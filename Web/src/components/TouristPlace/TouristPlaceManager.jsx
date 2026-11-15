// File: src/pages/tourist-places.jsx
'use client';

import { useEffect, useMemo, useState } from 'react';
import {
  FaPlus,
  FaTags,
  FaMapMarkedAlt,
  FaSearch,
  FaSyncAlt,
} from 'react-icons/fa';
import useTouristPlace from '@/hooks/useTouristPlace';
import useCategories from '@/hooks/useCategories';
import TouristPlaceForm from '@/components/TouristPlace/TouristPlaceForm';
import TouristPlaceCard from '@/components/TouristPlace/TouristPlaceCard';
import TouristPlaceFormEdit from '@/components/TouristPlace/TouristPlaceFormEdit';

import { uploadImages } from '@/services/storageService';
import mediaService from '@/services/mediaService';
import useMedia from '@/hooks/useMedia';

import useTag from '@/hooks/useTag';
import TagForm from '@/components/TouristPlace/TagForm';

import toast from 'react-hot-toast';

const UI = { primary: '#0077B6', soft: '#E9F3FF', border: '#E2E8F0' };

function ItemSkeleton() {
  return (
    <div
      className="border rounded-xl overflow-hidden bg-white"
      style={{ borderColor: UI.border }}
    >
      <div className="h-48 bg-slate-200 animate-pulse" />
      <div className="p-4 space-y-2">
        <div className="h-5 bg-slate-200 rounded w-1/2" />
        <div className="h-4 bg-slate-200 rounded w-1/3" />
      </div>
    </div>
  );
}

const isPlaceInactive = (p) => {
  return String(p?.status || '').toLowerCase() === 'inactive';
};

const computeNextStatus = (p) => {
  return isPlaceInactive(p) ? 'active' : 'inactive';
};

function getPlaceId(place) {
  return Number(place?.id ?? place?._id ?? place?.place_id);
}

export default function TouristPlaceManager() {
  const {
    items,
    loading,
    error,
    createOne,
    fetchAll,
    deleteOne,
    updateOne,
    fetchTagsByPlace,
    replaceTags,
  } = useTouristPlace({ autoLoad: true });

  const { fetchForBusinessIds } = useMedia();
  const [mediaByPlace, setMediaByPlace] = useState({});

  const {
    items: tags,
    loading: loadingTags,
    createOne: createTag,
    updateOne: updateTag,
    deleteOne: deleteTag,
    fetchAll: fetchTags,
  } = useTag({ autoLoad: true });

  const tagOptions = useMemo(
    () =>
      (tags || [])
        .filter((t) => String(t.status || '').toLowerCase() === 'active')
        .map((t) => ({ value: Number(t.id), label: t.name })),
    [tags]
  );

  const [tagsByPlace, setTagsByPlace] = useState({});

  const [isTagOpen, setIsTagOpen] = useState(false);
  const [editingTag, setEditingTag] = useState(null);
  const [tagSubmitting, setTagSubmitting] = useState(false);
  const [tagError, setTagError] = useState('');

  const openCreateTag = () => {
    setEditingTag(null);
    setIsTagOpen(true);
  };

  const openEditTag = (tag) => {
    setEditingTag(tag);
    setIsTagOpen(true);
  };

  const [isEditOpen, setIsEditOpen] = useState(false);
  const [editingPlace, setEditingPlace] = useState(null);
  const [editSubmitting, setEditSubmitting] = useState(false);
  const [editError, setEditError] = useState('');
  const [editFiles, setEditFiles] = useState([]);
  const [editSelectedTagIds, setEditSelectedTagIds] = useState([]);
  const [removedMediaIds, setRemovedMediaIds] = useState([]);

  const [viewPlace, setViewPlace] = useState(null);

  const { categories, loadingList: loadingCats } = useCategories();

  const categoryOptions = useMemo(
    () => (categories || []).map((c) => ({ value: c.id, label: c.name })),
    [categories]
  );

  const getCategoryName = (place) => {
    if (place?.category?.name) return place.category.name;

    const hit = categoryOptions.find(
      (o) => String(o.value) === String(place?.category_id)
    );

    return hit?.label ?? '—';
  };

  const placeIds = useMemo(
    () =>
      (items || [])
        .map((p) => getPlaceId(p))
        .filter((n) => Number.isFinite(n)),
    [items]
  );

  const reloadMedia = async (ids = placeIds) => {
    if (!ids.length) {
      setMediaByPlace({});
      return;
    }

    const map = await fetchForBusinessIds(ids, 'tourist_place');

    const obj = {};

    map.forEach((arr, id) => {
      const idStr = String(id);

      const mediaItems = (arr || [])
        .filter((m) => String(m?.entity_id ?? m?.target_id ?? m?.targetId) === idStr)
        .map((m) => ({
          id: m.id ?? m.media_id ?? m._id,
          url: m.url || m.image_url || m.media_url || m.path || m.fileUrl,
        }))
        .filter((m) => m.id && m.url);

      obj[idStr] = mediaItems;
    });

    setMediaByPlace(obj);
  };

  useEffect(() => {
    if (!placeIds.length) {
      setMediaByPlace({});
      return;
    }

    let mounted = true;

    (async () => {
      try {
        const map = await fetchForBusinessIds(placeIds, 'tourist_place');

        if (!mounted) return;

        const obj = {};

        map.forEach((arr, id) => {
          const idStr = String(id);

          const mediaItems = (arr || [])
            .filter(
              (m) =>
                String(m?.entity_id ?? m?.target_id ?? m?.targetId) === idStr
            )
            .map((m) => ({
              id: m.id ?? m.media_id ?? m._id,
              url: m.url || m.image_url || m.media_url || m.path || m.fileUrl,
            }))
            .filter((m) => m.id && m.url);

          obj[idStr] = mediaItems;
        });

        setMediaByPlace(obj);
      } catch (e) {
        console.error('ERROR CARGANDO MEDIA TOURIST PLACE:', e);
        setMediaByPlace({});
      }
    })();

    return () => {
      mounted = false;
    };
  }, [placeIds, fetchForBusinessIds]);

  useEffect(() => {
    if (!placeIds.length) {
      setTagsByPlace({});
      return;
    }

    let mounted = true;

    (async () => {
      const entries = await Promise.all(
        placeIds.map(async (pid) => {
          try {
            const rows = await fetchTagsByPlace(pid);

            const names = (rows || [])
              .map((r) => r?.tag?.name ?? r?.name ?? r?.tag_name)
              .filter(Boolean);

            const ids = (rows || [])
              .map((r) => Number(r?.tag_id ?? r?.id))
              .filter((n) => Number.isFinite(n));

            return [
              String(pid),
              {
                names,
                ids,
              },
            ];
          } catch {
            return [
              String(pid),
              {
                names: [],
                ids: [],
              },
            ];
          }
        })
      );

      if (!mounted) return;

      const obj = {};
      entries.forEach(([pid, value]) => {
        obj[pid] = value;
      });

      setTagsByPlace(obj);
    })();

    return () => {
      mounted = false;
    };
  }, [placeIds, fetchTagsByPlace]);

  const handleEdit = async (p) => {
    const id = getPlaceId(p);
    const mediaItems = mediaByPlace[String(id)] ?? [];
    const existingUrls = mediaItems.map((m) => m.url);

    let preIds = [];

    try {
      const rows = await fetchTagsByPlace(id);

      preIds = (rows || [])
        .map((r) => Number(r?.tag_id ?? r?.id))
        .filter((n) => Number.isFinite(n));
    } catch { }

    setEditingPlace({ ...p, existingUrls });
    setEditSelectedTagIds(preIds);
    setEditFiles([]);
    setEditError('');
    setRemovedMediaIds([]);
    setIsEditOpen(true);
  };

  const handleRemoveExistingUrl = (url) => {
    const placeId = Number(editingPlace?.id);
    const mediaItems = mediaByPlace[String(placeId)] ?? [];
    const match = mediaItems.find((m) => m.url === url);

    setEditingPlace((prev) => ({
      ...prev,
      existingUrls: (prev?.existingUrls || []).filter((x) => x !== url),
    }));

    if (match?.id) {
      setRemovedMediaIds((prev) => [...prev, match.id]);
    }
  };

  const handleToggleTagStatus = async (tag) => {
    const next =
      String(tag.status || '').toLowerCase() === 'active'
        ? 'inactive'
        : 'active';

    try {
      await updateTag(tag.id, { status: next });
      await fetchTags();
    } catch (e) {
      alert(e?.message || 'No se pudo actualizar el estado del tag');
      await fetchTags();
    }
  };

  const [isOpen, setIsOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState('');
  const [tpFiles, setTpFiles] = useState([]);
  const [selectedTagIds, setSelectedTagIds] = useState([]);

  const handleCreatePlace = async (payload) => {
    setSubmitting(true);
    setFormError('');

    try {
      const created = await createOne(payload, selectedTagIds);

      const placeId = Number(
        created?.id ?? created?.data?.id ?? created?.place?.id
      );

      if (!placeId || Number.isNaN(placeId)) {
        throw new Error('No se obtuvo el ID del lugar creado');
      }

      if (tpFiles?.length) {
        await uploadImages(tpFiles, {
          entityType: 'tourist_place',
          entityId: placeId,
        });
      }

      setTpFiles([]);
      setSelectedTagIds([]);

      await fetchAll();
      await reloadMedia([...placeIds, placeId]);

      setIsOpen(false);

      toast.success('Lugar turístico creado correctamente');
    } catch (e) {
      setFormError(e?.message || 'No se pudo crear el lugar turístico');
    } finally {
      setSubmitting(false);
    }
  };

  const handleView = (p) => {
    const id = getPlaceId(p);
    const mediaItems = mediaByPlace[String(id)] ?? [];
    const imgs = mediaItems.map((m) => m.url);
    const tagNames = tagsByPlace[String(id)]?.names ?? p.tags ?? [];

    setViewPlace({
      id,
      name: p.name,
      description: p.description,
      address: p.address,
      categoryName: getCategoryName(p),
      images: imgs,
      tags: tagNames,
    });
  };

  const handleSubmitEdit = async (payload) => {
    if (!editingPlace?.id) return;

    setEditSubmitting(true);
    setEditError('');

    try {
      const placeId = Number(editingPlace.id);

      const desiredIds = Array.from(
        new Set(
          (editSelectedTagIds || [])
            .map(Number)
            .filter((n) => Number.isFinite(n))
        )
      );

      await updateOne(placeId, payload, desiredIds);

      if (Array.isArray(editFiles) && editFiles.length) {
        await uploadImages(editFiles, {
          entityType: 'tourist_place',
          entityId: placeId,
        });
      }

      if (removedMediaIds.length > 0) {
        await Promise.all(
          removedMediaIds.map((mid) => mediaService.remove(mid))
        );
      }

      await fetchAll();
      await reloadMedia(placeIds);

      setIsEditOpen(false);
      setEditingPlace(null);
      setEditFiles([]);
      setRemovedMediaIds([]);

      toast.success('Lugar turístico actualizado');
    } catch (e) {
      setEditError(e?.message || 'No se pudo guardar los cambios');
    } finally {
      setEditSubmitting(false);
    }
  };

  const handleDelete = async (p) => {
    const ok = window.confirm(`¿Archivar "${p.name}"?`);

    if (!ok) return;

    try {
      await deleteOne(p.id);
      await fetchAll();
      toast.success('Lugar turístico archivado');
    } catch (e) {
      alert(e?.message || 'No se pudo archivar');
    }
  };

  const handlePauseToggle = async (p) => {
    const id = getPlaceId(p);

    try {
      const next = computeNextStatus(p);

      await updateOne(id, { status: next });

      await fetchAll();

      toast.success(next === 'active' ? 'Lugar activado' : 'Lugar pausado');
    } catch (e) {
      alert(e?.message || 'No se pudo actualizar el estado del lugar');
    }
  };

  const [view, setView] = useState('places');
  const [query, setQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  const filteredPlaces = useMemo(() => {
    const list = Array.isArray(items) ? items : [];

    const byStatus =
      statusFilter === 'all'
        ? list
        : list.filter((p) => {
          const s = String(p?.status || '').toLowerCase();

          if (statusFilter === 'active') return s === 'active';
          if (statusFilter === 'inactive') return s === 'inactive';

          return true;
        });

    const q = query.trim().toLowerCase();

    if (!q) return byStatus;

    return byStatus.filter((p) => {
      const id = getPlaceId(p);
      const tagsStr = (tagsByPlace[String(id)]?.names || []).join(' ');
      const catName = getCategoryName(p);

      return [p.name, p.description, p.address, catName, tagsStr]
        .filter(Boolean)
        .some((v) => String(v).toLowerCase().includes(q));
    });
  }, [items, query, statusFilter, tagsByPlace, categoryOptions]);

  const handleReload = async () => {
    try {
      await fetchAll();
      toast.success('Lista de lugares turísticos actualizada');
    } catch (e) {
      console.error(e);
      toast.error('No se pudo actualizar la lista');
    }
  };

  const handleSubmitTag = async (payload) => {
    setTagSubmitting(true);
    setTagError('');

    try {
      if (editingTag?.id) {
        await updateTag(editingTag.id, payload);
      } else {
        await createTag(payload);
      }

      await fetchTags();

      setIsTagOpen(false);
      setEditingTag(null);
    } catch (e) {
      setTagError(e?.message || 'No se pudo guardar el tag');
    } finally {
      setTagSubmitting(false);
    }
  };

  return (
    <div className="p-4 sm:p-0">
      <div
        className="bg-[#F8F9FA] shadow-md rounded-lg p-4 sm:p-6 border"
        style={{ borderColor: UI.border }}
      >
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <h1 className="text-2xl sm:text-3xl font-bold" style={{ color: UI.primary }}>
            Lugares turísticos
          </h1>

          <div className="flex flex-wrap items-center gap-2">
            <button
              onClick={() => setView('places')}
              className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold border transition
                ${view === 'places'
                  ? 'bg-white text-slate-900 border-[#0077B6]'
                  : 'bg-white text-slate-700 hover:bg-slate-50 border-slate-300'
                }`}
              title="Ver lugares"
            >
              <FaMapMarkedAlt
                className={view === 'places' ? 'text-[#0077B6]' : 'text-slate-500'}
              />
              Lugares
            </button>

            <button
              onClick={() => setView('tags')}
              className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold border transition
                ${view === 'tags'
                  ? 'bg-white text-slate-900 border-[#0077B6]'
                  : 'bg-white text-slate-700 hover:bg-slate-50 border-slate-300'
                }`}
              title="Ver tags"
            >
              <FaTags
                className={view === 'tags' ? 'text-[#0077B6]' : 'text-slate-500'}
              />
              Tags
            </button>

            {view === 'places' ? (
              <button
                onClick={() => setIsOpen(true)}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold text-white transition"
                style={{ background: UI.primary }}
              >
                <FaPlus />
                Añadir lugar turístico
              </button>
            ) : (
              <button
                onClick={openCreateTag}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold text-white transition"
                style={{ background: UI.primary }}
              >
                <FaPlus />
                Nuevo tag
              </button>
            )}
          </div>
        </div>

        {view === 'places' && (
          <div className="mt-4 flex flex-col md:flex-row gap-3 items-stretch md:items-center justify-between">
            <div className="flex-1 min-w-[220px]">
              <div className="relative">
                <FaSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                <input
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 text-sm rounded-lg border bg-white outline-none
                    text-slate-900 placeholder:text-slate-400/90
                    focus:ring-2 focus:ring-[#0077B6]/30 focus:border-[#0077B6]"
                  style={{ borderColor: UI.border }}
                  placeholder="Buscar por nombre, dirección, categoría o tag…"
                />
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-3 py-2 rounded-lg border bg-white text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0077B6]/30"
                style={{ borderColor: UI.border }}
              >
                <option value="all">Todos</option>
                <option value="active">Solo activos</option>
                <option value="inactive">Solo inactivos</option>
              </select>

              <button
                onClick={handleReload}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold border bg-[#EFF4FB] text-slate-800 hover:bg-[#E7EEF9] transition text-sm"
                style={{ borderColor: UI.border }}
                disabled={loading}
              >
                <FaSyncAlt className="opacity-70" />
                Recargar
              </button>
            </div>
          </div>
        )}

        {view === 'places' && (
          <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {loading
              ? Array.from({ length: 6 }).map((_, i) => <ItemSkeleton key={i} />)
              : filteredPlaces
                .slice()
                .sort((a, b) => {
                  const idA = getPlaceId(a) || 0;
                  const idB = getPlaceId(b) || 0;
                  return idB - idA;
                })
                .map((p) => {
                  const id = getPlaceId(p);
                  const mediaItems = mediaByPlace[String(id)] ?? [];
                  const imgs = mediaItems.map((m) => m.url);
                  const tagsForCard = tagsByPlace[String(id)]?.names ?? p.tags ?? [];
                  const isPaused = isPlaceInactive(p);

                  return (
                    <TouristPlaceCard
                      key={id}
                      place={p}
                      categoryName={getCategoryName(p)}
                      imageUrl={imgs[0]}
                      imageCount={imgs.length}
                      tags={tagsForCard}
                      onView={handleView}
                      onEdit={handleEdit}
                      onDelete={handleDelete}
                      onPause={() => handlePauseToggle(p)}
                      isPaused={isPaused}
                    />
                  );
                })}

            {!loading && filteredPlaces.length === 0 && (
              <div
                className="col-span-full text-center text-slate-600 bg-white border rounded-lg p-10"
                style={{ borderColor: UI.border }}
              >
                No hay lugares turísticos que coincidan con tu búsqueda / filtros.
              </div>
            )}
          </div>
        )}

        {view === 'tags' && (
          <div
            className="mt-6 overflow-x-auto bg-white border rounded-lg"
            style={{ borderColor: UI.border }}
          >
            <table className="min-w-full text-sm">
              <thead className="bg-slate-100">
                <tr className="text-slate-900">
                  <th className="text-left px-4 py-3 font-semibold">Nombre</th>
                  <th className="text-left px-4 py-3 font-semibold">Descripción</th>
                  <th className="text-left px-4 py-3 font-semibold">Estado</th>
                  <th className="text-right px-4 py-3 font-semibold">Acciones</th>
                </tr>
              </thead>

              <tbody className="text-slate-800">
                {loadingTags ? (
                  <tr>
                    <td className="px-4 py-4 text-slate-600" colSpan={4}>
                      Cargando…
                    </td>
                  </tr>
                ) : (tags || []).length ? (
                  tags.map((t, idx) => {
                    const isActive = String(t.status || '').toLowerCase() === 'active';

                    return (
                      <tr
                        key={t.id}
                        className={`border-t hover:bg-slate-50 ${idx % 2 ? 'bg-white' : 'bg-slate-50/40'
                          }`}
                        style={{ borderColor: UI.border }}
                      >
                        <td className="px-4 py-3 font-medium">{t.name}</td>
                        <td className="px-4 py-3">{t.description || '—'}</td>
                        <td className="px-4 py-3">
                          <span
                            className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold
                              ${isActive
                                ? 'bg-green-100 text-green-700'
                                : 'bg-amber-100 text-amber-700'
                              }`}
                          >
                            {isActive ? 'Activo' : 'Inactivo'}
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex justify-end gap-2">
                            <button
                              onClick={() => handleToggleTagStatus(t)}
                              className={`px-3 py-1 rounded border hover:bg-slate-100 ${isActive ? 'text-amber-700' : 'text-green-700'
                                }`}
                              style={{ borderColor: UI.border }}
                              title={isActive ? 'Pausar' : 'Reanudar'}
                            >
                              {isActive ? 'Pausar' : 'Reanudar'}
                            </button>

                            <button
                              onClick={() => openEditTag(t)}
                              className="px-3 py-1 rounded border text-slate-800 hover:bg-slate-100"
                              style={{ borderColor: UI.border }}
                            >
                              Editar
                            </button>

                            <button
                              onClick={async () => {
                                const ok = window.confirm(
                                  `¿Eliminar el tag "${t.name}"?`
                                );
                                if (!ok) return;

                                await deleteTag(t.id);
                                await fetchTags();
                              }}
                              className="px-3 py-1 rounded border text-rose-700 hover:bg-rose-50"
                              style={{ borderColor: UI.border }}
                            >
                              Eliminar
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                ) : (
                  <tr>
                    <td className="px-4 py-6 text-center text-slate-600" colSpan={4}>
                      Aún no hay tags registrados.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {isOpen && (
        <div className="fixed inset-0 z-50">
          <div className="absolute inset-0 bg-black/40" onClick={() => setIsOpen(false)} />
          <div className="absolute inset-0 grid place-items-center p-6">
            <div
              className="w-full max-w-4xl bg-white rounded-lg shadow-xl border"
              style={{ borderColor: UI.border }}
            >
              <div
                className="px-5 py-3 flex items-center justify-between rounded-t-lg"
                style={{
                  background: UI.soft,
                  borderBottom: `1px solid ${UI.border}`,
                }}
              >
                <h2 className="font-semibold text-slate-900">
                  Nuevo lugar turístico
                </h2>
                <button
                  onClick={() => setIsOpen(false)}
                  className="text-slate-700 hover:text-slate-900"
                >
                  ✕
                </button>
              </div>

              <div className="p-5">
                <TouristPlaceForm
                  categoryOptions={categoryOptions}
                  onSubmit={handleCreatePlace}
                  onCancel={() => setIsOpen(false)}
                  isSubmitting={submitting}
                  errorMsg={formError || (loadingCats ? 'Cargando categorías…' : '')}
                  files={tpFiles}
                  onFilesChange={setTpFiles}
                  tagOptions={tagOptions}
                  selectedTagIds={selectedTagIds}
                  onSelectedTagIdsChange={setSelectedTagIds}
                />
              </div>
            </div>
          </div>
        </div>
      )}

      {isTagOpen && (
        <div className="fixed inset-0 z-50">
          <div className="absolute inset-0 bg-black/40" onClick={() => setIsTagOpen(false)} />
          <div className="absolute inset-0 grid place-items-center p-6 text-black">
            <div
              className="w-full max-w-2xl bg-white rounded-lg shadow-xl border"
              style={{ borderColor: UI.border }}
            >
              <div className="px-5 py-3 flex items-center justify-between">
                <h2 className="font-semibold">
                  {editingTag ? 'Editar tag' : 'Nuevo tag'}
                </h2>
                <button onClick={() => setIsTagOpen(false)}>✕</button>
              </div>

              <div className="p-5">
                <TagForm
                  initialValue={editingTag || undefined}
                  onSubmit={handleSubmitTag}
                  onCancel={() => setIsTagOpen(false)}
                  isSubmitting={tagSubmitting}
                  errorMsg={tagError}
                />
              </div>
            </div>
          </div>
        </div>
      )}

      {isEditOpen && editingPlace && (
        <div className="fixed inset-0 z-50">
          <div className="absolute inset-0 bg-black/40" onClick={() => setIsEditOpen(false)} />

          <div className="absolute inset-0 grid place-items-center p-6">
            <div
              className="w-full max-w-4xl bg-white rounded-lg shadow-xl border"
              style={{ borderColor: UI.border }}
            >
              <div
                className="px-5 py-3 flex items-center justify-between rounded-t-lg"
                style={{
                  background: UI.soft,
                  borderBottom: `1px solid ${UI.border}`,
                }}
              >
                <h2 className="font-semibold text-slate-900">
                  Editar lugar turístico
                </h2>
                <button
                  onClick={() => setIsEditOpen(false)}
                  className="text-slate-700 hover:text-slate-900"
                >
                  ✕
                </button>
              </div>

              <div className="p-5">
                <TouristPlaceFormEdit
                  initialValue={{
                    id: editingPlace.id,
                    category_id: editingPlace.category_id,
                    name: editingPlace.name,
                    description: editingPlace.description,
                    address: editingPlace.address,
                    lat:
                      editingPlace?.location?.latitude ??
                      editingPlace?.lat ??
                      -17.3895,
                    lng:
                      editingPlace?.location?.longitude ??
                      editingPlace?.lng ??
                      -66.1568,
                  }}
                  categoryOptions={categoryOptions}
                  tagOptions={tagOptions}
                  initialSelectedTagIds={editSelectedTagIds}
                  onSelectedTagIdsChange={setEditSelectedTagIds}
                  existingImageUrls={editingPlace.existingUrls || []}
                  onRemoveExistingUrl={handleRemoveExistingUrl}
                  newFiles={editFiles}
                  onNewFilesChange={setEditFiles}
                  isSubmitting={editSubmitting}
                  errorMsg={editError}
                  onCancel={() => setIsEditOpen(false)}
                  onSubmit={handleSubmitEdit}
                />
              </div>
            </div>
          </div>
        </div>
      )}

      {viewPlace && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 sm:p-6">
          <div
            className="w-full max-w-4xl bg-white rounded-2xl shadow-2xl border flex flex-col max-h-[90vh] overflow-hidden"
            style={{ borderColor: UI.border }}
          >
            <div
              className="px-6 py-4 flex items-start justify-between border-b"
              style={{ background: UI.soft, borderColor: UI.border }}
            >
              <div className="space-y-1">
                <p className="text-[11px] uppercase tracking-[0.15em] text-slate-400 font-semibold">
                  Lugar turístico
                </p>
                <h2 className="font-semibold text-xl text-slate-900">
                  {viewPlace.name}
                </h2>
                {viewPlace.categoryName && (
                  <span
                    className="inline-flex items-center px-3 py-1 mt-1 rounded-full text-xs font-semibold bg-[#E0F4FF] text-[#0B63A1] border"
                    style={{ borderColor: UI.border }}
                  >
                    {viewPlace.categoryName}
                  </span>
                )}
              </div>

              <button
                onClick={() => setViewPlace(null)}
                className="inline-flex items-center justify-center w-9 h-9 rounded-full border text-slate-500 hover:text-slate-900 hover:bg-slate-50 transition"
                style={{ borderColor: UI.border }}
              >
                ✕
              </button>
            </div>

            <div className="flex-1 overflow-y-auto">
              <div className="p-5 sm:p-6 space-y-6">
                {Array.isArray(viewPlace.images) && viewPlace.images.length > 0 && (
                  <div className="space-y-3">
                    <div
                      className="w-full overflow-hidden rounded-xl border bg-slate-100"
                      style={{ borderColor: UI.border }}
                    >
                      <img
                        src={viewPlace.images[0]}
                        alt={viewPlace.name}
                        className="w-full h-56 sm:h-64 object-cover"
                      />
                    </div>

                    {viewPlace.images.length > 1 && (
                      <>
                        <p className="text-xs font-medium text-slate-600">
                          Galería ({viewPlace.images.length} imágenes)
                        </p>
                        <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
                          {viewPlace.images.slice(1).map((url, idx) => (
                            <img
                              key={idx}
                              src={url}
                              alt={`img-${idx + 1}`}
                              className="w-full h-20 sm:h-24 object-cover rounded-lg border hover:opacity-90 transition"
                              style={{ borderColor: UI.border }}
                            />
                          ))}
                        </div>
                      </>
                    )}
                  </div>
                )}

                <div className="grid gap-6 sm:grid-cols-2">
                  {viewPlace.address && (
                    <div className="space-y-1.5">
                      <p className="text-xs font-semibold tracking-wide text-slate-500 uppercase">
                        Dirección
                      </p>
                      <p className="text-sm text-slate-800 leading-relaxed">
                        {viewPlace.address}
                      </p>
                    </div>
                  )}

                  {Array.isArray(viewPlace.tags) && viewPlace.tags.length > 0 && (
                    <div className="space-y-1.5">
                      <p className="text-xs font-semibold tracking-wide text-slate-500 uppercase">
                        Tags
                      </p>
                      <div className="flex flex-wrap gap-2">
                        {viewPlace.tags.map((t, idx) => (
                          <span
                            key={`${t}-${idx}`}
                            className="px-3 py-1 rounded-full text-[11px] font-medium bg-[#E0F4FF] text-[#0B63A1] border"
                            style={{ borderColor: UI.border }}
                          >
                            {t}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                {viewPlace.description && (
                  <div className="space-y-1.5">
                    <p className="text-xs font-semibold tracking-wide text-slate-500 uppercase">
                      Descripción
                    </p>
                    <p className="text-sm text-slate-800 whitespace-pre-line leading-relaxed">
                      {viewPlace.description}
                    </p>
                  </div>
                )}
              </div>
            </div>

            <div
              className="px-5 sm:px-6 py-3 flex justify-end"
              style={{ borderTop: `1px solid ${UI.border}` }}
            >
              <button
                onClick={() => setViewPlace(null)}
                className="px-5 py-2 rounded-md font-semibold border bg-white text-slate-900 hover:bg-[#F2F4F7] text-sm transition"
                style={{ borderColor: UI.border }}
              >
                Cerrar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}