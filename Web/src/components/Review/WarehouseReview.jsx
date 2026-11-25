'use client';

import { useMemo, useState } from 'react';
import { FaCheck, FaSearch, FaSyncAlt, FaTimes, FaWarehouse } from 'react-icons/fa';
import toast from 'react-hot-toast';
import useWarehouses from '@/hooks/useWarehouses';

const FILTERS = [
  { id: 'pending', label: 'Pendientes' },
  { id: 'active', label: 'Activos' },
  { id: 'inactive', label: 'Rechazados' },
  { id: 'all', label: 'Todos' },
];

const statusStyle = {
  pending: 'bg-amber-100 text-amber-800',
  active: 'bg-emerald-100 text-emerald-800',
  inactive: 'bg-rose-100 text-rose-800',
};

export default function WarehouseReview() {
  const {
    warehouses, status, setStatus, loading, savingId, error,
    canReview, fetchAll, approveOne, rejectOne,
  } = useWarehouses();
  const [query, setQuery] = useState('');

  const visibleRows = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    if (!normalized) return warehouses;
    return warehouses.filter((warehouse) =>
      [warehouse.name, warehouse.description, warehouse.address, warehouse.email, warehouse.phone]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(normalized))
    );
  }, [warehouses, query]);

  const refresh = async (nextStatus = status) => {
    await fetchAll(nextStatus);
  };

  const approve = async (warehouse) => {
    const updated = await approveOne(warehouse.id);
    if (!updated) return toast.error('No se pudo aprobar el almacén.');
    toast.success('Almacén aprobado.');
    refresh();
  };

  const reject = async (warehouse) => {
    const message = window.prompt(`Motivo para rechazar “${warehouse.name}”:`);
    if (message === null) return;
    if (!message.trim()) return toast.error('El motivo de rechazo es obligatorio.');

    const updated = await rejectOne(warehouse.id, message.trim());
    if (!updated) return toast.error('No se pudo rechazar el almacén.');
    toast.success('Almacén rechazado.');
    refresh();
  };

  if (!canReview) {
    return <p className="rounded-lg border bg-white p-5 text-slate-600">No tienes permiso para revisar almacenes.</p>;
  }

  return (
    <section>
      <h2 className="text-2xl font-semibold text-slate-900">Revisión de almacenes</h2>
      <p className="mb-4 text-slate-600">Aprueba o rechaza almacenes registrados por socios.</p>

      <div className="mb-4 flex flex-wrap items-center gap-2">
        {FILTERS.map((filter) => (
          <button
            key={filter.id}
            type="button"
            onClick={() => setStatus(filter.id)}
            className={`rounded-full border px-3 py-1.5 text-sm font-medium ${status === filter.id ? 'border-[#0077B6] bg-white text-[#0077B6]' : 'border-slate-200 bg-slate-50 text-slate-600'}`}
          >
            {filter.label}
          </button>
        ))}
        <button type="button" onClick={() => refresh()} disabled={loading} className="ml-auto inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-slate-700">
          <FaSyncAlt className={loading ? 'animate-spin' : ''} /> Recargar
        </button>
      </div>

      <label className="mb-4 flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2">
        <FaSearch className="text-slate-400" />
        <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Buscar por nombre, dirección, correo o teléfono" className="w-full outline-none" />
      </label>

      {error && <p className="mb-4 rounded-lg border border-rose-200 bg-rose-50 p-3 text-rose-700">{error}</p>}

      {loading && !warehouses.length ? (
        <p className="rounded-lg border bg-white p-6 text-center text-slate-500">Cargando almacenes…</p>
      ) : visibleRows.length ? (
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
          {visibleRows.map((warehouse) => {
            const currentStatus = String(warehouse.status || 'pending').toLowerCase();
            const isPending = currentStatus === 'pending';
            return (
              <article key={warehouse.id} className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                <div className="flex items-start justify-between gap-3">
                  <div className="flex gap-3">
                    <FaWarehouse className="mt-1 text-xl text-[#0077B6]" />
                    <div>
                      <h3 className="font-bold text-slate-900">{warehouse.name}</h3>
                      <p className="mt-1 text-sm text-slate-600">{warehouse.address || 'Sin dirección registrada'}</p>
                    </div>
                  </div>
                  <span className={`rounded-full px-2.5 py-1 text-xs font-bold ${statusStyle[currentStatus] || 'bg-slate-100 text-slate-700'}`}>{currentStatus}</span>
                </div>
                {warehouse.description && <p className="mt-4 text-sm text-slate-600">{warehouse.description}</p>}
                <div className="mt-4 grid grid-cols-2 gap-2 text-sm text-slate-600">
                  <span>{warehouse.email || 'Sin correo'}</span><span>{warehouse.phone || 'Sin teléfono'}</span>
                </div>
                {isPending && (
                  <div className="mt-5 flex gap-2 border-t border-slate-100 pt-4">
                    <button type="button" disabled={savingId === warehouse.id} onClick={() => approve(warehouse)} className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-3 py-2 text-sm font-semibold text-white disabled:opacity-60"><FaCheck /> Aprobar</button>
                    <button type="button" disabled={savingId === warehouse.id} onClick={() => reject(warehouse)} className="inline-flex items-center gap-2 rounded-lg border border-rose-200 px-3 py-2 text-sm font-semibold text-rose-700 disabled:opacity-60"><FaTimes /> Rechazar</button>
                  </div>
                )}
              </article>
            );
          })}
        </div>
      ) : <p className="rounded-lg border bg-white p-6 text-center text-slate-500">No hay almacenes para este filtro.</p>}
    </section>
  );
}
