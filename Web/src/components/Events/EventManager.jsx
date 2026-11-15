// File: src/components/Events/EventManager.jsx
'use client';

import { useEffect, useMemo, useState } from 'react';
import {
    FaCalendarAlt,
    FaListUl,
    FaPlus,
    FaSearch,
    FaSyncAlt,
    FaTimes,
} from 'react-icons/fa';

import useEvents from '@/hooks/useEvents';
import useMedia from '@/hooks/useMedia';
import EventCard from '@/components/Events/EventCard';
import FormEvent from '@/components/Events/FormEvent';
import useCategories from '@/hooks/useCategories';
import { uploadImages } from '@/services/storageService';
import mediaService from '@/services/mediaService';
import useBusiness from '@/hooks/useBusiness';
import EventView from '@/components/Events/EventView';
import toast from 'react-hot-toast';

const UI = {
    primary: '#0077B6',
    border: '#E2E8F0',
    soft: '#F8FAFC',
};

const initialEventForm = {
    business_id: '',
    business_name: '',
    category_id: '',
    name: '',
    description: '',
    start_date: '',
    end_date: '',
    capacity: '',
    tinku_price: '',
    address: '',
    location: {
        latitude: -17.3895,
        longitude: -66.1568,
    },
    status: 'active',
};

function getEventId(ev) {
    return Number(ev?.id ?? ev?._id ?? ev?.event_id);
}

export default function EventManager() {
    const [view, setView] = useState('list');

    const { businesses } = useBusiness({ autoLoad: true });

    const {
        filteredRows,
        loading,
        error,
        search,
        setSearch,
        statusFilter = 'active',
        setStatusFilter,
        fetchAll,
        createOne,
        updateOne,
        removeOne,
    } = useEvents({ autoLoad: true });

    const { fetchForBusinessIds } = useMedia();
    const [mediaByEvent, setMediaByEvent] = useState({});

    const [isCreateOpen, setIsCreateOpen] = useState(false);
    const [createForm, setCreateForm] = useState(initialEventForm);
    const [createFiles, setCreateFiles] = useState([]);
    const [createError, setCreateError] = useState('');
    const [isSubmitting, setIsSubmitting] = useState(false);


    const [isEditOpen, setIsEditOpen] = useState(false);
    const [editingEventId, setEditingEventId] = useState(null);
    const [editForm, setEditForm] = useState(initialEventForm);
    const [editFiles, setEditFiles] = useState([]);
    const [editError, setEditError] = useState('');
    const [isEditSubmitting, setIsEditSubmitting] = useState(false);


    const [editExistingImages, setEditExistingImages] = useState([]);
    const [editOriginalImages, setEditOriginalImages] = useState([]);

    const [viewEvent, setViewEvent] = useState(null);

    const [currentMonth, setCurrentMonth] = useState(() => {
        const d = new Date();
        d.setHours(0, 0, 0, 0);
        return d;
    });

    const { categories, loadingList: loadingCategories } = useCategories();

    const eventCategoryOptions = useMemo(
        () =>
            (categories || [])
                .filter((c) => {
                    const status = String(c.status ?? 'active').toLowerCase();
                    return status === 'active' || status === '1' || status === 'true';
                })
                .map((c) => ({
                    value: c.id,
                    label: c.name,
                })),
        [categories]
    );

    const eventIds = useMemo(
        () =>
            (filteredRows || [])
                .map((ev) => getEventId(ev))
                .filter((n) => Number.isFinite(n)),
        [filteredRows]
    );

    const reloadMedia = async (ids = eventIds) => {
        if (!ids.length) {
            setMediaByEvent({});
            return;
        }

        const map = await fetchForBusinessIds(ids, 'event');

        const obj = {};

        map.forEach((arr, id) => {
            const idStr = String(id);

            const own = (arr || []).filter(
                (m) => String(m?.entity_id ?? m?.target_id ?? m?.targetId) === idStr
            );

            obj[idStr] = own
                .map((m) => ({
                    id: m.id ?? m.media_id ?? m._id,
                    url: m.url || m.image_url || m.media_url || m.path || m.fileUrl,
                }))
                .filter((m) => m.id && m.url);
        });

        setMediaByEvent(obj);
    };

    useEffect(() => {
        if (!eventIds.length) {
            setMediaByEvent({});
            return;
        }

        let mounted = true;

        (async () => {
            try {
                const map = await fetchForBusinessIds(eventIds, 'event');

                if (!mounted) return;

                const obj = {};

                map.forEach((arr, id) => {
                    const idStr = String(id);

                    const own = (arr || []).filter(
                        (m) =>
                            String(m?.entity_id ?? m?.target_id ?? m?.targetId) === idStr
                    );

                    obj[idStr] = own
                        .map((m) => ({
                            id: m.id ?? m.media_id ?? m._id,
                            url: m.url || m.image_url || m.media_url || m.path || m.fileUrl,
                        }))
                        .filter((m) => m.id && m.url);
                });

                setMediaByEvent(obj);
            } catch (e) {
                console.error('[EventManager] Error cargando media:', e);
                setMediaByEvent({});
            }
        })();

        return () => {
            mounted = false;
        };
    }, [eventIds, fetchForBusinessIds]);

    const visibleRows = useMemo(() => {
        const rows = filteredRows || [];

        if (statusFilter === 'active') {
            return rows.filter((ev) => ev.status === 'active');
        }

        if (statusFilter === 'pending') {
            return rows.filter((ev) => ev.status === 'pending');
        }

        if (statusFilter === 'finished') {
            return rows.filter((ev) => ev.status === 'finished');
        }
        if (statusFilter === 'cancelled') {
            return rows.filter((ev) => ev.status === 'cancelled');
        }

        return rows;
    }, [filteredRows, statusFilter]);

    const calendarDays = useMemo(() => {
        const startOfMonth = new Date(
            currentMonth.getFullYear(),
            currentMonth.getMonth(),
            1
        );

        startOfMonth.setHours(0, 0, 0, 0);

        const offset = (startOfMonth.getDay() + 6) % 7;
        const firstGridDay = new Date(startOfMonth);

        firstGridDay.setDate(firstGridDay.getDate() - offset);

        const days = [];

        for (let i = 0; i < 42; i++) {
            const d = new Date(firstGridDay);
            d.setDate(firstGridDay.getDate() + i);
            days.push(d);
        }

        return days;
    }, [currentMonth]);

    const eventsByDate = useMemo(() => {
        const map = {};

        (visibleRows || []).forEach((ev) => {
            const dateStr = ev.start_date || ev.end_date;

            if (!dateStr) return;

            const d = new Date(dateStr);

            if (Number.isNaN(d.getTime())) return;

            const key = d.toISOString().slice(0, 10);

            if (!map[key]) map[key] = [];

            map[key].push(ev);
        });

        return map;
    }, [visibleRows]);

    const monthLabel = useMemo(() => {
        return new Intl.DateTimeFormat('es-ES', {
            month: 'long',
            year: 'numeric',
        }).format(currentMonth);
    }, [currentMonth]);

    const goPrevMonth = () => {
        setCurrentMonth((prev) => {
            const d = new Date(prev.getFullYear(), prev.getMonth() - 1, 1);
            d.setHours(0, 0, 0, 0);
            return d;
        });
    };

    const goNextMonth = () => {
        setCurrentMonth((prev) => {
            const d = new Date(prev.getFullYear(), prev.getMonth() + 1, 1);
            d.setHours(0, 0, 0, 0);
            return d;
        });
    };

    const goToday = () => {
        const d = new Date();
        d.setHours(0, 0, 0, 0);
        setCurrentMonth(d);
    };

    const handleReloadEvents = async () => {
        try {
            await fetchAll();
            await reloadMedia();
            toast.success('Lista de eventos actualizada');
        } catch (e) {
            console.error(e);
            toast.error('No se pudo actualizar la lista de eventos');
        }
    };

    const handleOpenCreate = () => {
        setCreateForm(initialEventForm);
        setCreateFiles([]);
        setCreateError('');
        setIsCreateOpen(true);
    };

    const handleCloseCreate = () => {
        if (isSubmitting) return;

        setIsCreateOpen(false);
    };

    const handleCreateChange = (e) => {
        const { name, value } = e.target;

        setCreateForm((prev) => ({
            ...prev,
            [name]: value,
        }));
    };

    const handleCreateSubmit = async (e) => {
        e.preventDefault();

        setCreateError('');

        try {
            setIsSubmitting(true);

            const payload = {
                business_id: createForm.business_id
                    ? Number(createForm.business_id)
                    : null,
                category_id: Number(createForm.category_id),
                name: String(createForm.name || '').trim(),
                description: createForm.description?.trim() || null,
                start_date: new Date(createForm.start_date).toISOString(),
                end_date: new Date(createForm.end_date).toISOString(),
                capacity: createForm.capacity ? Number(createForm.capacity) : null,
                tinku_price: createForm.tinku_price
                    ? Number(createForm.tinku_price)
                    : 0,
                address: String(createForm.address || '').trim(),
                location: {
                    latitude: Number(createForm.location?.latitude),
                    longitude: Number(createForm.location?.longitude),
                },
            };

            const created = await createOne(payload);

            const eventId = Number(
                created?.id ?? created?.data?.id ?? created?.event?.id
            );

            if (!eventId) {
                throw new Error('No se obtuvo el ID del evento creado');
            }

            if (Array.isArray(createFiles) && createFiles.length) {
                await uploadImages(createFiles, {
                    entityType: 'event',
                    entityId: eventId,
                });
            }


            await fetchAll();
            await reloadMedia([...eventIds, eventId]);

            setIsCreateOpen(false);
            setCreateFiles([]);
            setCreateForm(initialEventForm);

            toast.success('Evento creado correctamente');
        } catch (error) {
            console.error('Error al crear evento', error);
            setCreateError(error?.message || 'Error al crear el evento.');
        } finally {
            setIsSubmitting(false);
        }
    };

    const handleEditEvent = (ev) => {
        if (ev.status === 'finished') {
            alert('Este evento ya está finalizado y no se puede editar.');
            return;
        }

        const id = getEventId(ev);

        const businessId = ev.business_id ?? ev.business?.id ?? '';

        let businessName = ev.business_name || ev.business?.name || '';

        if (!businessName && businessId && Array.isArray(businesses)) {
            const found = businesses.find(
                (b) =>
                    String(b.id) === String(businessId) ||
                    String(b.business_id) === String(businessId)
            );

            if (found) {
                businessName = found.name || found.business_name || '';
            }
        }

        const galleryMedia = mediaByEvent[String(id)] || [];
        const galleryUrls = galleryMedia.map((m) => m.url);

        setEditingEventId(id);

        setEditForm({
            business_id: businessId || '',
            business_name: businessName || '',
            category_id: ev.category_id ?? '',
            name: ev.name ?? '',
            description: ev.description ?? '',
            start_date: ev.start_date || '',
            end_date: ev.end_date || '',
            capacity: ev.capacity ?? '',
            tinku_price: ev.tinku_price ?? '',
            address: ev.address ?? '',
            location: {
                latitude:
                    ev?.location?.latitude ??
                    ev?.lat ??
                    -17.3895,
                longitude:
                    ev?.location?.longitude ??
                    ev?.lng ??
                    -66.1568,
            },
            status: ev.status ?? 'pending',
        });

        setEditFiles([]);
        setEditError('');

        setEditExistingImages(galleryUrls);
        setEditOriginalImages(galleryMedia);

        setIsEditOpen(true);
    };

    const handleEditChange = (e) => {
        const { name, value } = e.target;

        setEditForm((prev) => ({
            ...prev,
            [name]: value,
        }));
    };

    const handleCloseEdit = () => {
        if (isEditSubmitting) return;

        setIsEditOpen(false);
        setEditFiles([]);
        setEditExistingImages([]);
        setEditOriginalImages([]);
    };

    const handleEditSubmit = async (e) => {
        e.preventDefault();

        setEditError('');

        const id = Number(editingEventId);

        if (!id || Number.isNaN(id)) {
            setEditError('ID de evento inválido.');
            return;
        }

        try {
            setIsEditSubmitting(true);

            const payload = {
                name: String(editForm.name || '').trim(),
                description: editForm.description?.trim() || null,
                category_id: Number(editForm.category_id),
                start_date: new Date(editForm.start_date).toISOString(),
                end_date: new Date(editForm.end_date).toISOString(),
                capacity: editForm.capacity ? Number(editForm.capacity) : null,
                tinku_price: editForm.tinku_price
                    ? Number(editForm.tinku_price)
                    : 0,
                address: String(editForm.address || '').trim(),
                location: {
                    latitude: Number(editForm.location?.latitude),
                    longitude: Number(editForm.location?.longitude),
                },
            };

            await updateOne(id, payload);

            const removed = (editOriginalImages || []).filter(
                (item) => !editExistingImages.includes(item.url)
            );

            if (removed.length) {
                await Promise.all(
                    removed
                        .filter((r) => r.id)
                        .map((r) => mediaService.remove(r.id))
                );
            }

            if (Array.isArray(editFiles) && editFiles.length) {
                await uploadImages(editFiles, {
                    entityType: 'event',
                    entityId: id,
                });
            }


            await fetchAll();
            await reloadMedia(eventIds);

            setIsEditOpen(false);
            setEditFiles([]);
            setEditOriginalImages([]);
            setEditExistingImages([]);

            toast.success('Evento actualizado');
        } catch (err) {
            console.error('Error al actualizar evento', err);
            setEditError(err?.message || 'Error al actualizar el evento.');
        } finally {
            setIsEditSubmitting(false);
        }
    };

    const handleFinishEvent = async (ev) => {
        const id = getEventId(ev);

        if (!id) return;

        if (ev.status === 'finished') {
            alert('Este evento ya está finalizado.');
            return;
        }

        const ok = window.confirm(
            `¿Finalizar el evento "${ev.name}"?\n\nUna vez finalizado, el evento no se podrá editar ni eliminar.`
        );

        if (!ok) return;

        try {
            await updateOne(id, { status: 'finished' });
            await fetchAll();
            toast.success('Evento finalizado');
        } catch (e) {
            console.error('Error al finalizar evento', e);
            alert(e?.message || 'No se pudo finalizar el evento');
        }
    };

    const handleDeleteEvent = async (ev) => {
        const id = getEventId(ev);

        if (!id) return;

        if (ev.status !== 'active') {
            alert('Solo los eventos activos pueden eliminarse.');
            return;
        }

        const ok = window.confirm(
            `¿Eliminar el evento "${ev.name}"?\n\nEsta acción es permanente y no se puede deshacer.`
        );

        if (!ok) return;

        try {
            await removeOne(id);

            await fetchAll();

            toast.success('Evento eliminado');
        } catch (e) {
            console.error('Error al eliminar evento', e);

            alert(e?.message || 'No se pudo eliminar el evento');
        }
    };

    const handleViewEvent = (ev) => {
        const id = getEventId(ev);
        const imgs = (mediaByEvent[String(id)] || []).map((m) => m.url);

        setViewEvent({
            ...ev,
            images: imgs,
        });
    };

    return (
        <div className="p-0">
            <div
                className="bg-white rounded-xl shadow-md border p-5 space-y-4"
                style={{ borderColor: UI.border }}
            >
                <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
                    <div>
                        <h1
                            className="text-3xl font-bold"
                            style={{ color: UI.primary }}
                        >
                            Gestión de eventos
                        </h1>

                        <p className="text-sm text-slate-600">
                            Administra los eventos registrados en la plataforma.
                        </p>
                    </div>

                    <div className="flex flex-wrap gap-2 items-center">
                        <div
                            className="inline-flex rounded-lg border bg-slate-50 overflow-hidden"
                            style={{ borderColor: UI.border }}
                        >
                            <button
                                type="button"
                                onClick={() => setView('list')}
                                className={`px-3 py-1.5 text-sm font-medium flex items-center gap-1 ${view === 'list'
                                    ? 'bg-white text-slate-900 shadow-sm'
                                    : 'text-slate-600 hover:bg-slate-100'
                                    }`}
                            >
                                <FaListUl /> Lista
                            </button>

                            <button
                                type="button"
                                onClick={() => setView('calendar')}
                                className={`px-3 py-1.5 text-sm font-medium flex items-center gap-1 ${view === 'calendar'
                                    ? 'bg-white text-slate-900 shadow-sm'
                                    : 'text-slate-600 hover:bg-slate-100'
                                    }`}
                            >
                                <FaCalendarAlt /> Calendario
                            </button>
                        </div>

                        <button
                            type="button"
                            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg text-white font-semibold"
                            style={{ background: UI.primary }}
                            onClick={handleOpenCreate}
                        >
                            <FaPlus />
                            Nuevo evento
                        </button>
                    </div>
                </div>

                <div className="flex flex-wrap items-center gap-3 justify-between">
                    <div className="flex-1 min-w-[260px] max-w-2xl">
                        <div className="relative">
                            <FaSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />

                            <input
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                                className="w-full pl-10 pr-3 py-2 text-sm rounded-lg border bg-white outline-none
                  text-slate-900 placeholder:text-slate-400/90
                  focus:ring-2 focus:ring-[#0077B6]/30 focus:border-[#0077B6]"
                                style={{ borderColor: UI.border, boxShadow: 'none' }}
                                placeholder="Buscar por nombre, descripción o dirección…"
                                aria-label="Buscar eventos"
                            />
                        </div>
                    </div>

                    <select
                        value={statusFilter}
                        onChange={(e) => setStatusFilter(e.target.value)}
                        className="px-3 py-2 rounded-lg border bg-white text-sm text-slate-700"
                        style={{ borderColor: UI.border }}
                    >
                        <option value="all">Todos</option>
                        <option value="active">Activos</option>
                        <option value="pending">Pendientes</option>
                        <option value="finished">Finalizados</option>
                        <option value="cancelled">Cancelados</option>
                    </select>

                    <button
                        onClick={handleReloadEvents}
                        className="inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold border bg-[#EFF4FB] text-slate-800 hover:bg-[#E7EEF9] transition text-sm"
                        style={{ borderColor: UI.border }}
                        disabled={loading}
                    >
                        <FaSyncAlt
                            className={loading ? 'animate-spin opacity-70' : 'opacity-70'}
                        />
                        Recargar
                    </button>
                </div>

                {error && (
                    <div className="px-3 py-2 rounded-md bg-red-50 text-red-700 border border-red-200 text-sm">
                        {error?.message || 'Error al cargar eventos'}
                    </div>
                )}

                {view === 'list' ? (
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5 mt-4">
                        {loading && visibleRows.length === 0 ? (
                            <p className="text-sm text-slate-500 col-span-full">
                                Cargando…
                            </p>
                        ) : visibleRows.length === 0 ? (
                            <div className="col-span-full text-center text-slate-500 text-sm py-6">
                                Aún no hay eventos que coincidan con tu búsqueda.
                            </div>
                        ) : (
                            visibleRows.map((ev) => {
                                const id = getEventId(ev);
                                const media = mediaByEvent[String(id)] ?? [];
                                const imgs = media.map((m) => m.url);

                                return (
                                    <EventCard
                                        key={id}
                                        event={ev}
                                        imageUrl={imgs[0]}
                                        imageCount={imgs.length}
                                        onView={handleViewEvent}
                                        onEdit={handleEditEvent}
                                        onFinish={handleFinishEvent}
                                        onDelete={handleDeleteEvent}
                                    />
                                );
                            })
                        )}
                    </div>
                ) : (
                    <div className="mt-4 border rounded-lg bg-white overflow-hidden">
                        <div
                            className="flex items-center justify-between px-4 py-2 border-b"
                            style={{ background: '#E2F1FB', borderColor: '#B0D4EC' }}
                        >
                            <div className="flex items-center gap-2">
                                <button
                                    type="button"
                                    onClick={goPrevMonth}
                                    className="px-2 py-1 text-sm rounded-md font-semibold text-slate-700"
                                    style={{
                                        background: 'white',
                                        border: '1px solid #B0D4EC',
                                    }}
                                >
                                    ←
                                </button>

                                <button
                                    type="button"
                                    onClick={goNextMonth}
                                    className="px-2 py-1 text-sm rounded-md font-semibold text-slate-700"
                                    style={{
                                        background: 'white',
                                        border: '1px solid #B0D4EC',
                                    }}
                                >
                                    →
                                </button>

                                <button
                                    type="button"
                                    onClick={goToday}
                                    className="px-3 py-1 text-xs rounded-md font-semibold"
                                    style={{
                                        background: '#0077B6',
                                        color: 'white',
                                        border: '1px solid #00588A',
                                    }}
                                >
                                    Hoy
                                </button>
                            </div>

                            <div
                                className="font-semibold text-lg capitalize tracking-wide"
                                style={{ color: '#00588A' }}
                            >
                                {monthLabel}
                            </div>
                        </div>

                        <div className="grid grid-cols-7 text-xs text-slate-500 bg-slate-50 border-b">
                            {['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'].map((d) => (
                                <div
                                    key={d}
                                    className="px-2 py-1 text-center font-semibold uppercase tracking-wide"
                                >
                                    {d}
                                </div>
                            ))}
                        </div>

                        <div className="grid grid-cols-7 text-xs">
                            {calendarDays.map((day, idx) => {
                                const dateKey = day.toISOString().slice(0, 10);
                                const events = eventsByDate[dateKey] || [];

                                const isCurrentMonth =
                                    day.getMonth() === currentMonth.getMonth() &&
                                    day.getFullYear() === currentMonth.getFullYear();

                                const today = new Date();
                                today.setHours(0, 0, 0, 0);

                                const isToday = day.getTime() === today.getTime();

                                return (
                                    <div
                                        key={`${dateKey}-${idx}`}
                                        className={`min-h-[90px] border border-slate-100 px-1.5 py-1.5 flex flex-col gap-1 ${isCurrentMonth ? 'bg-white' : 'bg-slate-50/60'
                                            }`}
                                    >
                                        <div className="flex items-center justify-between">
                                            <span
                                                className={`text-[11px] font-semibold ${isToday
                                                    ? 'inline-flex items-center justify-center w-5 h-5 rounded-full text-white'
                                                    : 'text-slate-700'
                                                    }`}
                                                style={
                                                    isToday
                                                        ? { backgroundColor: UI.primary }
                                                        : undefined
                                                }
                                            >
                                                {day.getDate()}
                                            </span>
                                        </div>

                                        <div className="space-y-1 mt-1">
                                            {events.map((ev) => {
                                                const id = getEventId(ev);
                                                const media = mediaByEvent[String(id)] ?? [];
                                                const imageUrl = media[0]?.url;

                                                return (
                                                    <button
                                                        key={id}
                                                        type="button"
                                                        onClick={() => handleViewEvent(ev)}
                                                        className="relative w-full h-12 rounded-md overflow-hidden text-white text-[11px] flex items-end px-2 py-1"
                                                        title={ev.name}
                                                    >
                                                        {imageUrl && (
                                                            <img
                                                                src={imageUrl}
                                                                alt={ev.name}
                                                                className="absolute inset-0 w-full h-full object-cover"
                                                            />
                                                        )}

                                                        <div className="absolute inset-0 bg-black/40" />

                                                        <span className="relative truncate font-medium">
                                                            {ev.name}
                                                        </span>
                                                    </button>
                                                );
                                            })}
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                )}
            </div>

            {isCreateOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
                    <div className="bg-white rounded-xl shadow-xl max-w-4xl w-full mx-4 p-6 flex flex-col max-h-[90vh]">
                        <div className="flex items-center justify-between mb-4">
                            <div>
                                <h2 className="text-lg font-semibold text-slate-900">
                                    Nuevo evento
                                </h2>
                                <p className="text-xs text-slate-500">
                                    Completa la información del evento y guarda para registrarlo.
                                </p>
                            </div>

                            <button
                                type="button"
                                onClick={handleCloseCreate}
                                className="p-2 rounded-full hover:bg-slate-100 text-slate-500"
                                disabled={isSubmitting}
                            >
                                <FaTimes />
                            </button>
                        </div>

                        <FormEvent
                            formData={createForm}
                            isSubmitting={isSubmitting || loadingCategories}
                            errorMsg={createError}
                            onChange={handleCreateChange}
                            onSubmit={handleCreateSubmit}
                            onCancel={handleCloseCreate}
                            categoryOptions={eventCategoryOptions}
                            files={createFiles}
                            onFilesChange={setCreateFiles}
                            showStatus={false}
                            existingImageUrls={[]}
                            onExistingImageUrlsChange={() => { }}
                        />
                    </div>
                </div>
            )}

            {isEditOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
                    <div className="bg-white rounded-xl shadow-xl max-w-4xl w-full mx-4 p-6 flex flex-col max-h-[90vh]">
                        <div className="flex items-center justify-between mb-4">
                            <div>
                                <h2 className="text-lg font-semibold text-slate-900">
                                    Editar evento
                                </h2>

                                <p className="text-xs text-slate-500">
                                    Actualiza la información del evento.
                                </p>
                            </div>

                            <button
                                type="button"
                                onClick={handleCloseEdit}
                                className="p-2 rounded-full hover:bg-slate-100 text-slate-500"
                                disabled={isEditSubmitting}
                            >
                                <FaTimes />
                            </button>
                        </div>

                        <FormEvent
                            formData={editForm}
                            isSubmitting={isEditSubmitting || loadingCategories}
                            errorMsg={editError}
                            onChange={handleEditChange}
                            onSubmit={handleEditSubmit}
                            onCancel={handleCloseEdit}
                            categoryOptions={eventCategoryOptions}
                            files={editFiles}
                            onFilesChange={setEditFiles}
                            showStatus={true}
                            existingImageUrls={editExistingImages}
                            onExistingImageUrlsChange={setEditExistingImages}
                        />
                    </div>
                </div>
            )}

            {viewEvent && (
                <EventView
                    event={viewEvent}
                    onClose={() => setViewEvent(null)}
                />
            )}
        </div>
    );
}