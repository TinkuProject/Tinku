// File: src/components/Review/EventViewReview.jsx
'use client';

import { useEffect, useMemo, useState } from 'react';
import {
    FaTimes,
    FaMapMarkerAlt,
    FaIdBadge,
    FaInfoCircle,
    FaCheckCircle,
    FaClock,
    FaBan,
    FaCalendarAlt,
    FaBuilding,
    FaLayerGroup,
    FaUsers,
    FaCoins,
} from 'react-icons/fa';

import { getUser } from '@/services/usersService';

const UI = {
    primary: '#0077B6',
    border: '#E2E8F0',
    chipActive: '#DCFCE7',
    chipFinished: '#E0F2FE',
    chipPending: '#FEF3C7',
    chipRejected: '#FEE2E2',
};

const PLACEHOLDER = 'https://via.placeholder.com/1280x720?text=Sin+imagen';

// 🆕 costo fijo de aprobación de evento
const COST_TINKU_EVENT = 5;

/* ===================== Utils ===================== */
function osmEmbedUrl(lat, lng, z = 14) {
    const bbox = [lng - 0.02, lat - 0.02, lng + 0.02, lat + 0.02].join('%2C');
    return `https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat}%2C${lng}&zoom=${z}`;
}

function mapEventStatus(raw) {
    const s = String(raw || '').toLowerCase();

    if (s === 'active') {
        return {
            key: 'active',
            label: 'Activo',
            bg: UI.chipActive,
            color: '#166534',
        };
    }

    if (s === 'finished') {
        return {
            key: 'finished',
            label: 'Finalizado',
            bg: UI.chipFinished,
            color: '#075985',
        };
    }

    // default: pending
    return {
        key: 'pending',
        label: 'Pendiente',
        bg: UI.chipPending,
        color: '#92400E',
    };
}

function mapValidated(raw) {
    const ok =
        raw === true ||
        raw === 1 ||
        (typeof raw === 'string' &&
            ['true', '1', 'yes', 'si', 'aprobado', 'validado'].includes(
                raw.toLowerCase()
            ));

    return ok;
}

/* ===================== Badges ===================== */
function StatusBadge({ status }) {
    const info = mapEventStatus(status);

    return (
        <span
            className="text-xs font-semibold px-2 py-1 rounded-full"
            style={{ background: info.bg, color: info.color }}
        >
            {info.label}
        </span>
    );
}

function ValidBadge({ validated }) {
    const ok = mapValidated(validated);
    return (
        <span
            className={`text-xs font-semibold px-2 py-1 rounded-full ${ok ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'
                }`}
            title={ok ? 'Validado' : 'Pendiente de validación'}
        >
            {ok ? 'Validado' : 'Pendiente'}
        </span>
    );
}

/* ===================== Componente ===================== */
export default function EventViewReview({
    event,
    images = [],
    categoryName = '—',
    onClose,
    onApprove,
    onReject,
    savingId,
}) {
    const gallery = images.length ? images : [PLACEHOLDER];
    const [current, setCurrent] = useState(0);

    // 👇 ID del evento
    const id = event?.id ?? event?.event_id ?? event?._id ?? '—';

    // 👇 Nombre de negocio / empresa asociado
    const businessName =
        event?.business_name ||
        event?.business?.name ||
        event?.business?.business_name ||
        '—';

    const meta = useMemo(() => {
        const coords = event?.location?.coordinates;
        const lng = Number(coords?.[0] ?? event?.lng ?? -66.1568);
        const lat = Number(coords?.[1] ?? event?.lat ?? -17.3895);

        const statusInfo = mapEventStatus(
            event?.status ?? event?.event_status ?? 'pending'
        );

        const validated = mapValidated(
            event?.validated ??
            event?.is_validated ??
            event?.approved ??
            event?.validation ??
            event?.validation_status
        );

        const createdAt =
            event?.created_at || event?.createdAt || event?.created || null;

        return {
            lat,
            lng,
            statusKey: statusInfo.key,
            statusLabel: statusInfo.label,
            validated,
            createdAt,
        };
    }, [event]);

    // ✅ Solo cuando el evento está en "pending" se pueden usar Aprobar/Rechazar
    const canEvaluate = meta.statusKey === 'pending';
    const isSaving =
        savingId != null &&
        Number(savingId) === Number(event?.id);

    // 🆕 Tinkus del propietario
    const [ownerBalance, setOwnerBalance] = useState(null);
    const [balanceStatus, setBalanceStatus] = useState('unknown'); // 'enough' | 'exact' | 'insufficient' | 'unknown'

    useEffect(() => {
        if (!event) return;

        const ownerId =
            event?.user_id ?? event?.owner_id ?? event?.creator_id ?? null;

        if (!ownerId) {
            setOwnerBalance(null);
            setBalanceStatus('unknown');
            return;
        }

        let cancelled = false;
        (async () => {
            try {
                const u = await getUser(ownerId);
                if (cancelled || !u) return;

                const current = Number(u.coin_balance ?? 0);
                setOwnerBalance(current);

                if (current > COST_TINKU_EVENT) setBalanceStatus('enough');
                else if (current === COST_TINKU_EVENT) setBalanceStatus('exact');
                else setBalanceStatus('insufficient');
            } catch (e) {
                console.error('[EventViewReview] Error cargando usuario:', e);
                setOwnerBalance(null);
                setBalanceStatus('unknown');
            }
        })();

        return () => {
            cancelled = true;
        };
    }, [event]);

    const balanceBadge = (() => {
        let bg = 'bg-slate-100';
        let text = 'text-slate-700';
        let label = 'Saldo no disponible';

        if (balanceStatus === 'enough') {
            bg = 'bg-emerald-100';
            text = 'text-emerald-800';
            label = 'Saldo suficiente';
        } else if (balanceStatus === 'exact') {
            bg = 'bg-amber-100';
            text = 'text-amber-800';
            label = 'Saldo justo';
        } else if (balanceStatus === 'insufficient') {
            bg = 'bg-rose-100';
            text = 'text-rose-800';
            label = 'Saldo insuficiente';
        }

        return { bg, text, label };
    })();

    const projectedBalance =
        typeof ownerBalance === 'number'
            ? ownerBalance - COST_TINKU_EVENT
            : null;

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
                                {event?.name || 'Evento'}
                            </h2>

                            <div className="flex flex-wrap items-center gap-3 text-xs text-slate-600 mt-1">
                                {/* Categoría */}
                                <div className="inline-flex items-center gap-1">
                                    <FaLayerGroup className="text-[#0077B6]" />
                                    <span className="font-medium text-[#0077B6]">
                                        {categoryName}
                                    </span>
                                </div>

                                {/* Negocio / Empresa */}
                                <div className="inline-flex items-center gap-1 text-slate-700">
                                    <span className="mx-1 text-slate-400">·</span>
                                    <FaBuilding className="mr-1" />
                                    {businessName}
                                </div>
                            </div>
                        </div>

                        <div className="flex items-center gap-2">
                            <StatusBadge status={event?.status} />
                            <ValidBadge validated={event?.validated} />

                            {/* ✅ Solo cuando el evento está pendiente */}
                            {canEvaluate && (
                                <>
                                    <button
                                        disabled={isSaving}
                                        onClick={() => {
                                            if (isSaving) return;
                                            onApprove?.(event);
                                        }}
                                        className={`inline-flex items-center gap-2 px-3 py-2 rounded-md text-white font-semibold transition
                ${isSaving
                                                ? 'bg-emerald-400 cursor-not-allowed opacity-70'
                                                : 'bg-emerald-600 hover:bg-emerald-700'
                                            }`}
                                        title="Aprobar"
                                    >
                                        <FaCheckCircle />
                                        {isSaving ? 'Procesando...' : 'Aprobar'}
                                    </button>

                                    <button
                                        disabled={isSaving}
                                        onClick={() => {
                                            if (isSaving) return;
                                            onReject?.(event);
                                        }}
                                        className={`inline-flex items-center gap-2 px-3 py-2 rounded-md text-white font-semibold transition
                ${isSaving
                                                ? 'bg-rose-400 cursor-not-allowed opacity-70'
                                                : 'bg-rose-600 hover:bg-rose-700'
                                            }`}
                                        title="Rechazar"
                                    >
                                        <FaBan />
                                        {isSaving ? 'Procesando...' : 'Rechazar'}
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
                            <div
                                className="rounded-lg overflow-hidden border"
                                style={{ borderColor: UI.border }}
                            >
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
                                                className={`relative aspect-[4/3] rounded-md overflow-hidden border ${i === current
                                                    ? 'ring-2 ring-[#0077B6]'
                                                    : 'hover:opacity-90'
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
                            <div
                                className="bg-white rounded-lg border p-4"
                                style={{ borderColor: UI.border }}
                            >
                                <div className="flex items-center gap-2 mb-3 text-slate-800">
                                    <FaInfoCircle />
                                    <h3 className="font-semibold">Detalle del evento</h3>
                                </div>

                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-3 text-[15px]">
                                    <Row
                                        label="ID"
                                        value={id}
                                        icon={<FaIdBadge className="text-slate-400" />}
                                    />

                                    <Row
                                        label="Estado del evento"
                                        value={meta.statusLabel}
                                    />

                                    <Row
                                        label="Validación"
                                        value={meta.validated ? 'Validado' : 'Pendiente'}
                                    />

                                    <Row
                                        label="Categoría"
                                        value={categoryName}
                                        icon={<FaLayerGroup className="text-slate-400" />}
                                    />

                                    <Row
                                        label="Negocio / Empresa"
                                        value={businessName}
                                        icon={<FaBuilding className="text-slate-400" />}
                                    />

                                    <Row
                                        label="Fecha de inicio"
                                        value={
                                            event?.start_date
                                                ? new Date(event.start_date).toLocaleString()
                                                : '—'
                                        }
                                        icon={<FaCalendarAlt className="text-slate-400" />}
                                    />

                                    <Row
                                        label="Fecha de fin"
                                        value={
                                            event?.end_date
                                                ? new Date(event.end_date).toLocaleString()
                                                : '—'
                                        }
                                        icon={<FaCalendarAlt className="text-slate-400" />}
                                    />

                                    <Row
                                        label="Nº esperado de asistentes"
                                        value={event?.attendees_number ?? '—'}
                                        icon={<FaUsers className="text-slate-400" />}
                                    />

                                    <Row
                                        label="Dirección"
                                        value={event?.address || '—'}
                                        icon={<FaMapMarkerAlt className="text-[#0077B6]" />}
                                    />

                                    <Row
                                        label="Coordenadas"
                                        value={`${meta.lat.toFixed(5)}, ${meta.lng.toFixed(5)}`}
                                    />

                                    <Row
                                        label="Creado"
                                        value={
                                            meta.createdAt
                                                ? new Date(meta.createdAt).toLocaleString()
                                                : '—'
                                        }
                                        icon={<FaClock className="text-slate-400" />}
                                    />
                                </div>

                                {event?.description && (
                                    <div className="mt-4">
                                        <p className="text-sm font-medium text-slate-700 mb-1">
                                            Descripción
                                        </p>
                                        <p className="text-slate-700 whitespace-pre-line">
                                            {event.description}
                                        </p>
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Derecha: mapa + Tinkus */}
                        <div className="space-y-4">
                            

                            {/* Mapa */}
                            <div
                                className="bg-white rounded-lg border overflow-hidden"
                                style={{ borderColor: UI.border }}
                            >
                                <div
                                    className="px-4 py-2 text-sm font-semibold text-slate-700 border-b"
                                    style={{ borderColor: UI.border }}
                                >
                                    Ubicación del evento
                                </div>
                                <div className="h-56">
                                    <iframe
                                        title="mapa-evento"
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
        <div className="grid grid-cols-[160px_1fr] items-start gap-3">
            <div className="text-slate-500 font-medium flex items-center gap-2">
                {icon} {label}
            </div>
            <div className="text-slate-800">{content ?? '—'}</div>
        </div>
    );
}
