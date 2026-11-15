export interface AuditLog {
  id: number;
  user_id: string;
  action: string;
  entity_type?: string | null; //Próximamente se volverá enum, definir entidades.
  entity_id?: number | null;
  details?: Record<string, any> | null;

  created_at: Date;
}