'use client';

interface UsageBarProps {
  current: number;
  max: number;
  label: string;
}

export function UsageBar({ current, max, label }: UsageBarProps) {
  const percentage = max === 0 ? 0 : Math.min((current / max) * 100, 100);
  const isNearLimit = percentage >= 80 && percentage < 100;
  const isAtLimit = percentage >= 100;
  const isMaxInfinity = max === 999999;

  const barColor = isAtLimit
    ? 'from-red-400 to-red-600'
    : isNearLimit
      ? 'from-amber-400 to-orange-500'
      : 'from-primary-400 to-primary-600';

  const glowClass = isAtLimit
    ? 'shadow-[0_0_8px_rgba(239,68,68,0.4)]'
    : isNearLimit
      ? 'shadow-[0_0_8px_rgba(251,146,60,0.4)]'
      : '';

  const statusDot = isAtLimit
    ? 'bg-red-500'
    : isNearLimit
      ? 'bg-amber-500'
      : 'bg-emerald-500';

  return (
    <div className="space-y-1.5">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-1.5">
          <span className={`h-1.5 w-1.5 rounded-full ${statusDot}`} />
          <span className="text-xs font-medium text-surface-500">{label}</span>
        </div>
        <span className="text-xs font-semibold text-surface-700">
          {current}
          {!isMaxInfinity && (
            <span className="text-surface-300 font-normal">
              /{max}
            </span>
          )}
        </span>
      </div>
      <div className="relative h-2 w-full overflow-hidden rounded-full bg-surface-100">
        <div
          className={`h-full rounded-full bg-gradient-to-r ${barColor} transition-all duration-1000 ease-out ${glowClass}`}
          style={{
            width: `${isMaxInfinity ? 100 : percentage}%`,
          }}
        />
        {/* Shimmer effect on top */}
        {percentage > 0 && percentage < 100 && (
          <div className="absolute inset-0 rounded-full shimmer opacity-30" />
        )}
      </div>
    </div>
  );
}
