// File: src/components/Tinku/ChargingPoint/ChargingPointsPanel.jsx
'use client';

import { useEffect, useMemo, useState } from 'react';

import useChargingPoints from '@/hooks/useChargingPoints';
import useMedia from '@/hooks/useMedia';

import { uploadImages } from '@/services/storageService';

import ChargingPointFormModal from './ChargingPointFormModal';
import ChargingPointCard from './ChargingPointCard';

const UI = {
  primary: '#0077B6',
  primaryHover: '#005f92',
  border: '#E2E8F0',
  danger: '#E11D48',
};

export default function ChargingPointsPanel() {
  const {
    rows,
    loading,
    savingId,
    error,
    fetchAll,
    createOne,
    updateOne,
    removeOne,
    activateOne,
    maintenanceOne,
  } = useChargingPoints({ autoLoad: true });

  const { fetchForBusinessIds } = useMedia();

  const [mediaByPoint, setMediaByPoint] = useState({});

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [saving, setSaving] = useState(false);
  const [modalImg, setModalImg] = useState(null);

  const pointIds = useMemo(() => {
    return (rows || [])
      .map((item) => Number(item.id))
      .filter((id) => Number.isFinite(id));
  }, [rows]);

  const sorted = useMemo(() => {
    return (rows || [])
      .slice()
      .sort((a, b) => Number(b.id) - Number(a.id));
  }, [rows]);

  const reloadMedia = async (ids = pointIds) => {
    if (!ids.length) {
      setMediaByPoint({});
      return;
    }

    const map = await fetchForBusinessIds(ids, 'charging_point');

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
          url:
            m.url ||
            m.image_url ||
            m.media_url ||
            m.path ||
            m.fileUrl,
        }))
        .filter((m) => m.id && m.url);
    });

    setMediaByPoint(obj);
  };

  useEffect(() => {
    if (!pointIds.length) {
      setMediaByPoint({});
      return;
    }

    let mounted = true;

    (async () => {
      try {
        const map = await fetchForBusinessIds(
          pointIds,
          'charging_point'
        );

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
              url:
                m.url ||
                m.image_url ||
                m.media_url ||
                m.path ||
                m.fileUrl,
            }))
            .filter((m) => m.id && m.url);
        });

        setMediaByPoint(obj);
      } catch (e) {
        console.error('[ChargingPointsPanel] Error cargando media:', e);
        setMediaByPoint({});
      }
    })();

    return () => {
      mounted = false;
    };
  }, [pointIds, fetchForBusinessIds]);

  const openCreate = () => {
    setEditing(null);
    setModalOpen(true);
  };

  const openEdit = (item) => {
    setEditing(item);
    setModalOpen(true);
  };

  const handleSave = async ({ form, file }) => {
    try {
      setSaving(true);

      const payload = {
        id: editing?.id,

        name: String(form.name || '').trim(),

        address: String(form.address || '').trim(),

        status: form.status || 'active',

        location: {
          latitude: Number(form.lat ?? form.latitude),
          longitude: Number(form.lng ?? form.longitude),
        },
      };

      let saved;

      if (editing?.id) {
        saved = await updateOne(editing.id, payload);
      } else {
        saved = await createOne(payload);
      }

      const savedId = Number(saved?.id ?? editing?.id);

      if (file && savedId) {
        await uploadImages([file], {
          entityType: 'charging_point',
          entityId: savedId,
          folder: 'charging-points',
        });
      }

      await fetchAll();

      if (savedId) {
        await reloadMedia([...new Set([...pointIds, savedId])]);
      }

      setModalOpen(false);
      setEditing(null);
    } catch (e) {
      alert(e?.message || 'No se pudo guardar el punto de carga');
    } finally {
      setSaving(false);
    }
  };

  const handleToggleActive = async (item) => {
    try {
      if (item.status === 'active') {
        await removeOne(item.id);
      } else {
        await activateOne(item.id);
      }

      await fetchAll();
    } catch (e) {
      alert(e?.message || 'No se pudo cambiar el estado');
    }
  };

  const handleMaintenance = async (item) => {
    try {
      await maintenanceOne(item.id);
      await fetchAll();
    } catch (e) {
      alert(e?.message || 'No se pudo poner en mantenimiento');
    }
  };

  const handleReload = async () => {
    await fetchAll();
    await reloadMedia();
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h3 className="text-base font-semibold text-slate-700">
          Puntos de Recarga{' '}
          <span className="text-slate-500">
            · {sorted.length} registro(s)
          </span>
        </h3>

        <div className="flex gap-2">
          <button
            onClick={handleReload}
            className="px-3 py-2 rounded-lg text-white font-semibold"
            style={{ backgroundColor: UI.primary }}
            disabled={loading}
          >
            {loading ? 'Actualizando…' : 'Recargar'}
          </button>

          <button
            onClick={openCreate}
            className="px-3 py-2 rounded-lg font-semibold border"
            style={{
              borderColor: UI.primary,
              color: UI.primary,
            }}
          >
            + Registrar nuevo punto
          </button>
        </div>
      </div>

      {sorted.length === 0 ? (
        <div
          className="px-4 py-10 text-center text-slate-500 bg-white border rounded-xl"
          style={{ borderColor: UI.border }}
        >
          Aún no hay puntos de recarga.
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {sorted.map((item) => {
            const media = mediaByPoint[String(item.id)] || [];
            const imageUrl = media?.[0]?.url || null;

            return (
              <ChargingPointCard
                key={item.id}
                item={{
                  ...item,
                  media,
                  image_url: imageUrl,
                }}
                onEdit={openEdit}
                onToggleActive={handleToggleActive}
                onMaintenance={handleMaintenance}
                onViewImage={setModalImg}
              />
            );
          })}
        </div>
      )}

      {error && (
        <div className="px-3 py-2 bg-red-50 text-red-700 border border-red-200 rounded-md text-sm">
          {error}
        </div>
      )}

      <ChargingPointFormModal
        open={modalOpen}
        initial={
          editing
            ? {
              ...editing,
              media: mediaByPoint[String(editing.id)] || [],
              image_url:
                mediaByPoint[String(editing.id)]?.[0]?.url || '',
            }
            : null
        }
        saving={saving || savingId != null}
        onCancel={() => {
          setModalOpen(false);
          setEditing(null);
        }}
        onSave={handleSave}
      />

      {modalImg && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center backdrop-blur-sm"
          style={{
            background:
              'radial-gradient(circle at 50% 40%, rgba(0,0,0,0.45), rgba(0,0,0,0.65) 60%, rgba(0,0,0,0.75))',
          }}
          onClick={() => setModalImg(null)}
        >
          <div
            className="relative bg-white/90 p-3 rounded-2xl shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <img
              src={modalImg}
              alt="preview"
              className="max-h-[85vh] max-w-[85vw] rounded-lg border border-slate-200"
            />

            <button
              onClick={() => setModalImg(null)}
              className="absolute top-3 right-3 bg-black/60 text-white rounded-full px-2 py-1 hover:bg-black/80"
            >
              ✕
            </button>
          </div>
        </div>
      )}
    </div>
  );
}