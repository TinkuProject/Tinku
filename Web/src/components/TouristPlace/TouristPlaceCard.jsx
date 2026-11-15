// File: src/components/TouristPlace/TouristPlaceCard.jsx
'use client';

import {
  FaMapMarkerAlt,
  FaEdit,
  FaTrash,
  FaPause,
  FaPlay,
} from 'react-icons/fa';

const UI = { primary: '#0077B6' };
const PLACEHOLDER = '/images/no-image.jpg';

export default function TouristPlaceCard({
  place,
  categoryName,
  imageUrl,
  imageCount = 0,
  tags = [],
  onView,
  onEdit,
  onDelete,
  onPause,
  status = 'active',
}) {

  const isPaused = status === 'inactive';

  const cover = imageUrl || PLACEHOLDER;
  const plural = imageCount === 1 ? 'foto' : 'fotos';

  // Normaliza tags (acepta strings u objetos con name)
  const tagNames = (tags?.length ? tags : (place?.tags || []))
    .map((t) => (typeof t === 'string' ? t : t?.name))
    .filter(Boolean);

  const MAX_TAGS = 4; // cuántos chips mostrar
  const visible = tagNames.slice(0, MAX_TAGS);
  const rest = tagNames.length - visible.length;

  return (
    <div
      className="relative bg-white border rounded-xl shadow-md overflow-hidden transition hover:shadow-lg"
      style={{ borderColor: UI.primary }}
    >
      {/* Badge de cantidad de fotos */}
      {imageCount > 0 && (
        <div className="absolute top-2 right-2 z-10 px-2 py-1 text-xs rounded-full bg-black/60 text-white">
          {imageCount} {plural}
        </div>
      )}

      {/* Badge de estado pausado */}
      {isPaused && (
        <div className="absolute top-2 left-2 z-10 px-2 py-1 text-xs rounded-full bg-amber-500 text-white shadow">
          Pausado
        </div>
      )}

      {/* Cover */}
      <img
        src={cover}
        alt={place?.name || 'Lugar turístico'}
        className={`w-full h-48 object-cover transition ${isPaused ? 'grayscale-[0.4] brightness-95' : ''
          }`}
        loading="lazy"
        decoding="async"
        onError={(e) => {
          e.currentTarget.src = PLACEHOLDER;
        }}
      />

      {/* Body */}
      <div className="p-4 flex flex-col gap-3">
        <div>
          <h2
            className="text-lg font-bold truncate"
            style={{ color: UI.primary }}
          >
            {place?.name || '—'}
          </h2>
          {categoryName && (
            <p className="text-sm font-medium" style={{ color: UI.primary }}>
              {categoryName}
            </p>
          )}

          {/* Dirección */}
          <div className="flex items-center gap-1 text-sm text-gray-600 mt-1">
            <FaMapMarkerAlt style={{ color: UI.primary }} />
            <span className="truncate">{place?.address || '—'}</span>
          </div>

          {/* Tags */}
          {!!visible.length && (
            <div className="mt-2 flex flex-wrap gap-1.5">
              {visible.map((t, i) => (
                <span
                  key={`${t}-${i}`}
                  className="inline-flex px-2 py-0.5 rounded-full text-xs font-semibold border"
                  style={{
                    color: UI.primary,
                    borderColor: UI.primary,
                    background: '#E9F3FF',
                  }}
                  title={t}
                >
                  {t}
                </span>
              ))}
              {rest > 0 && (
                <span
                  className="inline-flex px-2 py-0.5 rounded-full text-xs font-semibold border text-slate-600 bg-slate-50"
                  style={{ borderColor: '#CBD5E1' }} // slate-300
                  title={tagNames.slice(MAX_TAGS).join(', ')}
                >
                  +{rest}
                </span>
              )}
            </div>
          )}

          {/* Descripción */}
          <p className="text-sm text-gray-500 mt-2 line-clamp-3">
            {place?.description || 'Sin descripción.'}
          </p>
        </div>

        {/* Acciones */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => onView?.(place)}
            className="flex-1 bg-[#0077B6] hover:bg-[#005f90] text-white font-semibold py-2 rounded-lg transition"
          >
            Ver más
          </button>

          {onPause && (
            <button
              onClick={() => onPause(place)}
              className={`inline-flex items-center justify-center w-10 h-10 rounded-full border bg-white transition ${isPaused
                ? 'text-green-700 hover:bg-green-50'
                : 'text-amber-700 hover:bg-amber-50'
                }`}
              title={isPaused ? 'Reanudar lugar' : 'Pausar lugar'}
            >
              {isPaused ? <FaPlay /> : <FaPause />}
            </button>
          )}

          {onEdit && (
            <button
              onClick={() => onEdit(place)}
              className="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white border text-[#2563EB] hover:bg-[#EFF6FF] transition"
              title="Editar"
            >
              <FaEdit />
            </button>
          )}

          {onDelete && (
            <button
              onClick={() => onDelete(place)}
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
