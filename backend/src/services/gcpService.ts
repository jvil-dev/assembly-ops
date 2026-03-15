/**
 * GCP Service
 *
 * Provides infrastructure monitoring data from GCP services.
 * Used by the admin portal for Cloud Run health, metrics/logs, and cost data.
 *
 * Methods:
 *   - getCloudRunServiceStatus(): Cloud Run service health and revision info
 *   - getMetrics(period, metricName): Time-series CPU/Memory utilization
 *   - getLogs(limit, filter): Recent log events
 *   - getCostBreakdown(startDate, endDate): Monthly cost by GCP service
 *   - getDatabaseStats(): Database size, connections, and table row counts
 *
 * Called by: ../graphql/resolvers/gcp.ts
 */
import { ServicesClient } from '@google-cloud/run';
import { MetricServiceClient } from '@google-cloud/monitoring';
import { Logging } from '@google-cloud/logging';
import { BigQuery } from '@google-cloud/bigquery';
import { PrismaClient } from '@prisma/client';

const PROJECT_ID = process.env.GCP_PROJECT_ID!;
const REGION = process.env.GCP_REGION ?? 'us-east1';
const SERVICE_NAME = process.env.GCP_CLOUD_RUN_SERVICE ?? 'assemblyops-api';
const BILLING_DATASET = process.env.GCP_BILLING_DATASET;
const BILLING_TABLE = process.env.GCP_BILLING_TABLE;

const METRIC_MAP: Record<string, string> = {
  CPUUtilization: 'run.googleapis.com/container/cpu/utilizations',
  MemoryUtilization: 'run.googleapis.com/container/memory/utilizations',
};

export class GcpService {
  private runClient: ServicesClient;
  private monitoringClient: MetricServiceClient;
  private logging: Logging;
  private bigquery: BigQuery;

  constructor(private prisma: PrismaClient) {
    this.runClient = new ServicesClient();
    this.monitoringClient = new MetricServiceClient();
    this.logging = new Logging({ projectId: PROJECT_ID });
    this.bigquery = new BigQuery({ projectId: PROJECT_ID });
  }

  // ─────────────────────────────────────────────
  // CLOUD RUN SERVICE STATUS
  // ─────────────────────────────────────────────

  async getCloudRunServiceStatus() {
    const name = `projects/${PROJECT_ID}/locations/${REGION}/services/${SERVICE_NAME}`;
    const [service] = await this.runClient.getService({ name });

    const condition = service.conditions?.find((c) => c.type === 'Ready');
    const latestRevision = service.latestReadyRevision?.split('/').pop() ?? null;

    const template = service.template;
    const container = template?.containers?.[0];
    const scaling = template?.scaling;

    return {
      status:
        condition?.state === 'CONDITION_SUCCEEDED' ? 'Ready' : (condition?.state ?? 'Unknown'),
      latestRevision,
      cpuLimit: container?.resources?.limits?.cpu ?? null,
      memoryLimit: container?.resources?.limits?.memory ?? null,
      minInstances: scaling?.minInstanceCount ?? 0,
      maxInstances: scaling?.maxInstanceCount ?? 100,
    };
  }

  // ─────────────────────────────────────────────
  // CLOUD MONITORING METRICS
  // ─────────────────────────────────────────────

  async getMetrics(period: string, metricName: string) {
    const periodMap: Record<string, { alignmentPeriod: number; lookback: number }> = {
      '1h': { alignmentPeriod: 60, lookback: 60 * 60 },
      '24h': { alignmentPeriod: 300, lookback: 24 * 60 * 60 },
      '7d': { alignmentPeriod: 3600, lookback: 7 * 24 * 60 * 60 },
      '30d': { alignmentPeriod: 86400, lookback: 30 * 24 * 60 * 60 },
    };
    const cfg = periodMap[period] ?? periodMap['24h'];

    const endTime = new Date();
    const startTime = new Date(endTime.getTime() - cfg.lookback * 1000);

    const gcpMetric = METRIC_MAP[metricName] ?? metricName;

    const [timeSeries] = await this.monitoringClient.listTimeSeries({
      name: `projects/${PROJECT_ID}`,
      filter: `metric.type="${gcpMetric}" AND resource.labels.service_name="${SERVICE_NAME}"`,
      interval: {
        startTime: { seconds: Math.floor(startTime.getTime() / 1000) },
        endTime: { seconds: Math.floor(endTime.getTime() / 1000) },
      },
      aggregation: {
        alignmentPeriod: { seconds: cfg.alignmentPeriod },
        perSeriesAligner: 'ALIGN_MEAN',
      },
    });

    const points: { timestamp: string; value: number }[] = [];
    for (const series of timeSeries) {
      for (const point of series.points ?? []) {
        const ts = point.interval?.endTime;
        const seconds = Number(ts?.seconds ?? 0);
        const value = point.value?.doubleValue ?? point.value?.int64Value ?? 0;
        points.push({
          timestamp: new Date(seconds * 1000).toISOString(),
          value: Number(value) * 100,
        });
      }
    }

    return points.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
  }

  // ─────────────────────────────────────────────
  // CLOUD LOGGING
  // ─────────────────────────────────────────────

  async getLogs(limit: number = 50, filter: string = '') {
    const baseFilter = `resource.type="cloud_run_revision" AND resource.labels.service_name="${SERVICE_NAME}"`;
    const fullFilter = filter ? `${baseFilter} AND ${filter}` : baseFilter;

    const [entries] = await this.logging.getEntries({
      filter: fullFilter,
      orderBy: 'timestamp desc',
      pageSize: limit,
    });

    return entries.map((entry) => ({
      timestamp: entry.metadata?.timestamp
        ? new Date(entry.metadata.timestamp as string).toISOString()
        : null,
      message: typeof entry.data === 'string' ? entry.data : JSON.stringify(entry.data),
      logStreamName: entry.metadata?.logName?.split('/').pop() ?? '',
    }));
  }

  // ─────────────────────────────────────────────
  // BILLING (BigQuery)
  // ─────────────────────────────────────────────

  async getCostBreakdown(startDate: string, endDate: string) {
    if (!BILLING_DATASET || !BILLING_TABLE) {
      return [];
    }

    const query = `
      SELECT
        service.description AS service,
        SUM(cost) AS amount,
        currency AS unit,
        @startDate AS timePeriodStart,
        @endDate AS timePeriodEnd
      FROM \`${PROJECT_ID}.${BILLING_DATASET}.${BILLING_TABLE}\`
      WHERE usage_start_time >= TIMESTAMP(@startDate)
        AND usage_start_time < TIMESTAMP(@endDate)
        AND project.id = @projectId
      GROUP BY service.description, currency
      ORDER BY amount DESC
    `;

    const [rows] = await this.bigquery.query({
      query,
      params: { startDate, endDate, projectId: PROJECT_ID },
    });

    return rows.map((row: Record<string, unknown>) => ({
      service: String(row.service ?? 'Unknown'),
      amount: Number(row.amount ?? 0),
      unit: String(row.unit ?? 'USD'),
      timePeriodStart: String(row.timePeriodStart ?? startDate),
      timePeriodEnd: String(row.timePeriodEnd ?? endDate),
    }));
  }

  // ─────────────────────────────────────────────
  // DATABASE STATS
  // ─────────────────────────────────────────────

  async getDatabaseStats() {
    const [sizeResult, connectionResult, tableCounts] = await Promise.all([
      this.prisma.$queryRaw<Array<{ size: string }>>`
        SELECT pg_size_pretty(pg_database_size(current_database())) as size
      `,
      this.prisma.$queryRaw<Array<{ count: bigint }>>`
        SELECT COUNT(*) as count FROM pg_stat_activity
        WHERE datname = current_database()
      `,
      Promise.all([
        this.prisma.user.count(),
        this.prisma.event.count(),
        this.prisma.eventVolunteer.count(),
        this.prisma.scheduleAssignment.count(),
        this.prisma.checkIn.count(),
      ]),
    ]);

    return {
      databaseSize: sizeResult[0]?.size ?? 'N/A',
      activeConnections: Number(connectionResult[0]?.count ?? 0),
      tableCounts: {
        users: tableCounts[0],
        events: tableCounts[1],
        eventVolunteers: tableCounts[2],
        assignments: tableCounts[3],
        checkIns: tableCounts[4],
      },
    };
  }
}
