import type { Alert, AlertSeverity, AlertConditionType, AlertDirection } from '@/types/alerts';

export function severityColor(severity: AlertSeverity): string {
  switch (severity) {
    case 'critical':
      return 'danger';
    case 'warning':
      return 'warning';
    case 'info':
      return 'info';
    default:
      return 'secondary';
  }
}

export function formatDuration(seconds: number): string {
  const s = Math.max(0, Math.floor(seconds));

  if (s < 60) {
    return `${s}s`;
  }

  if (s < 3600) {
    const minutes = Math.floor(s / 60);
    const remainder = s % 60;
    if (remainder === 0) {
      return `${minutes}m`;
    }
    return `${minutes}m ${remainder}s`;
  }

  if (s < 86400) {
    const hours = Math.floor(s / 3600);
    const minutes = Math.floor((s % 3600) / 60);
    if (minutes === 0) {
      return `${hours}h`;
    }
    return `${hours}h ${minutes}m`;
  }

  const days = Math.floor(s / 86400);
  const hours = Math.floor((s % 86400) / 3600);
  if (hours === 0) {
    return `${days}d`;
  }
  return `${days}d ${hours}h`;
}

export function formatAbsoluteTime(iso: string): string {
  const date = new Date(iso);
  return date.toLocaleString();
}

export function formatRelativeTime(iso: string): string {
  const date = new Date(iso);
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000);

  if (seconds < 60) {
    return `${seconds}s ago`;
  }

  if (seconds < 3600) {
    return `${Math.floor(seconds / 60)}m ago`;
  }

  if (seconds < 86400) {
    return `${Math.floor(seconds / 3600)}h ago`;
  }

  if (seconds < 2592000) {
    return `${Math.floor(seconds / 86400)}d ago`;
  }

  return formatAbsoluteTime(iso);
}

export function conditionSummary(alert: Alert | { condition_type: AlertConditionType; direction: AlertDirection; threshold_value: number | null; inactivity_seconds: number | null; unit?: string | null }): string {
  switch (alert.condition_type) {
    case 'status_change': {
      switch (alert.direction) {
        case 'to_on':
          return 'Turned ON';
        case 'to_off':
          return 'Turned OFF';
        case 'both':
          return 'Status changed';
        default:
          return 'Status change';
      }
    }
    case 'threshold': {
      const operator = alert.direction === 'above' ? '>' : '<';
      const unit = alert.unit ? ` ${alert.unit}` : '';
      return `Value ${operator} ${alert.threshold_value}${unit}`;
    }
    case 'inactivity': {
      const seconds = alert.inactivity_seconds ?? 0;
      return `No data for ${formatDuration(seconds)}`;
    }
    default:
      return alert.condition_type;
  }
}

export function formatValueWithUnit(value: string | null, unit: string | null | undefined, conditionType: AlertConditionType): string {
  if (value === null || value === undefined || value === '') {
    return '—';
  }

  if (conditionType === 'inactivity') {
    return formatDuration(parseInt(value, 10));
  }

  if (unit) {
    return `${value} ${unit}`;
  }

  return value;
}
