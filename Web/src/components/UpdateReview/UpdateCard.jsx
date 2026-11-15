// File: src/components/Review/UpdateReview/UpdateCard.jsx
'use client';

import {
    FaCalendarAlt,
    FaLayerGroup,
    FaMapMarkerAlt,
    FaExchangeAlt,
} from 'react-icons/fa';

const PLACEHOLDER =
    'https://via.placeholder.com/800x400?text=Sin+imagen';

const TYPE_LABELS = {
    business: 'Negocio',
    event: 'Evento',
};

function getStatusInfo(status) {
    const s = String(status || '')
        .trim()
        .toLowerCase();

    if (s === 'approved') {
        return {
            label: 'Aprobado',
            bg: 'bg-emerald-100',
            text: 'text-emerald-700',
            border: 'border-emerald-200',
        };
    }

    if (s === 'rejected') {
        return {
            label: 'Rechazado',
            bg: 'bg-rose-100',
            text: 'text-rose-700',
            border: 'border-rose-200',
        };
    }

    return {
        label: 'Pendiente',
        bg: 'bg-amber-100',
        text: 'text-amber-700',
        border: 'border-amber-200',
    };
}

function formatDate(value) {
    if (!value) return 'Sin fecha';

    try {
        return new Date(value).toLocaleString(
            'es-BO',
            {
                day: '2-digit',
                month: '2-digit',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
            }
        );
    } catch {
        return 'Sin fecha';
    }
}

function countChanges(data = {}) {
    return Object.keys(data || {}).filter(
        (key) =>
            ![
                'media',
                'socials',
                'hours',
                'transport',
            ].includes(key)
    ).length;
}

export default function UpdateCard({
    update,
    currentEntity,
    imageUrl,
    imageCount = 0,
    onView,
}) {
    const cover = imageUrl || PLACEHOLDER;

    const data = update?.data || {};

    const status = getStatusInfo(
        update?.status
    );

    const title =
        data?.name ||
        currentEntity?.name ||
        `${TYPE_LABELS[
        update?.entity_type
        ] || 'Entidad'
        } #${update?.entity_id}`;

    const address =
        data?.address ||
        currentEntity?.address ||
        '';

    const changes = countChanges(data);

    const plural =
        imageCount === 1
            ? 'foto'
            : 'fotos';

    return (
        <div className="relative bg-white border border-[#0077B6] rounded-xl shadow-md overflow-hidden transition hover:shadow-lg">
            {/* STATUS */}
            <div className="absolute top-2 left-2 z-10">
                <span
                    className={`inline-flex items-center gap-1 px-2 py-1 text-xs font-semibold rounded-full border ${status.bg} ${status.text} ${status.border}`}
                >
                    ● {status.label}
                </span>
            </div>

            {/* TYPE */}
            <div className="absolute top-2 right-2 z-10">
                <span className="inline-flex items-center gap-1 px-2 py-1 text-xs font-semibold rounded-full bg-sky-100 text-sky-700 border border-sky-200">
                    <FaExchangeAlt />
                    {TYPE_LABELS[
                        update?.entity_type
                    ] ||
                        update?.entity_type ||
                        'Entidad'}
                </span>
            </div>

            {/* COUNT */}
            {imageCount > 0 && (
                <div className="absolute bottom-2 right-2 z-10 px-2 py-1 text-xs rounded-full bg-black/60 text-white">
                    {imageCount} {plural}
                </div>
            )}

            {/* IMAGE */}
            <img
                src={cover}
                alt={title}
                className="w-full h-44 object-cover"
                loading="lazy"
                decoding="async"
                onError={(e) => {
                    e.currentTarget.src =
                        PLACEHOLDER;
                }}
            />

            <div className="p-4 flex flex-col gap-3">
                <div>
                    <h3 className="text-lg font-bold text-[#0077B6] truncate">
                        {title}
                    </h3>

                    <p className="text-sm text-[#0077B6]/80 inline-flex items-center gap-2">
                        <FaLayerGroup className="opacity-80" />
                        ID entidad #
                        {update?.entity_id}
                    </p>
                </div>

                <div className="space-y-1 text-sm">
                    <div className="flex items-center gap-2 text-slate-700">
                        <FaCalendarAlt className="text-[#0077B6]" />

                        <span className="truncate">
                            {formatDate(
                                update?.created_at
                            )}
                        </span>
                    </div>

                    {address && (
                        <div className="flex items-center gap-2 text-slate-700">
                            <FaMapMarkerAlt className="text-[#0077B6]" />

                            <span className="truncate">
                                {address}
                            </span>
                        </div>
                    )}

                    <div className="text-xs text-slate-500">
                        {changes} cambio
                        {changes === 1 ? '' : 's'}{' '}
                        directo
                    </div>
                </div>

                <button
                    type="button"
                    onClick={() =>
                        onView?.(update)
                    }
                    className="w-full bg-[#0077B6] hover:bg-[#005f90] text-white font-semibold py-2 rounded-lg transition"
                >
                    Ver revisión
                </button>
            </div>
        </div>
    );
}