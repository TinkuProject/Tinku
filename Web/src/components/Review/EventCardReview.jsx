// File: src/components/Review/EventCardReview.jsx
'use client';

import {
    FaCalendarAlt,
    FaMapMarkerAlt,
    FaLayerGroup,
} from 'react-icons/fa';

const PLACEHOLDER = 'https://via.placeholder.com/800x400?text=Sin+imagen';

// status: 'pending' | 'active' | 'finished'
function getStatusInfo(ev) {
    const raw = ev?.status || ev?.estado || ev?.state;
    const s = String(raw || '').trim().toLowerCase();

    if (s === 'active') {
        return {
            label: 'Activo',
            bg: 'bg-emerald-100',
            text: 'text-emerald-700',
            border: 'border-emerald-200',
        };
    }

    if (s === 'finished') {
        return {
            label: 'Finalizado',
            bg: 'bg-slate-200',
            text: 'text-slate-800',
            border: 'border-slate-300',
        };
    }
    if (s === 'cancelled') {
        return {
            label: 'Cancelado',
            bg: 'bg-rose-100',
            text: 'text-rose-700',
            border: 'border-rose-200',
        };
    }

    // default → pending / solicitud
    return {
        label: 'Pendiente',
        bg: 'bg-amber-100',
        text: 'text-amber-700',
        border: 'border-amber-200',
    };
}

function formatDateRange(start, end) {
    if (!start && !end) return 'Sin fecha definida';

    const toDate = (v) => (v ? new Date(v) : null);

    const s = toDate(start);
    const e = toDate(end);

    const opts = { day: '2-digit', month: '2-digit', year: 'numeric' };

    if (s && e) {
        const sameDay =
            s.getFullYear() === e.getFullYear() &&
            s.getMonth() === e.getMonth() &&
            s.getDate() === e.getDate();

        if (sameDay) return s.toLocaleDateString('es-BO', opts);
        return `${s.toLocaleDateString('es-BO', opts)} — ${e.toLocaleDateString(
            'es-BO',
            opts,
        )}`;
    }

    if (s) return `Desde ${s.toLocaleDateString('es-BO', opts)}`;
    if (e) return `Hasta ${e.toLocaleDateString('es-BO', opts)}`;

    return 'Sin fecha definida';
}

export default function EventCardReview({
    event,
    categoryName = '—',
    imageUrl,
    onEvaluate,
}) {
    const cover = imageUrl || PLACEHOLDER;
    const status = getStatusInfo(event);

    const dateLabel = formatDateRange(event?.start_date, event?.end_date);

    return (
        <div className="relative bg-white border border-[#0077B6] rounded-xl shadow-md overflow-hidden transition hover:shadow-lg">
            {/* Badge estado */}
            <div className="absolute top-2 left-2 z-10">
                <span
                    className={`inline-flex items-center gap-1 px-2 py-1 text-xs font-semibold rounded-full border ${status.bg} ${status.text} ${status.border}`}
                >
                    ● {status.label}
                </span>
            </div>

            {/* Imagen de portada */}
            <img
                src={cover}
                alt={event?.name || 'Evento'}
                className="w-full h-44 object-cover"
                loading="lazy"
                decoding="async"
                onError={(e) => {
                    e.currentTarget.src = PLACEHOLDER;
                }}
            />

            <div className="p-4 flex flex-col gap-3">
                {/* Título / categoría */}
                <div>
                    <h3 className="text-lg font-bold text-[#0077B6] truncate">
                        {event?.name ?? 'Sin nombre'}
                    </h3>
                    <p className="text-sm text-[#0077B6]/80 inline-flex items-center gap-2">
                        <FaLayerGroup className="opacity-80" />
                        {categoryName}
                    </p>
                </div>

                {/* Datos básicos: fechas y dirección */}
                <div className="space-y-1 text-sm">
                    <div className="flex items-center gap-2 text-slate-700">
                        <FaCalendarAlt className="text-[#0077B6]" />
                        <span className="truncate">{dateLabel}</span>
                    </div>

                    {event?.address && (
                        <div className="flex items-center gap-2 text-slate-700">
                            <FaMapMarkerAlt className="text-[#0077B6]" />
                            <span className="truncate">{event.address}</span>
                        </div>
                    )}
                </div>

                {/* Acción */}
                <button
                    type="button"
                    onClick={() => onEvaluate?.(event)}
                    className="w-full bg-[#0077B6] hover:bg-[#005f90] text-white font-semibold py-2 rounded-lg transition"
                >
                    Evaluar
                </button>
            </div>
        </div>
    );
}
