// File: src/components/Events/EventCard.jsx
'use client';

import {
  FaCalendarAlt,
  FaMapMarkerAlt,
  FaEdit,
  FaTrash,
  FaCheckCircle,
} from 'react-icons/fa';

const UI = {
  primary: '#0077B6',
  border: '#E2E8F0',
};

const PLACEHOLDER =
  'https://via.placeholder.com/800x400?text=Sin+imagen';

function formatDate(date) {
  if (!date) return '—';

  try {
    return new Date(date).toLocaleDateString();
  } catch {
    return String(date);
  }
}

export default function EventCard({
  event,
  categoryName,
  onView,
  onViewDetails,
  onEdit,
  onDelete,
  onFinish,
  imageUrl,
  imageCount = 0,
}) {
  const cover = imageUrl || PLACEHOLDER;

  const plural = imageCount === 1 ? 'foto' : 'fotos';

  const isFinished = event?.status === 'finished';

  const isActive = event?.status === 'active';

  const handleView = () => {
    if (onViewDetails) return onViewDetails(event);
    if (onView) return onView(event);
  };

  const handleEditClick = () => {
    if (!isActive) return;
    onEdit?.(event);
  };

  const handleFinishClick = () => {
    if (!isActive) return;
    onFinish?.(event);
  };

  const handleDeleteClick = () => {
    if (!isActive) return;
    onDelete?.(event);
  };

  const statusClass =
    event?.status === 'active'
      ? 'bg-green-100 text-green-700'
      : event?.status === 'finished'
        ? 'bg-slate-200 text-slate-700'
        : event?.status === 'cancelled'
          ? 'bg-red-100 text-red-700'
          : 'bg-amber-100 text-amber-700';

  const statusLabel =
    event?.status === 'active'
      ? 'Activo'
      : event?.status === 'finished'
        ? 'Finalizado'
        : event?.status === 'cancelled'
          ? 'Cancelado'
          : 'Pendiente';

  return (
    <div
      className="relative bg-white border rounded-xl shadow-md overflow-hidden transition hover:shadow-lg"
      style={{ borderColor: UI.border }}
    >
      {imageCount > 0 && (
        <div className="absolute top-2 right-2 z-10 px-2 py-1 text-xs rounded-full bg-black/60 text-white">
          {imageCount} {plural}
        </div>
      )}

      <img
        src={cover}
        alt={event?.name || 'Evento'}
        className="w-full h-48 object-cover"
        loading="lazy"
        decoding="async"
        onError={(e) => {
          e.currentTarget.src = PLACEHOLDER;
        }}
      />

      <div className="p-4 flex flex-col gap-3">
        <div>
          <h2 className="text-lg font-bold text-[#0077B6] truncate">
            {event?.name || '—'}
          </h2>

          {categoryName && (
            <p className="text-sm text-[#0077B6] font-medium">
              {categoryName}
            </p>
          )}

          {(event?.start_date || event?.end_date) && (
            <div className="mt-1 flex items-center gap-1 text-xs text-gray-600">
              <FaCalendarAlt className="text-[#0077B6]" />

              <span className="truncate">
                {formatDate(event?.start_date)} —{' '}
                {formatDate(event?.end_date)}
              </span>
            </div>
          )}

          {event?.address && (
            <div className="mt-1 flex items-center gap-1 text-xs text-gray-600">
              <FaMapMarkerAlt className="text-[#0077B6]" />

              <span className="truncate">{event.address}</span>
            </div>
          )}

          {event?.status && (
            <div className="mt-2">
              <span
                className={`inline-flex px-2 py-0.5 rounded-full text-xs font-semibold ${statusClass}`}
              >
                {statusLabel}
              </span>
            </div>
          )}

          {event?.description && (
            <p className="text-sm text-gray-500 mt-2 line-clamp-3">
              {event.description}
            </p>
          )}

          {event?.tinku_price !== undefined &&
            event?.tinku_price !== null && (
              <div className="mt-2">
                <span className="inline-flex px-2 py-1 rounded-full bg-[#0077B6]/10 text-[#0077B6] text-xs font-semibold">
                  {event.tinku_price} Tinkus
                </span>
              </div>
            )}

          {event?.capacity && (
            <p className="text-xs text-slate-500 mt-1">
              Capacidad: {event.capacity} personas
            </p>
          )}
        </div>

        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={handleView}
            className="flex-1 bg-[#0077B6] hover:bg-[#005f90] text-white font-semibold py-2 rounded-lg transition"
          >
            Ver detalle
          </button>

          {onEdit && (
            <button
              type="button"
              onClick={handleEditClick}
              disabled={!isActive}
              className={`inline-flex items-center justify-center w-10 h-10 rounded-full border transition ${isActive
                  ? 'bg-white text-[#2563EB] hover:bg-[#EFF6FF]'
                  : 'bg-slate-100 text-slate-400 cursor-not-allowed'
                }`}
              title={
                isActive
                  ? 'Editar evento'
                  : 'Solo eventos activos pueden editarse'
              }
            >
              <FaEdit />
            </button>
          )}

          {onFinish && (
            <button
              type="button"
              onClick={handleFinishClick}
              disabled={!isActive || isFinished}
              className={`inline-flex items-center justify-center w-10 h-10 rounded-full border transition ${isActive
                  ? 'bg-emerald-50 text-emerald-600 hover:bg-emerald-100'
                  : 'bg-slate-100 text-slate-400 cursor-not-allowed'
                }`}
              title={
                isActive
                  ? 'Marcar evento como finalizado'
                  : 'Solo eventos activos pueden finalizarse'
              }
            >
              <FaCheckCircle />
            </button>
          )}

          {onDelete && (
            <button
              type="button"
              onClick={handleDeleteClick}
              disabled={!isActive}
              className={`inline-flex items-center justify-center w-10 h-10 rounded-full border transition ${isActive
                  ? 'bg-white text-rose-600 hover:bg-rose-50'
                  : 'bg-slate-100 text-slate-400 cursor-not-allowed'
                }`}
              title={
                isActive
                  ? 'Eliminar evento'
                  : 'No se puede eliminar'
              }
            >
              <FaTrash />
            </button>
          )}
        </div>
      </div>
    </div>
  );
}