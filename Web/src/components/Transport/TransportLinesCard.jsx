// File: src/components/Transport/TransportLinesCard.jsx
'use client';

import { useMemo, useState } from 'react';
import {
  FaEdit,
  FaTrash,
  FaSync,
  FaToggleOff,
  FaToggleOn,
} from 'react-icons/fa';

import useTransportLines from '@/hooks/useTransportLines';
import useVehicleTypes from '@/hooks/useVehicleTypes';
import TransportLinesFormEdit from './TransportLinesFormEdit';
import toast from 'react-hot-toast';

const UI = {
  primary: '#0077B6',
  border: '#E2E8F0',
};

function getMediaImages(row) {
  const media = Array.isArray(row?.media) ? row.media : [];

  return media
    .map((m) => m?.url || m?.image_url || m?.media_url || m?.path)
    .filter(Boolean);
}

export default function TransportLinesCard() {
  const {
    filteredRows,
    loading,
    err,
    savingId,
    search,
    setSearch,
    fetchAll,
    toggleStatus,
    remove,
  } = useTransportLines();

  const { rows: vehicleTypes } = useVehicleTypes();

  const typeNameById = useMemo(() => {
    const map = new Map();

    (vehicleTypes || []).forEach((t) => {
      map.set(t.id, t.name);
    });

    return map;
  }, [vehicleTypes]);

  const rows = useMemo(() => filteredRows, [filteredRows]);

  const [editingRow, setEditingRow] = useState(null);

  return (
    <div className="space-y-4">
      <div className="flex flex-col md:flex-row items-center justify-between gap-3">
        <h3 className="text-xl font-semibold" style={{ color: UI.primary }}>
          Líneas registradas
        </h3>

        <div className="flex items-center gap-2 w-full md:w-auto">
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Buscar por nombre o tipo…"
            className="w-full md:w-72 px-3 py-2 rounded-lg border border-slate-300 bg-white text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
          />

          <button
            onClick={async () => {
              try {
                await fetchAll();
                toast.success('Lista actualizada');
              } catch (e) {
                toast.error('No se pudo actualizar');
                console.error(e);
              }
            }}
            className="inline-flex items-center gap-2 px-3 py-2 rounded-lg bg-[#E2E8F0] text-[#0F172A] hover:bg-[#CBD5E0] transition"
          >
            <FaSync className="text-[#0077B6]" />
            Recargar
          </button>
        </div>
      </div>

      {err && (
        <div className="px-3 py-2 rounded-md bg-red-50 text-red-700 border border-red-200 text-sm">
          {err}
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
        {loading ? (
          Array.from({ length: 6 }).map((_, i) => (
            <div
              key={i}
              className="border rounded-xl bg-white shadow-sm overflow-hidden"
              style={{ borderColor: UI.border }}
            >
              <div className="h-40 bg-slate-200 animate-pulse" />

              <div className="p-4 space-y-2">
                <div className="h-5 bg-slate-200 rounded w-1/2" />
                <div className="h-4 bg-slate-200 rounded w-1/3" />
              </div>
            </div>
          ))
        ) : rows.length === 0 ? (
          <div
            className="col-span-full text-center text-slate-500 py-10 bg-white border rounded-xl"
            style={{ borderColor: UI.border }}
          >
            Sin resultados.
          </div>
        ) : (
          rows.map((r) => {
            const isActive = r.status === 'active';

            const typeName =
              r.vehicle_type_name ||
              typeNameById.get(r.vehicle_type_id) ||
              r.vehicle_type_id;

            const mediaImages = getMediaImages(r);

            const newestImages = [...mediaImages].reverse();

            const logo = r.logo || newestImages[1] || newestImages[0] || '';

            const vehiclePhoto =
              r.vehicle_photo || newestImages[0] || newestImages[1] || '';

            return (
              <div
                key={r.id}
                className="relative border rounded-xl bg-white shadow-sm overflow-hidden hover:shadow-md transition"
                style={{ borderColor: UI.border }}
              >
                <div className="relative">
                  {vehiclePhoto ? (
                    <img
                      src={vehiclePhoto}
                      alt="vehículo"
                      className="w-full h-40 object-cover"
                    />
                  ) : (
                    <div className="w-full h-40 bg-slate-100 grid place-items-center text-slate-400">
                      Sin foto
                    </div>
                  )}

                  <span
                    className={`absolute top-2 left-2 px-2 py-0.5 text-xs rounded-full font-semibold ${isActive
                      ? 'bg-green-100 text-green-700'
                      : 'bg-red-100 text-red-600'
                      }`}
                  >
                    {isActive ? 'Activo' : 'Inactivo'}
                  </span>
                </div>

                <div className="p-4 space-y-3">
                  <div className="flex items-center gap-3">
                    {logo ? (
                      <img
                        src={logo}
                        alt="logo"
                        className="h-10 w-10 object-cover rounded bg-white border"
                      />
                    ) : (
                      <div className="h-10 w-10 grid place-items-center text-slate-400 border rounded bg-white">
                        —
                      </div>
                    )}

                    <div>
                      <h4 className="font-semibold text-slate-800">
                        {r.name || '—'}
                      </h4>

                      <p className="text-xs text-slate-500">ID: {r.id}</p>
                    </div>
                  </div>

                  <div className="text-sm">
                    <span className="font-medium text-slate-700">
                      Tipo:&nbsp;
                    </span>

                    <span className="text-slate-800">{typeName}</span>
                  </div>

                  <div className="pt-1 flex items-center justify-end gap-2">
                    <button
                      onClick={() => setEditingRow(r)}
                      className="p-2 rounded-full bg-blue-100 text-blue-700 hover:bg-blue-200 transition"
                      title="Editar"
                    >
                      <FaEdit />
                    </button>

                    <button
                      onClick={() => toggleStatus(r.id)}
                      disabled={savingId === r.id}
                      className="p-2 rounded-full bg-emerald-100 text-emerald-700 hover:bg-emerald-200 transition disabled:opacity-50"
                      title={isActive ? 'Desactivar' : 'Activar'}
                    >
                      {isActive ? <FaToggleOff /> : <FaToggleOn />}
                    </button>

                    <button
                      onClick={() => remove(r.id)}
                      disabled={savingId === r.id}
                      className="p-2 rounded-full bg-red-100 text-red-700 hover:bg-red-200 transition disabled:opacity-50"
                      title="Eliminar"
                    >
                      <FaTrash />
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      <TransportLinesFormEdit
        open={!!editingRow}
        row={editingRow}
        onClose={() => setEditingRow(null)}
        onSaved={fetchAll}
      />
    </div>
  );
}