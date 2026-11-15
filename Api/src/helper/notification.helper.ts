export function buildStatusNotification(params: {
  entityLabel: string;
  entityName: string;
  status: "pending" | "approved" | "rejected";
  adminMessage?: string;
}) {
  const cleanExtra = params.adminMessage?.trim();

  const titleMap = {
    pending: `${params.entityLabel} enviado a revisión`,
    approved: `${params.entityLabel} aprobado`,
    rejected: `${params.entityLabel} rechazado`,
  } as const;

  const baseMessageMap = {
    pending: `Tu ${params.entityLabel.toLowerCase()} "${params.entityName}" quedó pendiente de aprobación.`,
    approved: `Tu ${params.entityLabel.toLowerCase()} "${params.entityName}" fue aprobado.`,
    rejected: `Tu ${params.entityLabel.toLowerCase()} "${params.entityName}" fue rechazado.`,
  } as const;

  return {
    title: titleMap[params.status],
    message: cleanExtra
      ? `${baseMessageMap[params.status]}\n\n${cleanExtra}`
      : baseMessageMap[params.status],
  };
}