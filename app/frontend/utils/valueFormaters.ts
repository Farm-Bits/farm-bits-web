import type { LiveMeasurementPoint } from '@/types/analytics';
import type { SerieDefinition } from '@/components/ComboTimeSeriesChart.vue';

export function mapMeasurementPointToSerieDefinition(mp: LiveMeasurementPoint): SerieDefinition {
  return {
    id: mp.id,
    name: mp.name,
    unit: mp.effective_unit,
    chart_type: mp.effective_chart_type,
    color: mp.effective_color,
    value_format: mp.value_format,
    value_type: mp.measurement_subtype?.value_type ?? 'instantaneous'
  };
}
