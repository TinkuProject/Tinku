// File: src/components/Events/EventView.jsx
'use client';

import {
    FaCalendarAlt,
    FaMapMarkerAlt,
    FaUsers,
    FaTimes,
    FaImage,
} from 'react-icons/fa';

const UI = {
    primary: '#0077B6',
    border: '#E2E8F0',
};

const PLACEHOLDER = '/images/no-image.jpg';

function formatDate(value) {
    if (!value) return '—';

    try {
        return new Date(value).toLocaleString();
    } catch {
        return String(value);
    }
}

export default function EventView({ event, onClose }) {
    if (!event) return null;

    const {
        name,
        description,
        address,
        start_date,
        end_date,
        capacity,
        tinku_price,
        status,
        business_name,
        category_name,
        images = [],
    } = event;

    const cover = images?.[0] || PLACEHOLDER;

    const statusLabel =
        status === 'active'
            ? 'Activo'
            : status === 'finished'
                ? 'Finalizado'
                : status === 'cancelled'
                    ? 'Cancelado'
                    : 'Pendiente';

    const statusClasses =
        status === 'active'
            ? 'bg-green-100 text-green-700'
            : status === 'finished'
                ? 'bg-slate-200 text-slate-700'
                : status === 'cancelled'
                    ? 'bg-red-100 text-red-700'
                    : 'bg-amber-100 text-amber-700';

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <div className="bg-white rounded-xl shadow-2xl max-w-4xl w-full mx-4 max-h-[90vh] flex flex-col overflow-hidden">
                <div
                    className="flex items-center justify-between px-6 py-4 border-b"
                    style={{ borderColor: UI.border }}
                >
                    <div>
                        <h2 className="text-lg font-semibold text-slate-900">
                            Detalle del evento
                        </h2>

                        <p className="text-xs text-slate-500">
                            Revisa toda la información registrada de este evento.
                        </p>
                    </div>

                    <button
                        type="button"
                        onClick={onClose}
                        className="p-2 rounded-full hover:bg-slate-100 text-slate-500"
                    >
                        <FaTimes />
                    </button>
                </div>

                <div className="flex-1 overflow-y-auto">
                    <div className="relative">
                        <img
                            src={cover}
                            alt={name || 'Evento'}
                            className="w-full h-64 object-cover"
                            onError={(e) => {
                                e.currentTarget.src = PLACEHOLDER;
                            }}
                        />

                        {images.length > 1 && (
                            <div className="absolute top-3 right-3 px-3 py-1 rounded-full bg-black/60 text-white text-xs flex items-center gap-1">
                                <FaImage />
                                <span>{images.length} fotos</span>
                            </div>
                        )}
                    </div>

                    <div className="px-6 py-4 space-y-4">
                        <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-3">
                            <div>
                                <h3 className="text-xl font-bold text-slate-900">
                                    {name || '—'}
                                </h3>

                                <div className="flex flex-wrap items-center gap-2 mt-1 text-sm text-slate-600">
                                    {business_name && (
                                        <span className="font-medium text-[#0077B6]">
                                            {business_name}
                                        </span>
                                    )}

                                    {category_name && (
                                        <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-700 text-xs">
                                            {category_name}
                                        </span>
                                    )}
                                </div>
                            </div>

                            {status && (
                                <span
                                    className={`inline-flex px-3 py-1 rounded-full text-xs font-semibold ${statusClasses}`}
                                >
                                    {statusLabel}
                                </span>
                            )}
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
                            <div className="flex items-start gap-2">
                                <FaCalendarAlt className="mt-1 text-[#0077B6]" />

                                <div>
                                    <p className="text-xs text-slate-500">Fechas</p>

                                    <p className="font-medium text-slate-800">
                                        {formatDate(start_date)}

                                        <span className="text-slate-400 mx-1">→</span>

                                        {formatDate(end_date)}
                                    </p>
                                </div>
                            </div>

                            <div className="flex items-start gap-2">
                                <FaMapMarkerAlt className="mt-1 text-[#0077B6]" />

                                <div>
                                    <p className="text-xs text-slate-500">Dirección</p>

                                    <p className="font-medium text-slate-800">
                                        {address || '—'}
                                    </p>
                                </div>
                            </div>

                            <div className="flex items-start gap-2">
                                <FaUsers className="mt-1 text-[#0077B6]" />

                                <div>
                                    <p className="text-xs text-slate-500">
                                        Capacidad máxima
                                    </p>

                                    <p className="font-medium text-slate-800">
                                        {capacity ?? '—'}
                                    </p>
                                </div>
                            </div>
                        </div>

                        {tinku_price !== undefined &&
                            tinku_price !== null && (
                                <div className="inline-flex px-3 py-1 rounded-full bg-[#0077B6]/10 text-[#0077B6] text-sm font-semibold">
                                    {tinku_price} Tinkus
                                </div>
                            )}

                        {description && (
                            <div>
                                <h4 className="text-sm font-semibold text-slate-900 mb-1">
                                    Descripción
                                </h4>

                                <p className="text-sm text-slate-700 whitespace-pre-line">
                                    {description}
                                </p>
                            </div>
                        )}

                        {images.length > 1 && (
                            <div className="mt-4">
                                <h4 className="text-sm font-semibold text-slate-900 mb-2">
                                    Galería de fotos
                                </h4>

                                <div className="flex gap-2 overflow-x-auto pb-1">
                                    {images.map((img, idx) => (
                                        <img
                                            key={idx}
                                            src={img}
                                            alt={`Imagen ${idx + 1}`}
                                            className="w-28 h-20 object-cover rounded-md border cursor-pointer flex-shrink-0"
                                            style={{ borderColor: UI.border }}
                                            onError={(e) => {
                                                e.currentTarget.src = PLACEHOLDER;
                                            }}
                                        />
                                    ))}
                                </div>
                            </div>
                        )}
                    </div>

                    <div
                        className="px-6 py-4 border-t bg-slate-50/80 flex justify-end"
                        style={{ borderColor: UI.border }}
                    >
                        <button
                            type="button"
                            onClick={onClose}
                            className="px-4 py-2 rounded-lg text-sm font-semibold border bg-white text-slate-700 hover:bg-slate-100"
                            style={{ borderColor: UI.border }}
                        >
                            Cerrar
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}