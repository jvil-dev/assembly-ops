/**
 * AWS Service
 *
 * Provides infrastructure monitoring data from AWS services.
 * Used by the admin portal for ECS health, CloudWatch metrics/logs, and cost data.
 *
 * Methods:
 *   - getEcsServiceStatus(): ECS service health and deployment info
 *   - getCloudwatchMetrics(period, metricName): Time-series CPU/Memory utilization
 *   - getCloudwatchLogs(limit, filterPattern): Recent log events
 *   - getAwsCostBreakdown(startDate, endDate): Monthly cost by AWS service
 *   - getDatabaseStats(): Database size, connections, and table row counts
 *
 * Called by: ../graphql/resolvers/aws.ts
 */
import { ECSClient, DescribeServicesCommand, DescribeTasksCommand, ListTasksCommand } from '@aws-sdk/client-ecs';
import { CloudWatchClient, GetMetricDataCommand } from '@aws-sdk/client-cloudwatch';
import { CloudWatchLogsClient, FilterLogEventsCommand } from '@aws-sdk/client-cloudwatch-logs';
import { CostExplorerClient, GetCostAndUsageCommand, GroupDefinitionType } from '@aws-sdk/client-cost-explorer';
import { PrismaClient } from '@prisma/client';

const REGION = 'us-east-1';
const CLUSTER = 'assemblyops-cluster';
const SERVICE = 'assemblyops-api';
const LOG_GROUP = '/ecs/assemblyops-api';

export class AwsService {
  private ecs: ECSClient;
  private cloudwatch: CloudWatchClient;
  private cwLogs: CloudWatchLogsClient;
  private costExplorer: CostExplorerClient;

  constructor(private prisma: PrismaClient) {
    this.ecs = new ECSClient({ region: REGION });
    this.cloudwatch = new CloudWatchClient({ region: REGION });
    this.cwLogs = new CloudWatchLogsClient({ region: REGION });
    this.costExplorer = new CostExplorerClient({ region: REGION });
  }

  // ─────────────────────────────────────────────
  // ECS SERVICE STATUS
  // ─────────────────────────────────────────────

  async getEcsServiceStatus() {
    const describeCmd = new DescribeServicesCommand({
      cluster: CLUSTER,
      services: [SERVICE],
    });
    const response = await this.ecs.send(describeCmd);
    const svc = response.services?.[0];
    if (!svc) throw new Error('ECS service not found');

    const listCmd = new ListTasksCommand({ cluster: CLUSTER, serviceName: SERVICE });
    const listRes = await this.ecs.send(listCmd);
    const taskArns = listRes.taskArns ?? [];

    let cpuReservation: number | null = null;
    let memoryReservation: number | null = null;
    if (taskArns.length > 0) {
      const descTasks = new DescribeTasksCommand({ cluster: CLUSTER, tasks: taskArns });
      const tasksRes = await this.ecs.send(descTasks);
      const task = tasksRes.tasks?.[0];
      if (task) {
        cpuReservation = task.cpu ? parseInt(task.cpu) : null;
        memoryReservation = task.memory ? parseInt(task.memory) : null;
      }
    }

    const lastDeployment = svc.deployments?.[0];
    return {
      runningCount: svc.runningCount ?? 0,
      desiredCount: svc.desiredCount ?? 0,
      pendingCount: svc.pendingCount ?? 0,
      status: svc.status ?? 'UNKNOWN',
      lastDeploymentAt: lastDeployment?.updatedAt?.toISOString() ?? null,
      lastDeploymentStatus: lastDeployment?.status ?? null,
      cpuReservation,
      memoryReservation,
    };
  }

  // ─────────────────────────────────────────────
  // CLOUDWATCH METRICS
  // ─────────────────────────────────────────────

  async getCloudwatchMetrics(period: string, metricName: string) {
    const periodMap: Record<string, { seconds: number; lookback: number }> = {
      '1h':  { seconds: 60,    lookback: 60 * 60 },
      '24h': { seconds: 300,   lookback: 24 * 60 * 60 },
      '7d':  { seconds: 3600,  lookback: 7 * 24 * 60 * 60 },
      '30d': { seconds: 86400, lookback: 30 * 24 * 60 * 60 },
    };
    const cfg = periodMap[period] ?? periodMap['24h'];

    const endTime = new Date();
    const startTime = new Date(endTime.getTime() - cfg.lookback * 1000);

    const cmd = new GetMetricDataCommand({
      StartTime: startTime,
      EndTime: endTime,
      MetricDataQueries: [
        {
          Id: 'm1',
          MetricStat: {
            Metric: {
              Namespace: 'AWS/ECS',
              MetricName: metricName,
              Dimensions: [
                { Name: 'ClusterName', Value: CLUSTER },
                { Name: 'ServiceName', Value: SERVICE },
              ],
            },
            Period: cfg.seconds,
            Stat: 'Average',
          },
        },
      ],
    });

    const res = await this.cloudwatch.send(cmd);
    const result = res.MetricDataResults?.[0];
    const timestamps = result?.Timestamps ?? [];
    const values = result?.Values ?? [];

    return timestamps
      .map((ts, i) => ({ timestamp: ts.toISOString(), value: values[i] ?? 0 }))
      .sort((a, b) => a.timestamp.localeCompare(b.timestamp));
  }

  // ─────────────────────────────────────────────
  // CLOUDWATCH LOGS
  // ─────────────────────────────────────────────

  async getCloudwatchLogs(limit: number = 50, filterPattern: string = '') {
    const cmd = new FilterLogEventsCommand({
      logGroupName: LOG_GROUP,
      limit,
      filterPattern: filterPattern || undefined,
      startTime: Date.now() - 24 * 60 * 60 * 1000,
    });
    const res = await this.cwLogs.send(cmd);
    return (res.events ?? []).map(e => ({
      timestamp: e.timestamp ? new Date(e.timestamp).toISOString() : null,
      message: e.message ?? '',
      logStreamName: e.logStreamName ?? '',
    }));
  }

  // ─────────────────────────────────────────────
  // COST EXPLORER
  // ─────────────────────────────────────────────

  async getAwsCostBreakdown(startDate: string, endDate: string) {
    const cmd = new GetCostAndUsageCommand({
      TimePeriod: { Start: startDate, End: endDate },
      Granularity: 'MONTHLY',
      Metrics: ['UnblendedCost'],
      GroupBy: [{ Type: GroupDefinitionType.DIMENSION, Key: 'SERVICE' }],
    });
    const res = await this.costExplorer.send(cmd);
    const results = res.ResultsByTime ?? [];

    return results.flatMap(r =>
      (r.Groups ?? []).map(g => ({
        service: g.Keys?.[0] ?? 'Unknown',
        amount: parseFloat(g.Metrics?.UnblendedCost?.Amount ?? '0'),
        unit: g.Metrics?.UnblendedCost?.Unit ?? 'USD',
        timePeriodStart: r.TimePeriod?.Start ?? '',
        timePeriodEnd: r.TimePeriod?.End ?? '',
      }))
    );
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
