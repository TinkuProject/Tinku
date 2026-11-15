// src/pages/negocios.jsx
'use client';

import { useEffect, useMemo, useState } from 'react';
import { FaSearch, FaSyncAlt, FaPlus } from 'react-icons/fa';
import useBusiness from '@/hooks/useBusiness';
import BusinessForm from '@/components/Business/FormBussines';
import FormBusinessEdit from '@/components/Business/FormBusinessEdit';
import BusinessCard from '@/components/Business/BusinessCard';
import { useUser } from '@/context/UserContext';
import useCategories from '@/hooks/useCategories';
import { uploadImages } from '@/services/storageService';
import mediaService from '@/services/mediaService';
import useMedia from '@/hooks/useMedia';
import BusinessView from '@/components/Business/BusinessView';
import toast from 'react-hot-toast';

const UI = {
  primary: '#0077B6',
  soft: '#E9F3FF',
  border: '#E2E8F0',
};

function CardSkeleton() {
  return (
    <div
      className="bg-white border rounded-xl shadow-sm overflow-hidden animate-pulse"
      style={{ borderColor: UI.border }}
    >
      <div className="h-48 bg-slate-200" />
      <div className="p-4 space-y-2">
        <div className="h-5 bg-slate-200 rounded" />
        <div className="h-4 bg-slate-200 rounded w-1/2" />
        <div className="h-4 bg-slate-200 rounded w-3/4" />
        <div className="h-9 bg-slate-200 rounded mt-3" />
      </div>
    </div>
  );
}

function getBusinessId(biz) {
  return Number(biz?.id ?? biz?._id ?? biz?.business_id);
}

function getOwnerId(biz) {
  return (
    biz?.owner_id ??
    biz?.user_id ??
    biz?.userId ??
    biz?.id_user ??
    biz?.ownerId ??
    biz?.owner?.id ??
    biz?.owner?.user_id ??
    null
  );
}

function isOwnedByCurrentUser(biz, userId) {
  const ownerId = getOwnerId(biz);
  return ownerId != null && userId != null && String(ownerId) === String(userId);
}

function normalizeStatus(status) {
  const value = String(status || '').toLowerCase();

  if (value === 'active') return 'active';
  if (value === 'pending') return 'pending';
  if (value === 'inactive') return 'inactive';

  return 'pending';
}

function emptyForm() {
  return {
    category_id: '',
    name: '',
    nit: '',
    description: '',
    phone: '',
    email: '',
    business_type: 'business',
    address: '',
    location: {
      latitude: -17.3895,
      longitude: -66.1568,
    },
    website: '',
  };
}

export default function BusinessPage() {
  const { user, loading: userLoading } = useUser();

  const [token, setToken] = useState(null);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      setToken(localStorage.getItem('token'));
    }
  }, [user]);

  const userId =
    user?.id ??
    user?.idUser ??
    user?.id_user ??
    user?.user_id ??
    user?.uid ??
    null;

  const role = String(
    user?.role ?? user?.rol ?? user?.roleName ?? user?.user_type ?? ''
  )
    .trim()
    .toLowerCase();

  const {
    createOne,
    createSystemOne,
    fetchAll,
    fetchMine,
    deleteOne,
    businesses,
    loading,
    error,
  } = useBusiness({
    autoLoad: false,
    token,
  });

  const { categories, loadingList: loadingCats } = useCategories();

  const categoryOptions = useMemo(
    () => (categories || []).map((c) => ({ value: c.id, label: c.name })),
    [categories]
  );

  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isCreateSubmitting, setIsCreateSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [query, setQuery] = useState('');
  const [files, setFiles] = useState([]);
  const [viewing, setViewing] = useState(null);

  const [isEditOpen, setIsEditOpen] = useState(false);
  const [editingBizId, setEditingBizId] = useState(null);

  const { fetchForBusinessIds } = useMedia();
  const [mediaByBusiness, setMediaByBusiness] = useState({});

  const [statusFilter, setStatusFilter] = useState('all');
  const [formData, setFormData] = useState(emptyForm());

  const isAdminLike = ['admin', 'master'].includes(role);
  const isPartnerLike = ['partner', 'socio'].includes(role);

  const loadBusinesses = async () => {
    if (isPartnerLike && token) {
      return fetchMine();
    }

    return fetchAll();
  };

  useEffect(() => {
    if (userLoading) return;
    if (!token && userId) return;

    loadBusinesses().catch((e) => {
      console.error(e);
      toast.error('No se pudo cargar la lista de negocios');
    });

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userLoading, role, token, userId]);

  const handleReload = async () => {
    try {
      await loadBusinesses();
      toast.success('Lista de negocios actualizada');
    } catch (e) {
      console.error(e);
      toast.error('No se pudo actualizar la lista');
    }
  };

  const onChange = (e) => {
    const { name, value } = e.target;

    setFormData((f) => ({
      ...f,
      [name]: value,
    }));
  };

  const resetCreateForm = () => {
    setFormData(emptyForm());
    setFiles([]);
    setErrorMsg('');
  };

  const onCreateSubmit = async (e) => {
    e.preventDefault();

    if (!userId) {
      setErrorMsg('No hay usuario autenticado.');
      return;
    }

    if (!token) {
      setErrorMsg('No token provided');
      return;
    }

    if (!formData.category_id) {
      setErrorMsg('Selecciona una categoría.');
      return;
    }

    const latitude = Number(formData.location?.latitude);
    const longitude = Number(formData.location?.longitude);

    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      setErrorMsg('Selecciona una ubicación válida en el mapa.');
      return;
    }

    setIsCreateSubmitting(true);
    setErrorMsg('');

    try {
      const optionalText = (value) => {
        const v = String(value || '').trim();
        return v === '' ? undefined : v;
      };

      const optionalUrl = (value) => {
        const v = String(value || '').trim();
        if (v === '') return undefined;
        if (/^https?:\/\//i.test(v)) return v;
        return `https://${v}`;
      };

      const payload = {
        category_id: Number(formData.category_id),
        name: String(formData.name || '').trim(),
        business_type: formData.business_type,
        address: String(formData.address || '').trim(),
        location: {
          latitude,
          longitude,
        },
      };

      const optionalFields = {
        nit: optionalText(formData.nit),
        description: optionalText(formData.description),
        phone: optionalText(formData.phone),
        email: optionalText(formData.email),
        website: optionalUrl(formData.website),
      };

      Object.entries(optionalFields).forEach(([key, value]) => {
        if (value !== undefined) {
          payload[key] = value;
        }
      });

      const created = isAdminLike
        ? await createSystemOne(payload)
        : await createOne(payload);

      const businessIdRaw =
        created?.id ?? created?.data?.id ?? created?.business?.id;

      const businessId = Number(businessIdRaw);

      if (!businessId || Number.isNaN(businessId)) {
        throw new Error('No se obtuvo el ID del negocio creado');
      }

      let urls = [];

      if (files?.length) {
        urls = await uploadImages(files, {
          entityType: 'business',
          entityId: businessId,
        });

        console.log('UPLOADED URLS:', urls);
      }


      resetCreateForm();
      await loadBusinesses();
      setIsCreateOpen(false);

      toast.success(
        isAdminLike
          ? 'Negocio creado correctamente'
          : 'Negocio creado, pendiente de validación'
      );
    } catch (err) {
      console.error(err);
      setErrorMsg(err?.data?.error || err?.details?.error || err?.message || 'Error al crear');
    } finally {
      setIsCreateSubmitting(false);
    }
  };

  const filtered = useMemo(() => {
    const list = Array.isArray(businesses) ? businesses : [];

    let base = list;

    if (!isAdminLike && userId) {
      base = list.filter((b) => isOwnedByCurrentUser(b, userId));
    }

    const byStatus = base.filter((b) => {
      const status = normalizeStatus(b?.status);

      if (statusFilter === 'active') return status === 'active';
      if (statusFilter === 'pending') return status === 'pending';
      if (statusFilter === 'inactive') return status === 'inactive';

      return true;
    });

    const q = query.trim().toLowerCase();

    const searched = !q
      ? byStatus
      : byStatus.filter((b) =>
        [
          b.name,
          b.description,
          b.address,
          b.business_type,
          b.status,
          b.category?.name,
          b.category_name,
        ]
          .filter(Boolean)
          .some((v) => String(v).toLowerCase().includes(q))
      );

    return [...searched].sort((a, b) => {
      const dateA = new Date(
        a.created_at || a.createdAt || a.created || 0
      ).getTime();

      const dateB = new Date(
        b.created_at || b.createdAt || b.created || 0
      ).getTime();

      if (dateA && dateB && dateA !== dateB) {
        return dateB - dateA;
      }

      const idA = Number(a.id ?? a.business_id ?? a._id ?? 0);
      const idB = Number(b.id ?? b.business_id ?? b._id ?? 0);

      return idB - idA;
    });
  }, [businesses, isAdminLike, userId, query, statusFilter]);

  const filteredIds = useMemo(
    () =>
      filtered
        .map((b) => getBusinessId(b))
        .filter((id) => id !== undefined && id !== null)
        .filter((n) => !Number.isNaN(n)),
    [filtered]
  );

  useEffect(() => {
    if (!filteredIds.length) {
      setMediaByBusiness({});
      return;
    }

    let mounted = true;

    (async () => {
      const map = await fetchForBusinessIds(filteredIds, 'business');

      if (!mounted) return;

      const obj = {};

      map.forEach((arr, id) => {
        const idStr = String(id);

        const own = (arr || []).filter(
          (m) =>
            String(m?.entity_id ?? m?.target_id ?? m?.targetId) === idStr
        );

        obj[idStr] = own.map((m) => m?.url).filter(Boolean);
      });

      setMediaByBusiness(obj);
    })();

    return () => {
      mounted = false;
    };
  }, [filteredIds, fetchForBusinessIds]);

  const getCategoryName = (b) => {
    if (b.category?.name) return b.category.name;

    const hit = categoryOptions.find(
      (opt) => String(opt.value) === String(b.category_id)
    );

    return hit?.label ?? '—';
  };

  const handleOpenEdit = (biz) => {
    const id = getBusinessId(biz);

    if (!id || Number.isNaN(id)) {
      toast.error('ID de negocio inválido');
      return;
    }

    setEditingBizId(id);
    setIsEditOpen(true);
  };

  const handleCloseEdit = () => {
    setIsEditOpen(false);
    setEditingBizId(null);
  };

  const handleDeleteBiz = async (biz) => {
    const id = getBusinessId(biz);

    const ok = window.confirm(
      `¿Eliminar "${biz?.name}"? El negocio pasará a estado inactivo.`
    );

    if (!ok) return;

    try {
      await deleteOne(id);
      await loadBusinesses();
      toast.success('Negocio eliminado');
    } catch (e) {
      toast.error(e?.message || 'No se pudo eliminar el negocio');
    }
  };

  const canEdit = () => {
    return isAdminLike;
  };

  const canDelete = (biz) => {
    if (isAdminLike) return true;
    return isOwnedByCurrentUser(biz, userId);
  };

  return (
    <div className="p-0">
      <div
        className="bg-[#F8F9FA] shadow-md rounded-lg p-10 border"
        style={{ borderColor: UI.border }}
      >
        <h1 className="text-3xl font-bold mb-2" style={{ color: UI.primary }}>
          Gestión de Negocios
        </h1>

        <p className="text-sm text-slate-600 mb-6">
          Rol: <b>{role || '(desconocido)'}</b> · Total:{' '}
          {businesses?.length ?? 0} · Mostrando: {filtered.length}
        </p>

        <div className="mb-6 flex flex-wrap items-center gap-3 justify-between">
          <div className="flex-1 min-w-[260px] max-w-2xl">
            <div className="relative">
              <FaSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />

              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                className="w-full pl-10 pr-3 py-2 text-sm rounded-lg border bg-white outline-none
                  text-slate-900 placeholder:text-slate-400/90
                  focus:ring-2 focus:ring-[#0077B6]/30 focus:border-[#0077B6]"
                style={{ borderColor: UI.border, boxShadow: 'none' }}
                placeholder="Buscar por nombre, dirección, categoría, tipo o estado…"
                aria-label="Buscar negocios"
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
            <option value="pending">Pendientes</option>
            <option value="active">Activos</option>
            <option value="inactive">Inactivos</option>
          </select>

          <div className="flex items-center gap-2">
            <button
              onClick={handleReload}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold border bg-[#EFF4FB] text-slate-800 hover:bg-[#E7EEF9] transition"
              style={{ borderColor: UI.border }}
              disabled={loading}
            >
              <FaSyncAlt className="opacity-70" />
              Recargar
            </button>

            <button
              onClick={() => setIsCreateOpen(true)}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold text-white disabled:opacity-60 transition"
              style={{ background: UI.primary }}
              disabled={userLoading || !userId || !token}
            >
              <FaPlus />
              Añadir negocio
            </button>
          </div>
        </div>

        {error && (
          <div
            className="mb-4 bg-red-50 border text-red-700 rounded-lg p-3 text-sm"
            style={{ borderColor: '#FCA5A5' }}
          >
            {error.message || 'Ocurrió un error al cargar negocios'}
          </div>
        )}

        {loading && (!businesses || businesses.length === 0) ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {Array.from({ length: 6 }).map((_, i) => (
              <CardSkeleton key={i} />
            ))}
          </div>
        ) : filtered.length > 0 ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {filtered.map((b, i) => {
              const id = getBusinessId(b);
              const imgs = mediaByBusiness[String(id)] ?? [];
              const status = normalizeStatus(b?.status);
              const isPaused = status === 'inactive';

              return (
                <BusinessCard
                  key={id || i}
                  business={b}
                  categoryName={getCategoryName(b)}
                  onViewDetails={() => {
                    const imgsFor = mediaByBusiness[String(id)] ?? [];

                    setViewing({
                      business: b,
                      images: imgsFor,
                      nearbyPlaces: [],
                    });
                  }}
                  onEdit={canEdit(b) ? () => handleOpenEdit(b) : undefined}
                  onPause={undefined}
                  onDelete={canDelete(b) ? () => handleDeleteBiz(b) : undefined}
                  isPaused={isPaused}
                  imageUrl={imgs[0]}
                  imageCount={imgs.length}
                />
              );
            })}
          </div>
        ) : (
          <div
            className="bg-white border rounded-lg p-10 text-center text-slate-600"
            style={{ borderColor: UI.border }}
          >
            No hay negocios que coincidan con tu búsqueda.
          </div>
        )}
      </div>

      {isCreateOpen && (
        <div className="fixed inset-0 z-50">
          <div
            className="absolute inset-0 bg-black/40"
            onClick={() => {
              setIsCreateOpen(false);
              resetCreateForm();
            }}
          />

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
                <h2 className="font-semibold text-slate-900">Nuevo negocio</h2>

                <button
                  onClick={() => {
                    setIsCreateOpen(false);
                    resetCreateForm();
                  }}
                  className="text-slate-700 hover:text-slate-900"
                >
                  ✕
                </button>
              </div>

              <div className="p-5">
                <BusinessForm
                  formData={formData}
                  isSubmitting={isCreateSubmitting}
                  errorMsg={errorMsg}
                  onChange={onChange}
                  onSubmit={onCreateSubmit}
                  onCancel={() => {
                    setIsCreateOpen(false);
                    resetCreateForm();
                  }}
                  categoryOptions={categoryOptions}
                  files={files}
                  onFilesChange={setFiles}
                />

                {loadingCats && (
                  <p className="text-xs text-slate-500 mt-2">
                    Cargando categorías…
                  </p>
                )}
              </div>

              <div
                className="px-5 py-3 flex justify-end gap-2 rounded-b-lg"
                style={{ borderTop: `1px solid ${UI.border}` }}
              >
                <button
                  className="px-6 py-2 rounded-md font-semibold border bg-white text-slate-900 hover:bg-[#F2F4F7]"
                  style={{ borderColor: UI.border }}
                  onClick={() => {
                    setIsCreateOpen(false);
                    resetCreateForm();
                  }}
                  disabled={isCreateSubmitting}
                >
                  Cancelar
                </button>

                <button
                  className="px-6 py-2 rounded-md font-semibold text-white disabled:opacity-60"
                  style={{ background: UI.primary }}
                  onClick={() => document.querySelector('form')?.requestSubmit()}
                  disabled={isCreateSubmitting || !formData.category_id}
                >
                  {isCreateSubmitting ? 'Guardando…' : 'Guardar'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {isEditOpen && editingBizId != null && (
        <div className="fixed inset-0 z-50">
          <div className="absolute inset-0 bg-black/40" onClick={handleCloseEdit} />

          <div className="absolute inset-0 grid place-items-center p-6">
            <div
              className="w-full max-w-6xl bg-white rounded-lg shadow-xl border"
              style={{ borderColor: UI.border }}
            >
              <div
                className="px-5 py-3 flex items-center justify-between rounded-t-lg"
                style={{
                  background: UI.soft,
                  borderBottom: `1px solid ${UI.border}`,
                }}
              >
                <h2 className="font-semibold text-slate-900">Editar negocio</h2>

                <button
                  onClick={handleCloseEdit}
                  className="text-slate-700 hover:text-slate-900"
                >
                  ✕
                </button>
              </div>

              <div className="p-5">
                <FormBusinessEdit
                  businessId={editingBizId}
                  onClose={handleCloseEdit}
                  onSaved={async () => {
                    await loadBusinesses();
                    handleCloseEdit();
                  }}
                  categoryOptions={categoryOptions}
                />
              </div>
            </div>
          </div>
        </div>
      )}

      {viewing && (
        <BusinessView
          business={viewing.business}
          images={viewing.images}
          nearbyPlaces={viewing.nearbyPlaces}
          onClose={() => setViewing(null)}
        />
      )}
    </div>
  );
}