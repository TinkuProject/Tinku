// File: src/components/Transport/TransportationLines.jsx
'use client';

import dynamic from 'next/dynamic';
import { useEffect, useState } from 'react';
import useTransportLines from '@/hooks/useTransportLines';

const VehicleTypes = dynamic(() => import('./VehicleTypes'), { ssr: false });

const RegisterTrasportationLines = dynamic(
  () => import('./RegisterTrasportationLines'),
  { ssr: false }
);

const TransportLinesTable = dynamic(() => import('./TransportLinesCard'), {
  ssr: false,
});

const RouteMapping = dynamic(() => import('./RouteMapping'), {
  ssr: false,
});

export default function TransportationLines() {
  const [tab, setTab] = useState('vehicle-types');

  const {
    rows: lines,
    loading: loadingLines,
    err: errLines,
  } = useTransportLines();

  const [selectedId, setSelectedId] = useState('');

  useEffect(() => {
    if (!selectedId) return;
  }, [selectedId]);

  const renderTabButton = (key, label) => {
    const active = tab === key;

    return (
      <button
        type="button"
        onClick={() => setTab(key)}
        className={`px-4 py-2 rounded-md font-semibold border transition ${active
            ? 'bg-[#0077B6] text-white border-[#0077B6]'
            : 'bg-white text-[#0077B6] border-[#0077B6] hover:bg-[#E0F4FF]'
          }`}
      >
        {label}
      </button>
    );
  };

  return (
    <div className="p-8 bg-[#F8F9FA] shadow-md rounded-lg">
      <h1 className="text-3xl font-bold mb-4 text-[#0077B6]">
        Gestión de Transporte
      </h1>

      <div className="flex flex-wrap gap-2 mb-6">
        {renderTabButton('vehicle-types', 'Tipos de vehículos')}
        {renderTabButton('lines', 'Líneas de transporte')}
        {renderTabButton('route-mapping', 'Trazador de rutas')}
      </div>

      {tab === 'vehicle-types' && <VehicleTypes />}

      {tab === 'lines' && (
        <div className="space-y-8">
          <RegisterTrasportationLines />
          <TransportLinesTable />
        </div>
      )}

      {tab === 'route-mapping' && (
        <div className="space-y-6">
          <div className="flex flex-wrap items-end gap-3">
            <div className="flex flex-col">
              <label className="block text-sm font-medium text-slate-700">
                Selecciona una línea
              </label>

              <select
                value={selectedId}
                onChange={(e) => setSelectedId(e.target.value)}
                className="mt-1 w-80 px-3 py-2 rounded-lg border border-slate-300 bg-white text-black focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                disabled={loadingLines || (lines?.length ?? 0) === 0}
              >
                <option value="">
                  {loadingLines ? 'Cargando líneas…' : '— Selecciona una —'}
                </option>

                {lines?.map((line) => (
                  <option key={line.id} value={line.id}>
                    {line.name || 'Sin nombre'} (#{line.id})
                  </option>
                ))}
              </select>

              {errLines && (
                <span className="text-sm text-rose-600 mt-1">
                  {errLines}
                </span>
              )}
            </div>

            {selectedId && (
              <span className="px-2 py-1 rounded bg-slate-100 border text-xs text-slate-700">
                Seleccionada: #{selectedId}
              </span>
            )}
          </div>

          {selectedId ? (
            <RouteMapping
              lineId={Number(selectedId)}
              initialDirection="outbound"
            />
          ) : (
            <div className="p-6 bg-white border rounded-xl text-slate-500">
              Selecciona una <b>línea</b> para comenzar a trazar la ruta.
            </div>
          )}
        </div>
      )}
    </div>
  );
}