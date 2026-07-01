import { getPlanConfig } from '@/types';

interface PlanBadgeProps {
  plan: string;
  size?: 'sm' | 'md';
  showIcon?: boolean;
}

const PLAN_ICONS: Record<string, string> = {
  free: '🆓',
  basic: '🥈',
  pro: '🥇',
  enterprise: '💎',
};

const PLAN_STYLES: Record<string, string> = {
  free: 'bg-surface-100 text-surface-600 border border-surface-200',
  basic:
    'bg-gradient-to-r from-blue-50 to-blue-100 text-blue-700 border border-blue-200 shadow-sm shadow-blue-500/5',
  pro: 'bg-gradient-to-r from-purple-50 to-purple-100 text-purple-700 border border-purple-200 shadow-sm shadow-purple-500/5',
  enterprise:
    'bg-gradient-to-r from-amber-50 to-amber-100 text-amber-700 border border-amber-200 shadow-sm shadow-amber-500/5',
};

export function PlanBadge({
  plan,
  size = 'md',
  showIcon = true,
}: PlanBadgeProps) {
  const config = getPlanConfig(plan);
  const sizeClasses =
    size === 'sm' ? 'px-2 py-0.5 text-[11px]' : 'px-3 py-1 text-xs';

  return (
    <span
      className={`inline-flex items-center gap-1 font-semibold rounded-full ${sizeClasses} transition-all duration-200 hover:scale-105 ${PLAN_STYLES[plan] || PLAN_STYLES.free}`}
    >
      {showIcon && <span className="shrink-0">{PLAN_ICONS[plan] || ''}</span>}
      <span className="shrink-0">{config.label}</span>
    </span>
  );
}
