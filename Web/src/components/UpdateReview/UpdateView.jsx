// File: src/components/Review/UpdateReview/UpdateView.jsx
'use client';

import { useMemo, useState } from 'react';
import {
    FaTimes,
    FaCheckCircle,
    FaBan,
    FaInfoCircle,
    FaExchangeAlt,
} from 'react-icons/fa';

const UI = {
    primary: '#0077B6',
    border: '#E2E8F0',
};

const HIDDEN_KEYS = [
    'media',
    'socials',
    'hours',
    'transport',
];

const FIELD_LABELS = {
    // Generales
    id: 'ID',
    name: 'Nombre',
    description: 'Descripción',
    status: 'Estado',
    validated: 'Validado',
    created_at: 'Fecha de creación',
    updated_at: 'Fecha de actualización',

    // Ubicación
    address: 'Dirección',
    latitude: 'Latitud',
    longitude: 'Longitud',
    location: 'Ubicación',

    // Categoría
    category_id: 'Categoría',

    // Business
    nit: 'NIT',
    email: 'Correo electrónico',
    phone: 'Teléfono',
    website: 'Sitio web',
    business_type: 'Tipo de negocio',
    owner_id: 'Propietario',

    // Event
    business_id: 'Negocio',
    capacity: 'Capacidad',
    start_date: 'Fecha de inicio',
    end_date: 'Fecha de finalización',
    tinku_price: 'Precio Tinku',
    price: 'Precio',
    is_free: 'Evento gratuito',
    event_type: 'Tipo de evento',
    image: 'Imagen',
};

function formatValue(value) {
    if (
        value === null ||
        value === undefined ||
        value === ''
    ) {
        return '—';
    }

    if (Array.isArray(value)) {
        return value.join(', ');
    }

    if (typeof value === 'object') {
        return JSON.stringify(
            value,
            null,
            2
        );
    }

    return String(value);
}

function getChangedRows(
    current = {},
    requested = {}
) {
    return Object.keys(requested || {})
        .filter(
            (key) =>
                !HIDDEN_KEYS.includes(key)
        )
        .map((key) => ({
            key,
            current: current?.[key],
            requested:
                requested?.[key],
            changed:
                JSON.stringify(
                    current?.[key] ?? null
                ) !==
                JSON.stringify(
                    requested?.[key] ?? null
                ),
        }));
}

function StatusBadge({ status }) {
    const s = String(status || '')
        .toLowerCase();

    if (s === 'approved') {
        return (
            <span className="px-2 py-1 text-xs rounded-full bg-emerald-100 text-emerald-700 border border-emerald-200 font-semibold">
                Aprobado
            </span>
        );
    }

    if (s === 'rejected') {
        return (
            <span className="px-2 py-1 text-xs rounded-full bg-rose-100 text-rose-700 border border-rose-200 font-semibold">
                Rechazado
            </span>
        );
    }

    return (
        <span className="px-2 py-1 text-xs rounded-full bg-amber-100 text-amber-700 border border-amber-200 font-semibold">
            Pendiente
        </span>
    );
}

export default function UpdateView({
    update,
    currentEntity,
    images = [],
    savingId,
    onClose,
    onApprove,
    onReject,
}) {
    const [comment, setComment] =
        useState('');

    const [currentImage, setCurrentImage] =
        useState(0);

    const gallery = images?.length
        ? images
        : [];

    const data = update?.data || {};

    const rows = useMemo(
        () =>
            getChangedRows(
                currentEntity || {},
                data
            ),
        [currentEntity, data]
    );

    const isSaving =
        savingId != null &&
        Number(savingId) ===
        Number(update?.id);

    const canEvaluate =
        update?.status === 'pending';

    const title =
        data?.name ||
        currentEntity?.name ||
        `${update?.entity_type} #${update?.entity_id}`;

    return (
        <div className="fixed inset-0 z-50">
            <div
                className="absolute inset-0 bg-black/40"
                onClick={onClose}
            />

            <div className="absolute inset-0 grid place-items-center p-6">
                <div
                    className="w-full max-w-6xl bg-white rounded-xl shadow-2xl border overflow-hidden"
                    style={{
                        borderColor: UI.border,
                    }}
                >
                    <div
                        className="px-6 py-4 flex items-center justify-between gap-4"
                        style={{
                            borderBottom: `1px solid ${UI.border}`,
                            background:
                                '#F8FAFC',
                        }}
                    >
                        <div className="min-w-0">
                            <h2 className="text-2xl font-bold text-slate-900 truncate">
                                {title}
                            </h2>

                            <p className="text-sm text-[#0077B6] font-medium">
                                Solicitud #
                                {update?.id} ·{' '}
                                {
                                    update?.entity_type
                                }{' '}
                                #
                                {
                                    update?.entity_id
                                }
                            </p>
                        </div>

                        <div className="flex items-center gap-2">
                            <StatusBadge
                                status={
                                    update?.status
                                }
                            />

                            {canEvaluate && (
                                <>
                                    <button
                                        disabled={
                                            isSaving
                                        }
                                        onClick={() =>
                                            onApprove?.(
                                                update,
                                                comment
                                            )
                                        }
                                        className="inline-flex items-center gap-2 px-3 py-2 rounded-md text-white font-semibold bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 disabled:cursor-not-allowed"
                                    >
                                        <FaCheckCircle />

                                        {isSaving
                                            ? 'Procesando…'
                                            : 'Aprobar'}
                                    </button>

                                    <button
                                        disabled={
                                            isSaving
                                        }
                                        onClick={() =>
                                            onReject?.(
                                                update,
                                                comment
                                            )
                                        }
                                        className="inline-flex items-center gap-2 px-3 py-2 rounded-md text-white font-semibold bg-rose-600 hover:bg-rose-700 disabled:opacity-60 disabled:cursor-not-allowed"
                                    >
                                        <FaBan />

                                        {isSaving
                                            ? 'Procesando…'
                                            : 'Rechazar'}
                                    </button>
                                </>
                            )}

                            <button
                                onClick={onClose}
                                className="inline-flex items-center justify-center w-10 h-10 rounded-full border text-slate-700 hover:bg-slate-50"
                            >
                                <FaTimes />
                            </button>
                        </div>
                    </div>

                    <div className="p-6 max-h-[75vh] overflow-y-auto space-y-5">
                        {/* GALERIA */}
                        {gallery.length > 0 && (
                            <div
                                className="bg-white rounded-lg border overflow-hidden"
                                style={{
                                    borderColor:
                                        UI.border,
                                }}
                            >
                                <img
                                    src={
                                        gallery[
                                        currentImage
                                        ]
                                    }
                                    alt={`media-${currentImage}`}
                                    className="w-full h-72 object-cover bg-slate-100"
                                    onError={(
                                        e
                                    ) => {
                                        e.currentTarget.style.display =
                                            'none';
                                    }}
                                />

                                {gallery.length >
                                    1 && (
                                        <div className="p-3 grid grid-cols-5 sm:grid-cols-6 md:grid-cols-8 gap-2 bg-white">
                                            {gallery.map(
                                                (
                                                    url,
                                                    i
                                                ) => (
                                                    <button
                                                        key={`${url}-${i}`}
                                                        type="button"
                                                        onClick={() =>
                                                            setCurrentImage(
                                                                i
                                                            )
                                                        }
                                                        className={`relative aspect-[4/3] rounded-md overflow-hidden border ${i ===
                                                            currentImage
                                                            ? 'ring-2 ring-[#0077B6]'
                                                            : 'hover:opacity-90'
                                                            }`}
                                                        style={{
                                                            borderColor:
                                                                UI.border,
                                                        }}
                                                    >
                                                        <img
                                                            src={url}
                                                            alt={`thumb-${i}`}
                                                            className="w-full h-full object-cover"
                                                        />
                                                    </button>
                                                )
                                            )}
                                        </div>
                                    )}
                            </div>
                        )}

                        {/* COMPARACION */}
                        <div
                            className="bg-white rounded-lg border p-4"
                            style={{
                                borderColor:
                                    UI.border,
                            }}
                        >
                            <div className="flex items-center gap-2 mb-3 text-slate-800">
                                <FaInfoCircle />

                                <h3 className="font-semibold">
                                    Comparación de
                                    cambios
                                </h3>
                            </div>

                            <div className="overflow-x-auto">
                                <table className="min-w-full text-sm border rounded-lg overflow-hidden">
                                    <thead className="bg-slate-100 text-slate-800">
                                        <tr>
                                            <th className="px-3 py-2 text-left">
                                                Campo
                                            </th>

                                            <th className="px-3 py-2 text-left">
                                                Actual
                                            </th>

                                            <th className="px-3 py-2 text-left">
                                                Solicitado
                                            </th>

                                            <th className="px-3 py-2 text-left">
                                                Estado
                                            </th>
                                        </tr>
                                    </thead>

                                    <tbody>
                                        {rows.length ? (
                                            rows.map(
                                                (row) => (
                                                    <tr
                                                        key={
                                                            row.key
                                                        }
                                                        className="border-t"
                                                        style={{
                                                            borderColor:
                                                                UI.border,
                                                        }}
                                                    >
                                                        <td className="px-3 py-2 font-semibold text-slate-700">
                                                            {FIELD_LABELS[row.key] ?? row.key}
                                                        </td>

                                                        <td className="px-3 py-2 text-slate-600 whitespace-pre-wrap">
                                                            {formatValue(
                                                                row.current
                                                            )}
                                                        </td>

                                                        <td className="px-3 py-2 text-slate-900 whitespace-pre-wrap">
                                                            {formatValue(
                                                                row.requested
                                                            )}
                                                        </td>

                                                        <td className="px-3 py-2">
                                                            {row.changed ? (
                                                                <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs bg-sky-100 text-sky-700 border border-sky-200 font-semibold">
                                                                    <FaExchangeAlt />
                                                                    Cambia
                                                                </span>
                                                            ) : (
                                                                <span className="px-2 py-1 rounded-full text-xs bg-slate-100 text-slate-600 border border-slate-200 font-semibold">
                                                                    Igual
                                                                </span>
                                                            )}
                                                        </td>
                                                    </tr>
                                                )
                                            )
                                        ) : (
                                            <tr>
                                                <td
                                                    colSpan={
                                                        4
                                                    }
                                                    className="px-3 py-5 text-center text-slate-500"
                                                >
                                                    No hay
                                                    campos
                                                    directos
                                                    para
                                                    comparar.
                                                </td>
                                            </tr>
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        {/* EXTRA */}
                        {/*{(data?.media ||
                            data?.socials ||
                            data?.hours ||
                            data?.transport) && (
                                <div
                                    className="bg-white rounded-lg border p-4"
                                    style={{
                                        borderColor:
                                            UI.border,
                                    }}
                                >
                                    <div className="flex items-center gap-2 mb-3 text-slate-800">
                                        <FaInfoCircle />

                                        <h3 className="font-semibold">
                                            Cambios
                                            adicionales
                                        </h3>
                                    </div>

                                    <pre className="text-xs bg-slate-50 border rounded-lg p-3 overflow-x-auto text-slate-700">
                                        {JSON.stringify(
                                            {
                                                media:
                                                    data?.media,
                                                socials:
                                                    data?.socials,
                                                hours:
                                                    data?.hours,
                                                transport:
                                                    data?.transport,
                                            },
                                            null,
                                            2
                                        )}
                                    </pre>
                                </div>
                            )} */}

                        {/* COMMENT */}
                        {canEvaluate && (
                            <div
                                className="bg-white rounded-lg border p-4"
                                style={{
                                    borderColor:
                                        UI.border,
                                }}
                            >
                                <label className="block text-sm font-semibold text-slate-700 mb-2">
                                    Comentario
                                    de revisión
                                </label>

                                <textarea
                                    value={comment}
                                    onChange={(e) =>
                                        setComment(
                                            e.target
                                                .value
                                        )
                                    }
                                    rows={3}
                                    placeholder="Opcional: escribe una observación para aprobar o rechazar…"
                                    className="w-full px-3 py-2 rounded-lg border text-sm outline-none focus:ring-2 focus:ring-[#0077B6]/30"
                                    style={{
                                        borderColor:
                                            UI.border,
                                    }}
                                />
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}