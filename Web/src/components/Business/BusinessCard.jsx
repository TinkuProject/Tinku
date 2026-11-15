'use client';
import { FaMapMarkerAlt, FaEdit, FaPause, FaPlay, FaTrash } from 'react-icons/fa';

const PLACEHOLDER = 'https://via.placeholder.com/800x400?text=Sin+imagen';

export default function BusinessCard({
  business,
  categoryName,
  onViewDetails,
  onEdit,
  onPause,
  onDelete,
  isPaused = false,
  imageUrl,
  imageCount = 0,
}) {
  const cover = imageUrl || PLACEHOLDER;
  const plural = imageCount === 1 ? 'foto' : 'fotos';

  return (
    <div className="relative bg-white border border-[#0077B6] rounded-xl shadow-md overflow-hidden transition hover:shadow-lg">
      {/* Badge cantidad de fotos */}
      {imageCount > 0 && (
        <div className="absolute top-2 right-2 z-10 px-2 py-1 text-xs rounded-full bg-black/60 text-white">
          {imageCount} {plural}
        </div>
      )}

      <img
        src={cover}
        alt={business?.name || 'Negocio'}
        className="w-full h-48 object-cover"
        loading="lazy"
        decoding="async"
        onError={(e) => { e.currentTarget.src = PLACEHOLDER; }}
      />

      <div className="p-4 flex flex-col gap-3">
        {/* Info */}
        <div>
          <h2 className="text-lg font-bold text-[#0077B6] truncate">{business?.name}</h2>
          <p className="text-sm text-[#0077B6] font-medium">{categoryName}</p>
          <div className="flex items-center gap-1 text-sm text-gray-600 mt-1">
            <FaMapMarkerAlt className="text-[#0077B6]" />
            <span className="truncate">{business?.address}</span>
          </div>
          <p className="text-sm text-gray-500 mt-2 line-clamp-3">{business?.description}</p>
        </div>

        {/* Acciones (Ver más + iconos a la derecha) */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => onViewDetails?.(business)}
            className="flex-1 bg-[#0077B6] hover:bg-[#005f90] text-white font-semibold py-2 rounded-lg transition"
          >
            Ver más
          </button>

          {onEdit && (
            <button
              onClick={() => onEdit(business)}
              className="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white border text-[#2563EB] hover:bg-[#EFF6FF] transition"
              title="Editar"
            >
              <FaEdit />
            </button>
          )}

          {onPause && (
            <button
              onClick={() => onPause(business)}
              className={`inline-flex items-center justify-center w-10 h-10 rounded-full border transition ${
                isPaused
                  ? 'bg-green-50 text-green-600 hover:bg-green-100'
                  : 'bg-rose-50 text-rose-600 hover:bg-rose-100'
              }`}
              title={isPaused ? 'Reactivar' : 'Pausar'}
            >
              {isPaused ? <FaPlay /> : <FaPause />}
            </button>
          )}

          {onDelete && (
            <button
              onClick={() => onDelete(business)}
              className="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white border text-rose-600 hover:bg-rose-50 transition"
              title="Eliminar"
            >
              <FaTrash />
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
