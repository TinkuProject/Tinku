// File: src/components/Review/UpdateReview/UpdateReview.jsx
'use client';

import { useEffect, useMemo, useState } from 'react';
import { FaSearch, FaSyncAlt } from 'react-icons/fa';
import toast from 'react-hot-toast';

import useEntityUpdates from '@/hooks/useEntityUpdates';
import useMedia from '@/hooks/useMedia';

import UpdateCard from './UpdateCard';
import UpdateView from './UpdateView';

const UI = {
    primary: '#0077B6',
    border: '#E2E8F0',
};

const TYPE_FILTERS = [
    { id: 'all', label: 'Todos' },
    { id: 'business', label: 'Negocios' },
    { id: 'event', label: 'Eventos' },
];

const STATUS_FILTERS = [
    { id: 'pending', label: 'Pendientes' },
    { id: 'approved', label: 'Aprobados' },
    { id: 'rejected', label: 'Rechazados' },
    { id: 'all', label: 'Todos' },
];

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

export default function UpdateReview() {
    const {
        updates,
        loading,
        savingId,
        fetchAll,
        approveOne,
        rejectOne,
        getCurrentForUpdate,
    } = useEntityUpdates({
        autoLoad: true,
    });

    const { fetchForBusinessIds } = useMedia();

    const [mediaByUpdate, setMediaByUpdate] = useState({});

    const [viewing, setViewing] = useState(null);

    const [query, setQuery] = useState('');

    const [typeFilter, setTypeFilter] = useState('all');

    const [statusFilter, setStatusFilter] = useState('pending');

    const filtered = useMemo(() => {
        const list = Array.isArray(updates)
            ? updates
            : [];

        const byType = list.filter((row) => {
            if (typeFilter === 'all') return true;

            return row?.entity_type === typeFilter;
        });

        const byStatus = byType.filter((row) => {
            if (statusFilter === 'all') return true;

            return row?.status === statusFilter;
        });

        const q = query.trim().toLowerCase();

        if (!q) return byStatus;

        return byStatus.filter((row) => {
            const data = row?.data || {};

            const current =
                getCurrentForUpdate(row) || {};

            return [
                row?.entity_type,
                row?.status,
                data?.name,
                data?.description,
                data?.address,
                current?.name,
                current?.description,
                current?.address,
            ]
                .filter(Boolean)
                .some((value) =>
                    String(value)
                        .toLowerCase()
                        .includes(q)
                );
        });
    }, [
        updates,
        typeFilter,
        statusFilter,
        query,
        getCurrentForUpdate,
    ]);

    const mediaGroups = useMemo(() => {
        const businessIds = [];
        const eventIds = [];

        filtered.forEach((row) => {
            const id = Number(row?.entity_id);

            if (!Number.isFinite(id)) return;

            if (row?.entity_type === 'business') {
                businessIds.push(id);
            }

            if (row?.entity_type === 'event') {
                eventIds.push(id);
            }
        });

        return {
            businessIds,
            eventIds,
        };
    }, [filtered]);

    useEffect(() => {
        let mounted = true;

        const loadMedia = async () => {
            const obj = {};

            try {
                if (mediaGroups.businessIds.length) {
                    const map =
                        await fetchForBusinessIds(
                            mediaGroups.businessIds,
                            'business'
                        );

                    map.forEach((arr, id) => {
                        obj[`business:${id}`] = (
                            arr || []
                        )
                            .map(
                                (m) =>
                                    m?.url ||
                                    m?.image_url ||
                                    m?.media_url ||
                                    m?.path ||
                                    m?.fileUrl
                            )
                            .filter(Boolean);
                    });
                }

                if (mediaGroups.eventIds.length) {
                    const map =
                        await fetchForBusinessIds(
                            mediaGroups.eventIds,
                            'event'
                        );

                    map.forEach((arr, id) => {
                        obj[`event:${id}`] = (
                            arr || []
                        )
                            .map(
                                (m) =>
                                    m?.url ||
                                    m?.image_url ||
                                    m?.media_url ||
                                    m?.path ||
                                    m?.fileUrl
                            )
                            .filter(Boolean);
                    });
                }

                if (mounted) {
                    setMediaByUpdate(obj);
                }
            } catch (err) {
                console.error(err);

                if (mounted) {
                    setMediaByUpdate({});
                }
            }
        };

        loadMedia();

        return () => {
            mounted = false;
        };
    }, [mediaGroups, fetchForBusinessIds]);

    const handleApprove = async (
        row,
        comment = ''
    ) => {
        const id = Number(row?.id);

        if (!id) return;

        try {
            await approveOne(id, comment);

            toast.success(
                'Actualización aprobada correctamente ✔️'
            );

            setViewing(null);
        } catch (err) {
            console.error(err);

            toast.error(
                err?.message ||
                'No se pudo aprobar la actualización'
            );
        }
    };

    const handleReject = async (
        row,
        comment = ''
    ) => {
        const id = Number(row?.id);

        if (!id) return;

        try {
            await rejectOne(id, comment);

            toast.success(
                'Actualización rechazada'
            );

            setViewing(null);
        } catch (err) {
            console.error(err);

            toast.error(
                err?.message ||
                'No se pudo rechazar la actualización'
            );
        }
    };

    const emptyText = (() => {
        if (statusFilter === 'pending') {
            return 'No hay actualizaciones pendientes.';
        }

        if (statusFilter === 'approved') {
            return 'No hay actualizaciones aprobadas.';
        }

        if (statusFilter === 'rejected') {
            return 'No hay actualizaciones rechazadas.';
        }

        return 'No hay actualizaciones que coincidan con el filtro.';
    })();

    return (
        <section>
            <h2 className="text-2xl font-semibold text-slate-900 mb-1">
                Revisión de Actualizaciones
            </h2>

            <p className="text-slate-600 mb-4">
                Aprueba o rechaza cambios solicitados
                para negocios y eventos.
            </p>

            <div className="mb-3 flex flex-wrap gap-2">
                {TYPE_FILTERS.map((f) => {
                    const active =
                        typeFilter === f.id;

                    return (
                        <button
                            key={f.id}
                            type="button"
                            onClick={() =>
                                setTypeFilter(f.id)
                            }
                            className={`text-xs sm:text-sm inline-flex items-center px-3 py-1.5 rounded-full border transition font-medium ${active
                                    ? 'bg-white text-[#0077B6]'
                                    : 'bg-slate-50 text-slate-600 hover:bg-slate-100'
                                }`}
                            style={{
                                borderColor: active
                                    ? UI.primary
                                    : UI.border,
                            }}
                        >
                            {f.label}
                        </button>
                    );
                })}
            </div>

            <div className="mb-3 flex flex-wrap gap-2">
                {STATUS_FILTERS.map((f) => {
                    const active =
                        statusFilter === f.id;

                    return (
                        <button
                            key={f.id}
                            type="button"
                            onClick={() =>
                                setStatusFilter(f.id)
                            }
                            className={`text-xs sm:text-sm inline-flex items-center px-3 py-1.5 rounded-full border transition font-medium ${active
                                    ? 'bg-white text-[#0077B6]'
                                    : 'bg-slate-50 text-slate-600 hover:bg-slate-100'
                                }`}
                            style={{
                                borderColor: active
                                    ? UI.primary
                                    : UI.border,
                            }}
                        >
                            {f.label}
                        </button>
                    );
                })}
            </div>

            <div className="mb-4 flex items-center gap-2">
                <div className="relative flex-1 min-w-[260px]">
                    <FaSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />

                    <input
                        value={query}
                        onChange={(e) =>
                            setQuery(e.target.value)
                        }
                        className="w-full pl-10 pr-3 py-2 text-sm rounded-lg border bg-white outline-none
            text-slate-900 placeholder:text-slate-400/90
            focus:ring-2 focus:ring-[#0077B6]/30 focus:border-[#0077B6]"
                        style={{
                            borderColor: UI.border,
                        }}
                        placeholder="Buscar actualizaciones…"
                    />
                </div>

                <button
                    onClick={async () => {
                        try {
                            await fetchAll();

                            toast.success(
                                'Lista actualizada'
                            );
                        } catch (err) {
                            console.error(err);

                            toast.error(
                                'No se pudo recargar la lista'
                            );
                        }
                    }}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold border bg-[#EFF4FB] text-slate-800 hover:bg-[#E7EEF9] transition"
                    style={{
                        borderColor: UI.border,
                    }}
                    disabled={loading}
                >
                    <FaSyncAlt
                        className={`opacity-70 ${loading
                                ? 'animate-spin'
                                : ''
                            }`}
                    />
                    Recargar
                </button>
            </div>

            {loading &&
                (!updates ||
                    updates.length === 0) ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
                    {Array.from({
                        length: 6,
                    }).map((_, i) => (
                        <CardSkeleton key={i} />
                    ))}
                </div>
            ) : filtered.length ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
                    {filtered.map((row) => {
                        const mediaKey = `${row.entity_type}:${row.entity_id}`;

                        const imgs =
                            mediaByUpdate[
                            mediaKey
                            ] ?? [];

                        return (
                            <UpdateCard
                                key={row.id}
                                update={row}
                                currentEntity={getCurrentForUpdate(
                                    row
                                )}
                                imageUrl={imgs[0]}
                                imageCount={imgs.length}
                                onView={() =>
                                    setViewing({
                                        update: row,
                                        currentEntity:
                                            getCurrentForUpdate(
                                                row
                                            ),
                                        images: imgs,
                                    })
                                }
                            />
                        );
                    })}
                </div>
            ) : (
                <div className="p-6 border rounded-lg bg-white text-slate-500 text-center">
                    {emptyText}
                </div>
            )}

            {viewing && (
                <UpdateView
                    update={viewing.update}
                    currentEntity={
                        viewing.currentEntity
                    }
                    images={viewing.images}
                    savingId={savingId}
                    onClose={() =>
                        setViewing(null)
                    }
                    onApprove={handleApprove}
                    onReject={handleReject}
                />
            )}
        </section>
    );
}