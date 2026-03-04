/**
 * Overview Page
 *
 * Main dashboard showing platform health at a glance. Displays app
 * analytics (users, events), ECS service status, and current-month
 * AWS costs with auto-polling.
 *
 * Queries: AppAnalytics (60s poll), EcsServiceStatus (30s poll), AwsCostBreakdown
 *
 * Dependencies: DashboardShell, StatCard, Skeleton, ErrorCard
 */
'use client';
import { useQuery } from '@apollo/client/react';
import { format, startOfMonth } from 'date-fns';
import { DashboardShell } from '../components/DashboardShell';
import { StatCard } from '../components/StatCard';
import { SkeletonStatCard } from '../components/Skeleton';
import { ErrorCard } from '../components/ErrorCard';
import { APP_ANALYTICS, ECS_SERVICE_STATUS, AWS_COST_BREAKDOWN } from '../lib/queries';

interface AppAnalytics {
  totalUsers: number;
  totalOverseers: number;
  totalEvents: number;
  totalVolunteers: number;
  totalAssignments: number;
  totalCheckIns: number;
}

interface EcsStatus {
  runningCount: number;
  desiredCount: number;
  pendingCount: number;
  status: string;
  lastDeploymentAt: string | null;
  lastDeploymentStatus: string | null;
  cpuReservation: number | null;
  memoryReservation: number | null;
}

interface CostEntry { service: string; amount: number; unit: string; }

export default function OverviewPage() {
  const { data: analyticsData, loading: analyticsLoading, error: analyticsError, refetch: refetchAnalytics } = useQuery<{ appAnalytics: AppAnalytics }>(APP_ANALYTICS, {
    pollInterval: 60_000,
  });
  const { data: ecsData, loading: ecsLoading, error: ecsError, refetch: refetchEcs } = useQuery<{ ecsServiceStatus: EcsStatus }>(ECS_SERVICE_STATUS, {
    pollInterval: 30_000,
  });

  const start = format(startOfMonth(new Date()), 'yyyy-MM-dd');
  const end = format(new Date(), 'yyyy-MM-dd');
  const { data: costData, loading: costLoading, error: costError, refetch: refetchCost } = useQuery<{ awsCostBreakdown: CostEntry[] }>(AWS_COST_BREAKDOWN, {
    variables: { startDate: start, endDate: end },
  });

  const analytics = analyticsData?.appAnalytics;
  const ecs = ecsData?.ecsServiceStatus;
  const totalCost = costData?.awsCostBreakdown.reduce((sum, e) => sum + e.amount, 0) ?? 0;

  const ecsStatus = ecs
    ? ecs.runningCount === ecs.desiredCount ? 'ok' : ecs.runningCount === 0 ? 'error' : 'warn'
    : undefined;

  const cardStyle: React.CSSProperties = {
    backgroundColor: 'var(--card)',
    borderRadius: 'var(--radius-md)',
    boxShadow: 'var(--shadow-card)',
    border: '1px solid var(--divider)',
    padding: '20px',
  };

  return (
    <DashboardShell>
      <div className="p-8">
        <h1 className="text-2xl font-semibold mb-1" style={{ color: 'var(--text-primary)' }}>Overview</h1>
        <p className="text-sm mb-6" style={{ color: 'var(--text-secondary)' }}>Platform health at a glance</p>

        {/* Top-level error */}
        {analyticsError && !analyticsData && (
          <div className="mb-4">
            <ErrorCard message={analyticsError.message} onRetry={() => refetchAnalytics()} />
          </div>
        )}

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {analyticsLoading && !analyticsData ? (
            <>
              <SkeletonStatCard />
              <SkeletonStatCard />
            </>
          ) : (
            <>
              <StatCard
                label="Total Users"
                value={(analytics?.totalUsers ?? 0).toLocaleString()}
                subtext={`${analytics?.totalOverseers ?? 0} overseers`}
              />
              <StatCard
                label="Total Events"
                value={(analytics?.totalEvents ?? 0).toLocaleString()}
                subtext={`${analytics?.totalVolunteers ?? 0} assignments`}
              />
            </>
          )}
          {ecsLoading && !ecsData ? (
            <SkeletonStatCard />
          ) : ecsError && !ecsData ? (
            <ErrorCard message={ecsError.message} onRetry={() => refetchEcs()} />
          ) : (
            <StatCard
              label="ECS Tasks"
              value={ecs ? `${ecs.runningCount} / ${ecs.desiredCount}` : 'N/A'}
              subtext={ecs?.status ?? ''}
              status={ecsStatus}
            />
          )}
          {costLoading && !costData ? (
            <SkeletonStatCard />
          ) : costError && !costData ? (
            <ErrorCard message={costError.message} onRetry={() => refetchCost()} />
          ) : (
            <StatCard
              label="Monthly Cost"
              value={totalCost > 0 ? `$${totalCost.toFixed(2)}` : '$0.00'}
              subtext="Current month (AWS)"
            />
          )}
        </div>

        <div className="mt-6 grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div style={cardStyle}>
            <p className="text-sm font-semibold mb-3" style={{ color: 'var(--text-primary)' }}>App Summary</p>
            <div className="space-y-2">
              {([
                ['Check-ins', analytics?.totalCheckIns],
                ['Assignments', analytics?.totalAssignments],
                ['Volunteers', analytics?.totalVolunteers],
              ] as [string, number | undefined][]).map(([label, val]) => (
                <div key={label} className="flex justify-between text-sm">
                  <span style={{ color: 'var(--text-secondary)' }}>{label}</span>
                  <span className="font-medium" style={{ color: 'var(--text-primary)' }}>
                    {analyticsLoading && !analyticsData ? '—' : (val ?? 0).toLocaleString()}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {ecs && (
            <div style={cardStyle}>
              <p className="text-sm font-semibold mb-3" style={{ color: 'var(--text-primary)' }}>ECS Service</p>
              <div className="space-y-2">
                {([
                  ['Running', ecs.runningCount],
                  ['Desired', ecs.desiredCount],
                  ['Pending', ecs.pendingCount],
                ] as [string, number][]).map(([label, val]) => (
                  <div key={label} className="flex justify-between text-sm">
                    <span style={{ color: 'var(--text-secondary)' }}>{label}</span>
                    <span className="font-medium" style={{ color: 'var(--text-primary)' }}>{val}</span>
                  </div>
                ))}
                {ecs.lastDeploymentAt && (
                  <div className="flex justify-between text-sm pt-2 mt-2" style={{ borderTop: '1px solid var(--divider)' }}>
                    <span style={{ color: 'var(--text-secondary)' }}>Last deploy</span>
                    <span className="font-medium text-xs" style={{ color: 'var(--text-primary)' }}>
                      {new Date(ecs.lastDeploymentAt).toLocaleDateString()}
                    </span>
                  </div>
                )}
              </div>
            </div>
          )}

          <div style={cardStyle}>
            <p className="text-sm font-semibold mb-3" style={{ color: 'var(--text-primary)' }}>Quick Links</p>
            <div className="space-y-2">
              {[
                { label: 'App Metrics', href: '/metrics' },
                { label: 'Infrastructure', href: '/infra' },
                { label: 'Cost Breakdown', href: '/costs' },
                { label: 'View Logs', href: '/logs' },
              ].map(link => (
                <a
                  key={link.href}
                  href={link.href}
                  className="flex items-center justify-between text-sm py-0.5 transition-opacity hover:opacity-70"
                  style={{ color: 'var(--primary)' }}
                >
                  {link.label}
                  <span style={{ color: 'var(--text-tertiary)' }}>→</span>
                </a>
              ))}
            </div>
          </div>
        </div>
      </div>
    </DashboardShell>
  );
}
