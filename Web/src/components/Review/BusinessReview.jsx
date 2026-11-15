// File: src/components/Review/BusinessReview.jsx
'use client';

import { useEffect, useMemo, useState } from 'react';
import { FaSearch, FaSyncAlt } from 'react-icons/fa';
import BusinessCardReview from '@/components/Review/BusinessCardReview';
import BusinessViewReview from '@/components/Review/BusinessViewReview';
import useBusiness from '@/hooks/useBusiness';
import useMedia from '@/hooks/useMedia';
import useCategories from '@/hooks/useCategories';
import toast from 'react-hot-toast';

// 🆕 imports para notificaciones y user
import { useUser } from '@/context/UserContext';
import { NotificationsService } from '@/services/notificationsService';

const UI = { primary: '#0077B6', border: '#E2E8F0' };

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

// dueño del negocio (user_id)
const getOwnerId = (b) => {
  return (
    b?.user_id ??
    b?.userId ??
    b?.id_user ??
    b?.owner?.id ??
    b?.owner?.user_id ??
    null
  );
};

const STATUS_FILTERS = [
  { id: 'pending', label: 'Pendientes' },
  { id: 'active', label: 'Activos' },
  { id: 'suspended', label: 'Cancelados' },
  { id: 'all', label: 'Todos' },
];

export default function BusinessReview() {

  // 1️⃣ primero usuario
  const { user: currentUser } = useUser();

  // 2️⃣ después token
  const [token, setToken] = useState(null);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      setToken(localStorage.getItem('token'));
    }
  }, [currentUser]);

  // 3️⃣ después useBusiness
  const {
    businesses,
    loading,
    fetchAll,
    fetchByStatus,
    validateOne,
    rejectOne,
  } = useBusiness({
    autoLoad: false,
    token,
  });
  const { fetchForBusinessIds } = useMedia();
  const { categories, loadingList: loadingCats } = useCategories();

  const senderId =
    currentUser?.id ??
    currentUser?.user_id ??
    currentUser?.uid ??
    currentUser?.idUser ??
    null;

  // modal
  const [viewing, setViewing] = useState(null); // { business, images, categoryName }
  const [submitting, setSubmitting] = useState(false);

  // filtros
  const [statusFilter, setStatusFilter] = useState('pending');
  const [query, setQuery] = useState('');

  useEffect(() => {
    if (!token) return;

    const load = async () => {
      try {
        if (statusFilter === 'all') {
          await fetchAll();
        } else {
          await fetchByStatus(statusFilter);
        }
      } catch (err) {
        console.error(err);
        toast.error('No se pudo cargar negocios');
      }
    };

    load();
  }, [token, statusFilter, fetchAll, fetchByStatus]);

  // helper categoría
  const categoryOptions = useMemo(
    () => (categories || []).map((c) => ({ value: c.id, label: c.name })),
    [categories]
  );

  const getCategoryName = (b) => {
    if (b?.category?.name) return b.category.name;
    const hit = categoryOptions.find(
      (o) => String(o.value) === String(b?.category_id)
    );
    return hit?.label ?? '—';
  };

  const listForUI = useMemo(() => {
    const list = Array.isArray(businesses) ? businesses : [];

    const q = query.trim().toLowerCase();

    if (!q) return list;

    return list.filter((b) =>
      [b.name, b.email, b.phone, b.address]
        .filter(Boolean)
        .some((v) =>
          String(v).toLowerCase().includes(q)
        )
    );
  }, [businesses, query]);

  // media por negocio (solo de los que se muestran)
  const [mediaByBusiness, setMediaByBusiness] = useState({});
  const ids = useMemo(
    () =>
      listForUI
        .map((b) => b.id ?? b._id ?? b.business_id)
        .filter((id) => id !== undefined && id !== null)
        .map((id) => Number(id))
        .filter((n) => Number.isFinite(n)),
    [listForUI]
  );

  useEffect(() => {
    if (!ids.length) {
      setMediaByBusiness({});
      return;
    }
    let mounted = true;
    (async () => {
      const map = await fetchForBusinessIds(ids, 'business');
      if (!mounted) return;
      const obj = {};
      map.forEach((arr, id) => {
        const idStr = String(id);
        const own = (arr || []).filter(
          (m) =>
            String(
              m?.entity_id ??
              m?.target_id ??
              m?.targetId
            ) === idStr
        );

        obj[idStr] = own
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
      setMediaByBusiness(obj);
    })();
    return () => {
      mounted = false;
    };
  }, [ids, fetchForBusinessIds]);

  // acciones modal
  const closeModal = () => {
    if (!submitting) setViewing(null);
  };

  const handleApprove = async () => {
    const biz = viewing?.business;

    const id = Number(
      biz?.id ?? biz?.business_id
    );

    if (!id || submitting) return;

    setSubmitting(true);

    try {
      await validateOne(id);

      await fetchByStatus(statusFilter);

      toast.success(
        'Negocio aprobado correctamente ✔️'
      );

      const ownerId = getOwnerId(biz);

      if (ownerId && senderId) {
        await NotificationsService.create({
          user_id: String(ownerId),
          sender_id: String(senderId),
          message: `Tu negocio "${biz?.name ?? ''}" ha sido aprobado ✅`,
        });
      }

      setViewing(null);
    } catch (e) {
      console.error(e);

      if (
        String(e?.message || '').includes(
          'Business already processed'
        )
      ) {
        toast.error(
          'Este negocio ya fue procesado.'
        );

        await fetchByStatus(statusFilter);

        setViewing(null);

        return;
      }

      toast.error(
        e?.message ||
        'No se pudo aprobar el negocio'
      );
    } finally {
      setSubmitting(false);
    }
  };


  const handleReject = async () => {
    const biz = viewing?.business;

    const id = Number(
      biz?.id ?? biz?.business_id
    );

    if (!id || submitting) return;

    setSubmitting(true);

    try {
      await rejectOne(id);

      await fetchByStatus(statusFilter);

      const ownerId = getOwnerId(biz);

      if (ownerId && senderId) {
        await NotificationsService.create({
          user_id: String(ownerId),
          sender_id: String(senderId),
          message: `Tu negocio "${biz?.name ?? ''}" ha sido rechazado ❌`,
        });
      }

      toast.success('Negocio rechazado');

      setViewing(null);
    } catch (e) {
      console.error(e);

      if (
        String(e?.message || '').includes(
          'Business already processed'
        )
      ) {
        toast.error(
          'Este negocio ya fue procesado.'
        );

        await fetchByStatus(statusFilter);

        setViewing(null);

        return;
      }

      toast.error(
        e?.message ||
        'No se pudo rechazar el negocio'
      );
    } finally {
      setSubmitting(false);
    }
  };

  const emptyText = (() => {
    switch (statusFilter) {
      case 'PENDING':
        return 'No hay negocios pendientes de revisión por ahora.';
      case 'APPROVED':
        return 'No hay negocios aprobados que coincidan con el filtro.';
      case 'REJECTED':
        return 'No hay negocios rechazados que coincidan con el filtro.';
      case 'ALL':
      default:
        return 'No hay negocios que coincidan con el filtro.';
    }
  })();

  return (
    <section>
      <h2 className="text-2xl font-semibold text-slate-900 mb-1">
        Revisión de Negocios
      </h2>
      <p className="text-slate-600 mb-4">
        Aprueba o rechaza solicitudes de alta y cambios.
      </p>

      {/* filtros de estado */}
      <div className="mb-3 flex flex-wrap gap-2">
        {STATUS_FILTERS.map((f) => {
          const active = statusFilter === f.id;
          return (
            <button
              key={f.id}
              type="button"
              onClick={() => setStatusFilter(f.id)}
              className={`text-xs sm:text-sm inline-flex items-center px-3 py-1.5 rounded-full border transition font-medium
                ${active
                  ? 'bg-white text-[#0077B6]'
                  : 'bg-slate-50 text-slate-600 hover:bg-slate-100'
                }`}
              style={{ borderColor: active ? UI.primary : UI.border }}
            >
              {f.label}
            </button>
          );
        })}
      </div>

      {/* barra de búsqueda + recargar */}
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
            placeholder="Buscar por nombre, correo, teléfono o dirección…"
          />
        </div>
        <button
          onClick={async () => {
            try {
              await fetchAll();
              toast.success('Lista de negocios actualizada');
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

      {/* grid de cards */}
      {loading && (!businesses || businesses.length === 0) ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {Array.from({ length: 6 }).map((_, i) => (
            <CardSkeleton key={i} />
          ))}
        </div>
      ) : listForUI.length ? (
        <>
          {loadingCats && (
            <p className="text-xs text-slate-500 mb-2">Cargando categorías…</p>
          )}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {listForUI.map((b) => {
              const id = Number(b.id ?? b._id ?? b.business_id);
              const imgs = mediaByBusiness[String(id)] ?? [];
              return (
                <BusinessCardReview
                  key={id}
                  business={b}
                  categoryName={getCategoryName(b)}
                  imageUrl={imgs[0]}
                  onEvaluate={() =>
                    setViewing({
                      business: b,
                      categoryName: getCategoryName(b),
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
        <BusinessViewReview
          business={viewing.business}
          images={viewing.images}
          categoryName={viewing.categoryName}
          onClose={closeModal}
          onApprove={handleApprove}
          onReject={handleReject}
        />
      )}
    </section>
  );
}
