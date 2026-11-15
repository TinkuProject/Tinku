// File: src/components/Review/BusinessViewReview.jsx
'use client';

import { useEffect, useMemo, useState } from 'react';
import {
  FaTimes,
  FaGlobe,
  FaPhone,
  FaEnvelope,
  FaMapMarkerAlt,
  FaExternalLinkAlt,
  FaUser,
  FaIdBadge,
  FaInfoCircle,
  FaCheckCircle,
  FaClock,
  FaBan,
} from 'react-icons/fa';

const UI = {
  primary: '#0077B6',
  border: '#E2E8F0',
  chipActive: '#DCFCE7',
  chipPaused: '#FFE4E6',
  chipPending: '#FEF3C7',
  chipRejected: '#FEE2E2',
};

const PLACEHOLDER = 'https://via.placeholder.com/1280x720?text=Sin+imagen';


/* ===================== Utils ===================== */
function ensureHttp(url) {
  if (!url) return '';
  if (/^https?:\/\//i.test(url)) return url;
  return `https://${url}`;
}

function osmEmbedUrl(lat, lng, z = 14) {
  const bbox = [lng - 0.02, lat - 0.02, lng + 0.02, lat + 0.02].join('%2C');
  return `https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat}%2C${lng}&zoom=${z}`;
}

function displayNameFrom(u) {
  if (!u) return '';
  const username = u.username || u.user_name || '';
  const full =
    [u.first_name, u.last_name].filter(Boolean).join(' ').trim() ||
    [u.firstname, u.lastname].filter(Boolean).join(' ').trim() ||
    u.full_name ||
    u.displayName ||
    u.name ||
    '';
  return (username || full || u.email || '').toString().trim();
}

function StatusBadge({ status }) {
  const s = String(status || '')
    .trim()
    .toLowerCase();

  if (s === 'active') {
    return (
      <span
        className="text-xs font-semibold px-2 py-1 rounded-full"
        style={{
          background: UI.chipActive,
          color: '#166534',
        }}
      >
        Activo
      </span>
    );
  }

  if (s === 'cancelled') {
    return (
      <span
        className="text-xs font-semibold px-2 py-1 rounded-full"
        style={{
          background: UI.chipRejected,
          color: '#991B1B',
        }}
      >
        Cancelado
      </span>
    );
  }

  return (
    <span
      className="text-xs font-semibold px-2 py-1 rounded-full"
      style={{
        background: UI.chipPending,
        color: '#92400E',
      }}
    >
      Pendiente
    </span>
  );
}

/* ===================== Componente ===================== */
export default function BusinessViewReview({
  business,
  images = [],
  categoryName = '—',
  onClose,
  onApprove,
  onReject,
}) {
  const gallery = images.length ? images : [PLACEHOLDER];
  const [current, setCurrent] = useState(0);

  const meta = useMemo(() => {
    const coords = business?.location?.coordinates;

    const lng = Number(
      coords?.[0] ?? business?.lng ?? -66.1568
    );

    const lat = Number(
      coords?.[1] ?? business?.lat ?? -17.3895
    );

    const status = String(
      business?.status ??
      business?.estado ??
      'pending'
    )
      .trim()
      .toLowerCase();

    const statusLabel =
      status === 'active'
        ? 'Activo'
        : status === 'cancelled'
          ? 'Cancelado'
          : 'Pendiente';

    return {
      lat,
      lng,
      status,
      statusLabel,
    };
  }, [business]);



  const createdAt =
    business?.created_at || business?.createdAt || business?.created || '';
  const id = business?.id ?? business?.business_id ?? business?._id ?? '—';

  const canEvaluate = meta.status === 'pending';

  return (
    <div className="fixed inset-0 z-50">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="absolute inset-0 grid place-items-center p-6">
        <div
          className="w-full max-w-6xl bg-white rounded-xl shadow-2xl border overflow-hidden"
          style={{ borderColor: UI.border }}
        >
          {/* Header */}
          <div
            className="px-6 py-4 flex items-center justify-between"
            style={{ borderBottom: `1px solid ${UI.border}`, background: '#F8FAFC' }}
          >
            <div className="min-w-0">
              <h2 className="text-2xl font-bold text-slate-900 truncate">
                {business?.name || 'Negocio'}
              </h2>
              <p className="text-sm text-[#0077B6] font-medium">
                {categoryName} · {business?.business_type || '—'}
              </p>
            </div>

            <div className="flex items-center gap-2">
              <StatusBadge status={meta.status} />

              {canEvaluate && (
                <>
                  <button
                    onClick={() => onApprove?.(business)}
                    className="inline-flex items-center gap-2 px-3 py-2 rounded-md text-white font-semibold bg-emerald-600 hover:bg-emerald-700"
                    title="Aprobar"
                  >
                    <FaCheckCircle /> Aprobar
                  </button>

                  <button
                    onClick={() => onReject?.(business)}
                    className="inline-flex items-center gap-2 px-3 py-2 rounded-md text-white font-semibold bg-rose-600 hover:bg-rose-700"
                    title="Rechazar"
                  >
                    <FaBan /> Rechazar
                  </button>
                </>
              )}

              <button
                onClick={onClose}
                className="inline-flex items-center justify-center w-10 h-10 rounded-full border text-slate-700 hover:bg-slate-50"
                title="Cerrar"
                aria-label="Cerrar"
              >
                <FaTimes />
              </button>
            </div>
          </div>

          {/* Content */}
          <div className="p-6 grid grid-cols-1 lg:grid-cols-3 gap-6 max-h-[75vh] overflow-y-auto">
            {/* Izquierda: galería + detalle */}
            <div className="lg:col-span-2 space-y-4">
              {/* Galería */}
              <div className="rounded-lg overflow-hidden border" style={{ borderColor: UI.border }}>
                <img
                  src={gallery[current] || PLACEHOLDER}
                  alt={`img-${current}`}
                  className="w-full h-72 object-cover bg-slate-100"
                  onError={(e) => (e.currentTarget.src = PLACEHOLDER)}
                />
                {gallery.length > 1 && (
                  <div className="p-3 grid grid-cols-5 sm:grid-cols-6 md:grid-cols-8 gap-2 bg-white">
                    {gallery.map((url, i) => (
                      <button
                        key={`${url}-${i}`}
                        className={`relative aspect-[4/3] rounded-md overflow-hidden border ${i === current ? 'ring-2 ring-[#0077B6]' : 'hover:opacity-90'
                          }`}
                        style={{ borderColor: UI.border }}
                        onClick={() => setCurrent(i)}
                        aria-label={`Ver imagen ${i + 1}`}
                      >
                        <img
                          src={url}
                          alt={`thumb-${i}`}
                          className="w-full h-full object-cover"
                          onError={(e) => (e.currentTarget.src = PLACEHOLDER)}
                        />
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Detalle */}
              <div className="bg-white rounded-lg border p-4" style={{ borderColor: UI.border }}>
                <div className="flex items-center gap-2 mb-3 text-slate-800">
                  <FaInfoCircle />
                  <h3 className="font-semibold">Detalle</h3>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-3 text-[15px]">
                  <Row label="ID" value={id} icon={<FaIdBadge className="text-slate-400" />} />
                  <Row label="Estado" value={meta.statusLabel} />
                  <Row
                    label="Estado"
                    value={meta.statusLabel}
                  />
                  <Row
                    label="Tipo de negocio"
                    value={business?.business_type || '—'}
                  />
                  <Row label="Categoría" value={categoryName} />
                  <Row label="NIT" value={business?.nit || '—'} />
                  <Row
                    label="Email"
                    value={business?.email || '—'}
                    render={(v) =>
                      v && v !== '—' ? (
                        <a
                          href={`mailto:${v}`}
                          className="inline-flex items-center gap-2 text-slate-700 hover:underline"
                        >
                          <FaEnvelope /> {v}
                        </a>
                      ) : (
                        '—'
                      )
                    }
                  />
                  <Row
                    label="Teléfono"
                    value={business?.phone || '—'}
                    render={(v) =>
                      v && v !== '—' ? (
                        <a
                          href={`tel:${v}`}
                          className="inline-flex items-center gap-2 text-slate-700 hover:underline"
                        >
                          <FaPhone /> {v}
                        </a>
                      ) : (
                        '—'
                      )
                    }
                  />
                  <Row
                    label="Website"
                    value={business?.website || '—'}
                    render={(v) =>
                      v && v !== '—' ? (
                        <a
                          href={ensureHttp(v)}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center gap-2 text-[#0077B6] hover:underline"
                        >
                          <FaGlobe /> {v} <FaExternalLinkAlt className="opacity-70" />
                        </a>
                      ) : (
                        '—'
                      )
                    }
                  />
                  <Row
                    label="Dirección"
                    value={business?.address || '—'}
                    icon={<FaMapMarkerAlt className="text-[#0077B6]" />}
                  />
                  <Row
                    label="Coordenadas"
                    value={`${meta.lat.toFixed(5)}, ${meta.lng.toFixed(5)}`}
                  />
                  <Row
                    label="Creado"
                    value={
                      createdAt ? new Date(createdAt).toLocaleString() : '—'
                    }
                    icon={<FaClock className="text-slate-400" />}
                  />
                </div>

                <div className="mt-4">
                  <p className="text-sm font-medium text-slate-700 mb-1">
                    Descripción
                  </p>
                  <p className="text-slate-700 whitespace-pre-line">
                    {business?.description || '—'}
                  </p>
                </div>
              </div>
            </div>

            {/* Derecha: Tinkus + mapa */}
            <div className="space-y-4">
            
              {/* Card de mapa */}
              <div
                className="bg-white rounded-lg border overflow-hidden"
                style={{ borderColor: UI.border }}
              >
                <div
                  className="px-4 py-2 text-sm font-semibold text-slate-700 border-b"
                  style={{ borderColor: UI.border }}
                >
                  Ubicación
                </div>
                <div className="h-56">
                  <iframe
                    title="mapa"
                    className="w-full h-full"
                    loading="lazy"
                    referrerPolicy="no-referrer-when-downgrade"
                    src={osmEmbedUrl(meta.lat, meta.lng)}
                  />
                </div>
                <div className="px-4 py-3 text-xs text-slate-600">
                  Lat: <b>{meta.lat.toFixed(5)}</b> · Lng:{' '}
                  <b>{meta.lng.toFixed(5)}</b>
                </div>
              </div>
            </div>
          </div>
          {/* /content */}
        </div>
      </div>
    </div>
  );
}

function Row({ label, value, icon, render }) {
  const content = render ? render(value) : value;
  return (
    <div className="grid grid-cols-[140px_1fr] items-start gap-3">
      <div className="text-slate-500 font-medium flex items-center gap-2">
        {icon} {label}
      </div>
      <div className="text-slate-800">{content ?? '—'}</div>
    </div>
  );
}
