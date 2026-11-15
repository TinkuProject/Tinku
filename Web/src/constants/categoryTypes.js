// Opciones permitidas por la API (values) con etiquetas en español (labels)
export const CATEGORY_TYPES = [
  { label: 'Negocio', value: 'business' },
  { label: 'Evento', value: 'event' },
  { label: 'Lugar turístico', value: 'tourist_place' },
  { label: 'Producto', value: 'product' },
  { label: 'Servicio', value: 'service' },
];

// Helper para mostrar el label en UI
export const typeLabel = (value) =>
  CATEGORY_TYPES.find(t => t.value === value)?.label || value || '—';

// Set para validaciones rápidas
export const ALLOWED_CATEGORY_TYPE_VALUES = new Set(CATEGORY_TYPES.map(t => t.value));
