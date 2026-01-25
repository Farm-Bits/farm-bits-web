import type { RegisterMapping } from '@/types/plc';
import type { DataCategory } from '@/types/measurementPoint';

export function formatGroupName(groupName: string | null) {
  if (!groupName)
    return 'General';

  return groupName
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

export function formatDataCategory(category: DataCategory) {
  const categories: Record<DataCategory, string> = {
    'status': 'Status / On-Off',
    'analog': 'Analog Value',
    'counter': 'Counter / Accumulator'
  };
  return categories[category] || category;
}

export function getGroupIcon(groupName: string | null) {
  if (!groupName)
    return 'cilCog';

  const lowerName = groupName.toLowerCase();

  if (lowerName.includes('input') || lowerName.includes('ai'))
    return 'cilInput';

  if (lowerName.includes('output') || lowerName.includes('ao'))
    return 'cilMediaPlay';

  if (lowerName.includes('alarm'))
    return 'cilBell';

  if (lowerName.includes('scale') || lowerName.includes('calibr'))
    return 'cilBalanceScale';

  if (lowerName.includes('time'))
    return 'cilClock';

  return 'cilCog';
}

export function getConfigFieldClass(registerMapping: RegisterMapping) {
  const template = registerMapping.register_template;

  if (template.value_format === 'time_of_day')
    return 'col-md-4';

  if (template.value_format === 'duration_seconds')
    return 'col-md-6';

  if (template.value_format === 'boolean')
    return 'col-md-4';

  return 'col-md-6';
}

export function buildRoleMapping(
  registerMappings: RegisterMapping[],
  groupName: string | null
): Map<string, RegisterMapping> {
  const roleMap = new Map<string, RegisterMapping>();

  registerMappings.forEach((registerMapping) => {
    if (
      registerMapping.register_template.group_name === groupName &&
      registerMapping.register_template.group_role
    ) {
      roleMap.set(
        registerMapping.register_template.group_role,
        registerMapping
      );
    }
  });

  return roleMap;
}

export function groupMappingsByName(
  registerMappings: RegisterMapping[]
): Map<string | null, RegisterMapping[]> {
  const groups = new Map<string | null, RegisterMapping[]>();

  registerMappings.forEach((registerMapping) => {
    const groupName = registerMapping.register_template.group_name;
    if (!groups.has(groupName)) {
      groups.set(groupName, []);
    }
    groups.get(groupName)!.push(registerMapping);
  });

  return groups;
}

export function normalizeValue(value: unknown): string {
  if (value === null || value === undefined)
    return '';

  return String(value);
}
