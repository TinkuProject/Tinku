// File: src/components/Review/EventReview.jsx
'use client';

import { useEffect, useMemo, useState } from 'react';
import { FaSearch, FaSyncAlt } from 'react-icons/fa';

import EventCardReview from '@/components/Review/EventCardReview';
import EventViewReview from '@/components/Review/EventViewReview';
import { NotificationsService } from "@/services/notificationsService";

import useEvents from '@/hooks/useEvents';
import { useUser } from "@/context/UserContext";
import useMedia from '@/hooks/useMedia';
import useCategories from '@/hooks/useCategories';
import toast from 'react-hot-toast';


const UI = { primary: '#0077B6', border: '#E2E8F0' };


// Skeleton para carga
function CardSkeleton() {
    return (
        <div
            className="bg-white border rounded-xl shadow-sm overflow-hidden animate-pulse"
            style={{ borderColor: UI.border }}
        >
            <div className="h-44 bg-slate-200" />
            <div className="p-4 space-y-2">
                <div className="h-5 bg-slate-200 rounded w-2/3" />
                <div className="h-4 bg-slate-200 rounded w-1/2" />
                <div className="h-4 bg-slate-200 rounded w-1/3" />
                <div className="h-9 bg-slate-200 rounded mt-3" />
            </div>
        </div>
    );
}

/**
 * Normaliza "aprobado" para eventos.
 * Si tienes campo validated lo respeta,
 * si no, cae a status === 'active' como aprobado.
 */
const isValidated = (ev) => {
    const rawValidated =
        ev?.validated ??
        ev?.is_validated ??
        ev?.approved ??
        ev?.validation ??
        ev?.validation_status;

    if (rawValidated === true || rawValidated === 1) return true;
    if (rawValidated === false || rawValidated === 0) return false;
    if (typeof rawValidated === 'string') {
        const s = rawValidated.trim().toLowerCase();
        if (['true', '1', 'yes', 'si', 'approved', 'aprobado', 'validado'].includes(s)) {
            return true;
        }
    }

    // fallback: status "active" lo tratamos como aprobado
    const rawStatus = ev?.status;
    if (typeof rawStatus === 'string') {
        const s = rawStatus.trim().toLowerCase();
        return ['active', 'aprobado'].includes(s);
    }

    return false;
};

/**
 * Normaliza "rechazado" para eventos.
 * Por convención: status === 'rejected' | 'rechazado' | 3
 */
const isRejected = (ev) => {
    const raw = ev?.status ?? ev?.estado ?? ev?.is_active ?? ev?.active;
    let n;

    if (typeof raw === 'number') {
        n = raw;
    } else if (typeof raw === 'boolean') {
        n = raw ? 1 : 0;
    } else {
        const s = String(raw || '').toLowerCase();
        if (['rejected', 'rechazado'].includes(s)) n = 3;
        else if (s === 'active') n = 1;
        else n = 0;
    }

    return n === 2 || n === 3;
};

const STATUS_FILTERS = [
    { id: 'pending', label: 'Pendientes' },
    { id: 'active', label: 'Activos' },
    { id: 'finished', label: 'Finalizados' },
    { id: 'cancelled', label: 'Cancelados' },
    { id: 'all', label: 'Todos' },
];

export default function EventReview() {
    // ====== DATA BASE ======
    const {
        filteredRows: events,
        loading,
        fetchAll,
        approveOne,
        rejectOne,
        savingId,
        statusFilter,
        setStatusFilter,
    } = useEvents({
        autoLoad: true,
    });

    const { fetchForBusinessIds } = useMedia();
    const { categories, loadingList: loadingCats } = useCategories();

    const [viewing, setViewing] = useState(null);
    const [submitting, setSubmitting] = useState(false);

    // SOLO este filtro local queda
    const [query, setQuery] = useState('');

    // ====== CATEGORÍAS (solo de tipo event) ======
    const categoryOptions = useMemo(
        () =>
            (categories || [])
                .filter((c) => {
                    const t = (c.type || c.category_type || '').toString().toLowerCase();
                    return t === 'event';
                })
                .map((c) => ({ value: c.id, label: c.name })),
        [categories]
    );

    const getCategoryName = (ev) => {
        if (ev?.category?.name) return ev.category.name;
        const hit = categoryOptions.find(
            (o) => String(o.value) === String(ev?.category_id)
        );
        return hit?.label ?? '—';
    };

    const { user } = useUser();
    const senderId =
        user?.id ??
        user?.idUser ??
        user?.user_id ??
        user?.uid ??
        null;

    // ====== LISTA FILTRADA ======
    const listForUI = useMemo(() => {
        const list = Array.isArray(events) ? events : [];

        const byStatus = list.filter((ev) => {
            const status = String(
                ev?.status ??
                ev?.estado ??
                ''
            )
                .trim()
                .toLowerCase();

            if (statusFilter === 'all') return true;

            // finished
            if (statusFilter === 'finished') {
                return status === 'finished';
            }

            // pending
            if (statusFilter === 'pending') {
                return status === 'pending';
            }

            // active
            if (statusFilter === 'active') {
                return status === 'active';
            }

            // cancelled
            if (statusFilter === 'cancelled') {
                return status === 'cancelled';
            }

            return false;
        });

        const q = query.trim().toLowerCase();
        if (!q) return byStatus;

        return byStatus.filter((ev) =>
            [ev.name, ev.description, ev.address, ev.business_name]
                .filter(Boolean)
                .some((v) => String(v).toLowerCase().includes(q))
        );
    }, [events, statusFilter, query]);

    // ====== MEDIA POR EVENTO ======
    const [mediaByEvent, setMediaByEvent] = useState({});
    const ids = useMemo(
        () =>
            listForUI
                .map((ev) => ev.id ?? ev._id ?? ev.event_id)
                .filter((id) => id !== undefined && id !== null)
                .map((id) => Number(id))
                .filter((n) => Number.isFinite(n)),
        [listForUI]
    );

    useEffect(() => {
        if (!ids.length) {
            setMediaByEvent({});
            return;
        }

        let mounted = true;
        (async () => {
            const map = await fetchForBusinessIds(ids, 'event');
            if (!mounted) return;

            const obj = {};
            map.forEach((arr, id) => {
                const idStr = String(id);
                const own = (arr || []).filter(
                    (m) =>
                        String(m?.entity_id ?? m?.target_id ?? m?.targetId) === idStr
                );

                obj[idStr] = own
                    .map((m) => m?.url || m?.image_url || m?.media_url || m?.path || m?.fileUrl)
                    .filter(Boolean);
            });
            setMediaByEvent(obj);
        })();

        return () => {
            mounted = false;
        };
    }, [ids, fetchForBusinessIds]);

    // ====== MODAL: ACCIONES ======
    const closeModal = () => {
        if (!submitting) setViewing(null);
    };

    const handleApprove = async () => {
        const ev = viewing?.event;

        const id = Number(
            ev?.id ?? ev?.event_id ?? ev?._id
        );

        if (!id || submitting) return;

        setSubmitting(true);

        try {
            // ✅ APROBACIÓN REAL
            await approveOne(id);

            await fetchAll();

            toast.success('Evento aprobado correctamente ✔️');

            // 🔔 NOTIFICACIÓN
            try {
                const ownerId =
                    ev?.user_id ??
                    ev?.owner_id ??
                    ev?.creator_id ??
                    null;

                if (ownerId && senderId) {
                    await NotificationsService.create({
                        user_id: ownerId,
                        sender_id: senderId,
                        message: `Tu evento "${ev.name}" ha sido aprobado 🎉`,
                    });
                }
            } catch (err) {
                console.warn(
                    '[EventReview] Error enviando notificación:',
                    err
                );
            }

            setViewing(null);
        } catch (e) {
            console.error(e);

            if (
                String(e?.message || '').includes(
                    'Event already processed'
                )
            ) {
                toast.error('Este evento ya fue procesado.');
                await fetchAll();
                setViewing(null);
                return;
            }

            toast.error(
                e?.message || 'No se pudo aprobar el evento'
            );
        } finally {
            setSubmitting(false);
        }
    };

    const handleReject = async () => {
        const ev = viewing?.event;

        const id = Number(
            ev?.id ?? ev?.event_id ?? ev?._id
        );

        if (!id || submitting) return;

        setSubmitting(true);

        try {
            // ✅ RECHAZO REAL
            await rejectOne(id);

            // 🔔 NOTIFICACIÓN
            try {
                const ownerId =
                    ev?.user_id ??
                    ev?.owner_id ??
                    ev?.creator_id ??
                    null;

                if (ownerId && senderId) {
                    await NotificationsService.create({
                        user_id: ownerId,
                        sender_id: senderId,
                        message: `Tu evento "${ev.name}" ha sido rechazado ❌`,
                    });
                }
            } catch (err) {
                console.warn(
                    '[EventReview] Error enviando notificación:',
                    err
                );
            }

            await fetchAll();

            setViewing(null);

            toast.success('Evento rechazado');
        } catch (e) {
            console.error(e);

            if (
                String(e?.message || '').includes(
                    'Event already processed'
                )
            ) {
                toast.error('Este evento ya fue procesado.');
                await fetchAll();
                setViewing(null);
                return;
            }

            toast.error(
                e?.message || 'No se pudo rechazar el evento'
            );
        } finally {
            setSubmitting(false);
        }
    };

    const emptyText = (() => {
        switch (statusFilter) {
            case 'pending':
                return 'No hay eventos pendientes.';
            case 'active':
                return 'No hay eventos activos.';
            case 'finished':
                return 'No hay eventos finalizados.';
            case 'all':
            default:
                return 'No hay eventos que coincidan con el filtro.';
        }
    })();

    // ====== RENDER ======
    return (
        <section>
            <h2 className="text-2xl font-semibold text-slate-900 mb-1">
                Revisión de Eventos
            </h2>
            <p className="text-slate-600 mb-4">
                Aprueba o rechaza solicitudes de creación de eventos.
            </p>

            {/* Filtros de estado */}
            <div className="mb-3 flex flex-wrap gap-2">
                {STATUS_FILTERS.map((f) => {
                    const active = statusFilter === f.id;
                    return (
                        <button
                            key={f.id}
                            onClick={() => setStatusFilter(f.id)}
                            className={`text-xs sm:text-sm inline-flex items-center px-3 py-1.5 rounded-full border transition font-medium
        ${active ? 'bg-white text-[#0077B6]' : 'bg-slate-50 text-slate-600 hover:bg-slate-100'}
      `}
                            style={{ borderColor: active ? UI.primary : UI.border }}
                        >
                            {f.label}
                        </button>
                    );
                })}

            </div>

            {/* Búsqueda + recargar */}
            <div className="mb-4 flex items-center gap-2">
                <div className="relative flex-1 min-w-[260px]">
                    <FaSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                    <input
                        value={query}
                        onChange={(e) => setQuery(e.target.value)}
                        className="w-full pl-10 pr-3 py-2 text-sm rounded-lg border bg-white outline-none
                       text-slate-900 placeholder:text-slate-400/90
                       focus:ring-2 focus:ring-[#0077B6]/30 focus:border-[#0077B6]"
                        style={{ borderColor: UI.border }}
                        placeholder="Buscar por nombre, negocio, descripción o dirección…"
                    />
                </div>
                <button
                    onClick={async () => {
                        try {
                            await fetchAll();
                            toast.success('Lista de eventos actualizada');
                        } catch (e) {
                            console.error(e);
                            toast.error('No se pudo recargar la lista');
                        }
                    }}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold border bg-[#EFF4FB] text-slate-800 hover:bg-[#E7EEF9] transition"
                    style={{ borderColor: UI.border }}
                    disabled={loading}
                >
                    <FaSyncAlt className={`opacity-70 ${loading ? 'animate-spin' : ''}`} />
                    Recargar
                </button>
            </div>

            {/* Grid de cards */}
            {loading && (!events || events.length === 0) ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
                    {Array.from({ length: 6 }).map((_, i) => (
                        <CardSkeleton key={i} />
                    ))}
                </div>
            ) : listForUI.length ? (
                <>
                    {loadingCats && (
                        <p className="text-xs text-slate-500 mb-2">
                            Cargando categorías de eventos…
                        </p>
                    )}
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
                        {listForUI.map((ev) => {
                            const id = Number(ev.id ?? ev._id ?? ev.event_id);
                            const imgs = mediaByEvent[String(id)] ?? [];
                            return (
                                <EventCardReview
                                    key={id}
                                    event={ev}
                                    categoryName={getCategoryName(ev)}
                                    imageUrl={imgs[0]}
                                    onEvaluate={() =>
                                        setViewing({
                                            event: ev,
                                            categoryName: getCategoryName(ev),
                                            images: imgs,
                                        })
                                    }
                                />
                            );
                        })}
                    </div>
                </>
            ) : (
                <div className="p-6 border rounded-lg bg-white text-slate-500 text-center">
                    {emptyText}
                </div>
            )}

            {viewing && (
                <EventViewReview
                    event={viewing.event}
                    images={viewing.images}
                    categoryName={viewing.categoryName}
                    onClose={closeModal}
                    onApprove={handleApprove}
                    onReject={handleReject}
                    submitting={submitting}
                    savingId={savingId}
                />
            )}
        </section>
    );
}
