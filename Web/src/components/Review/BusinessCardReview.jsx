// File: src/components/Review/BusinessCardReview.jsx
'use client';

import { FaEnvelope, FaPhoneAlt, FaLayerGroup } from 'react-icons/fa';

const PLACEHOLDER = 'https://via.placeholder.com/800x400?text=Sin+imagen';

function getStatusInfo(biz) {
  const raw = biz?.status ?? biz?.estado ?? biz?.state;
  const status = String(raw || '').trim().toLowerCase();

  if (status === 'active') {
    return {
      label: 'Activo',
      bg: 'bg-emerald-100',
      text: 'text-emerald-700',
      border: 'border-emerald-200',
    };
  }

  if (status === 'suspended') {
    return {
      label: 'Cancelado',
      bg: 'bg-rose-100',
      text: 'text-rose-700',
      border: 'border-rose-200',
    };
  }

  if (status === 'finished') {
    return {
      label: 'Finalizado',
      bg: 'bg-slate-200',
      text: 'text-slate-800',
      border: 'border-slate-300',
    };
  }

  return {
    label: 'Pendiente',
    bg: 'bg-amber-100',
    text: 'text-amber-700',
    border: 'border-amber-200',
  };
}

export default function BusinessCardReview({
  business,
  categoryName = '—',
  imageUrl,
  onEvaluate,
}) {
  const cover = imageUrl || PLACEHOLDER;
  const status = getStatusInfo(business);

  return (
    <div className="relative bg-white border border-[#0077B6] rounded-xl shadow-md overflow-hidden transition hover:shadow-lg">
      <div className="absolute top-2 left-2 z-10">
        <span
          className={`inline-flex items-center gap-1 px-2 py-1 text-xs font-semibold rounded-full border ${status.bg} ${status.text} ${status.border}`}
        >
          ● {status.label}
        </span>
      </div>

      <img
        src={cover}
        alt={business?.name || 'Negocio'}
        className="w-full h-44 object-cover"
        loading="lazy"
        decoding="async"
        onError={(e) => {
          e.currentTarget.src = PLACEHOLDER;
        }}
      />

      <div className="p-4 flex flex-col gap-3">
        <div>
          <h3 className="text-lg font-bold text-[#0077B6] truncate">
            {business?.name ?? 'Sin nombre'}
          </h3>

          <p className="text-sm text-[#0077B6]/80 inline-flex items-center gap-2">
            <FaLayerGroup className="opacity-80" />
            {categoryName}
          </p>
        </div>

        <div className="space-y-1 text-sm">
          {business?.email && (
            <div className="flex items-center gap-2 text-slate-700">
              <FaEnvelope className="text-[#0077B6]" />
              <span className="truncate">{business.email}</span>
            </div>
          )}

          {business?.phone && (
            <div className="flex items-center gap-2 text-slate-700">
              <FaPhoneAlt className="text-[#0077B6]" />
              <span className="truncate">{business.phone}</span>
            </div>
          )}
        </div>

        <button
          type="button"
          onClick={() => onEvaluate?.(business)}
          className="w-full bg-[#0077B6] hover:bg-[#005f90] text-white font-semibold py-2 rounded-lg transition"
        >
          Evaluar
        </button>
      </div>
    </div>
  );
}