import type { ValueFormat } from '@/types/plc';

/**
 * Raw value type from server/database
 */
export type RawValue = string | number | null;

/**
 * Formatted value for display
 */
export type FormattedValue = string;

/**
 * Duration parts for editing
 */
export interface DurationParts {
  hours: number;
  minutes: number;
  seconds: number;
}

/**
 * Value converters - single source of truth for all value transformations
 */
export const valueConverters = {
  /**
   * NUMERIC
   */
  numeric: {
    toDisplay(value: RawValue, unit: string | null): FormattedValue {
      if (value === null)
        return '—';

      const numberValue = typeof value === 'number' ? value : parseFloat(String(value));
      const formatted = Number.isInteger(numberValue)
        ? numberValue.toString()
        : numberValue.toFixed(2);

      return unit ? `${formatted} ${unit}` : formatted;
    },

    toEdit(value: RawValue): string {
      if (value === null)
        return '';

      return String(value);
    },

    fromEdit(editValue: string): RawValue {
      if (editValue === '')
        return null;

      const numberValue = parseFloat(editValue);
      return isNaN(numberValue) ? null : numberValue;
    }
  },

  /**
   * BOOLEAN
   */
  boolean: {
    toDisplay(value: RawValue, options: string | null): FormattedValue {
      if (!options) {
        if (value === null)
          return 'On';

        return value === 1 || value === '1' ? 'On' : 'Off';
      }

      const optionsArray = options.split('/');
      const index = typeof value === 'number' ? value : Number(value);

      if (isNaN(index) || index < 0 || index >= optionsArray.length)
        return `Server Configuration Error (${index})`;

      return optionsArray[index];
    },

    toEdit(value: RawValue): boolean {
      if (typeof value === 'boolean')
        return value;

      if (value === 'true' || value === '1' || value === 1)
        return true;

      return false;
    },

    fromEdit(editValue: boolean): RawValue {
      return editValue ? 1 : 0;
    }
  },

  /**
   * ENUM
   */
  enum: {
    toDisplay(value: RawValue, enumValues: Record<string, string> | null): FormattedValue {
      if (value === null)
        return '—';

      const key = String(value);
      return enumValues?.[key] ?? `Server Configuration Error (${key})`;
    },

    toEdit(value: RawValue): string {
      if (value === null)
        return '';

      return String(value);
    },

    fromEdit(editValue: string): RawValue {
      return editValue === '' ? null : editValue;
    }
  },

  /**
   * ASCII STRING
   */
  asciiString: {
    toDisplay(value: RawValue): FormattedValue {
      return String(value ?? '—');
    },

    toEdit(value: RawValue): string {
      return String(value ?? '');
    },

    fromEdit(editValue: string): RawValue {
      return editValue === '' ? null : editValue;
    }
  },

  /**
   * TIME OF DAY (stored as minutes from midnight, displayed as HH:MM)
   */
  timeOfDay: {
    toDisplay(value: RawValue): FormattedValue {
      if (value === null)
        return '—';

      // If already formatted as HH:MM
      if (typeof value === 'string' && value.includes(':'))
        return value;

      const totalMinutes = typeof value === 'number' ? value : parseInt(String(value), 10);
      if (isNaN(totalMinutes))
        return '—';

      const hours = Math.floor(totalMinutes / 60);
      const minutes = totalMinutes % 60;
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
    },

    toEdit(value: RawValue): string {
      if (value === null)
        return '';

      // If already formatted as HH:MM
      if (typeof value === 'string' && value.includes(':'))
        return value;

      const totalMinutes = typeof value === 'number' ? value : parseInt(String(value), 10);
      if (isNaN(totalMinutes))
        return '';

      const hours = Math.floor(totalMinutes / 60);
      const minutes = totalMinutes % 60;
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
    },

    fromEdit(editValue: string): RawValue {
      if (!editValue)
        return null;

      const [hours, minutes] = editValue.split(':').map(Number);
      return hours * 60 + minutes;
    }
  },

  /**
   * DURATION (stored as total seconds)
   */
  durationSeconds: {
    toDisplay(value: RawValue): FormattedValue {
      if (value === null) return '—';

      // If already formatted
      if (typeof value === 'string' && value.includes(':'))
        return value;

      const totalSeconds = typeof value === 'number' ? value : parseInt(String(value), 10);
      if (isNaN(totalSeconds))
        return '—';

      const hours = Math.floor(totalSeconds / 3600);
      const minutes = Math.floor((totalSeconds % 3600) / 60);
      const seconds = totalSeconds % 60;

      if (hours > 0)
        return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;

      return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    },

    toEdit(value: RawValue): DurationParts {
      if (value === null)
        return { hours: 0, minutes: 0, seconds: 0 };

      // If it's a string like "HH:MM:SS" or "MM:SS"
      if (typeof value === 'string' && value.includes(':')) {
        const parts = value.split(':').map(Number);
        if (parts.length === 3)
          return { hours: parts[0], minutes: parts[1], seconds: parts[2] };
        else if (parts.length === 2)
          return { hours: 0, minutes: parts[0], seconds: parts[1] };
      }

      // If it's total seconds
      const totalSeconds = typeof value === 'number' ? value : parseInt(String(value), 10);
      if (isNaN(totalSeconds))
        return { hours: 0, minutes: 0, seconds: 0 };

      return {
        hours: Math.floor(totalSeconds / 3600),
        minutes: Math.floor((totalSeconds % 3600) / 60),
        seconds: totalSeconds % 60
      };
    },

    fromEdit(parts: DurationParts): RawValue {
      return parts.hours * 3600 + parts.minutes * 60 + parts.seconds;
    }
  },

  /**
   * BITMASK (stored as integer, each bit is a boolean flag)
   * enum_values keys are bit positions (as strings), values are labels.
   */
  bitmask: {
    toDisplay(value: RawValue, enumValues: Record<string, string> | null): FormattedValue {
      if (value === null)
        return '—';

      const intVal = typeof value === 'number' ? value : parseInt(String(value), 10);
      if (isNaN(intVal))
        return '—';

      if (intVal === 0)
        return 'None';

      if (!enumValues)
        return String(intVal);

      const activeLabels: string[] = [];
      for (const [bitStr, label] of Object.entries(enumValues)) {
        const bit = parseInt(bitStr, 10);
        if ((intVal & (1 << bit)) !== 0) {
          activeLabels.push(label);
        }
      }

      return activeLabels.length > 0 ? activeLabels.join(', ') : 'None';
    },

    toEdit(value: RawValue): number {
      if (value === null)
        return 0;

      const intVal = typeof value === 'number' ? value : parseInt(String(value), 10);
      return isNaN(intVal) ? 0 : intVal;
    },

    fromEdit(editValue: number): RawValue {
      return editValue;
    },

    /** Check if a specific bit is set */
    isBitSet(value: RawValue, bit: number): boolean {
      const intVal = typeof value === 'number' ? value : parseInt(String(value ?? '0'), 10);
      if (isNaN(intVal))
        return false;

      return (intVal & (1 << bit)) !== 0;
    },

    /** Toggle a specific bit and return the new bitmask value */
    toggleBit(value: RawValue, bit: number, checked: boolean): number {
      const current = typeof value === 'number' ? value : parseInt(String(value ?? '0'), 10);
      const intVal = isNaN(current) ? 0 : current;

      if (checked) {
        return intVal | (1 << bit);
      }
      return intVal & ~(1 << bit);
    }
  }
};

/**
 * Get display value based on value format
 */
export function getDisplayValue(
  value: RawValue,
  valueFormat: ValueFormat,
  metadata?: {
    unit?: string | null;
    enumValues?: Record<string, string> | null;
    showUnit?: boolean;
  }
): FormattedValue {
  switch (valueFormat) {
    case 'numeric':
      return valueConverters.numeric.toDisplay(value, metadata?.showUnit && metadata?.unit ? metadata.unit : null);
    case 'boolean':
      return valueConverters.boolean.toDisplay(value, metadata?.unit ?? null);
    case 'enum':
      return valueConverters.enum.toDisplay(value, metadata?.enumValues ?? null);
    case 'ascii_string':
      return valueConverters.asciiString.toDisplay(value);
    case 'time_of_day':
      return valueConverters.timeOfDay.toDisplay(value);
    case 'duration_seconds':
      return valueConverters.durationSeconds.toDisplay(value);
    case 'bitmask':
      return valueConverters.bitmask.toDisplay(value, metadata?.enumValues ?? null);
    default:
      return String(value ?? '—');
  }
}
