// File: src/components/Transport/RouteMapping.jsx
'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { FaPlus, FaSync, FaTrash } from 'react-icons/fa';

import useRoutePoints from '@/hooks/useRoutePoints';
import useTransportLines from '@/hooks/useTransportLines';
import MapPickerLine from '@/components/Transport/MapPickerLine';
import toast from 'react-hot-toast';

const UI = {
  primary: '#0EA5E9',
  primaryHover: '#0284C7',
  danger: '#E11D48',
  border: '#E2E8F0',
};

const DIR = {
  outbound: 'outbound',
  return: 'return',
};

const DIR_LABEL = {
  outbound: 'Ida',
  return: 'Vuelta',
};

function parsePoint(row) {
  if (!row) return { lat: NaN, lng: NaN };

  const loc = row.location;

  if (loc && typeof loc === 'object') {
    if (Array.isArray(loc.coordinates)) {
      const [lng, lat] = loc.coordinates.map(Number);
      return { lat, lng };
    }

    const lat = Number(loc.latitude ?? loc.lat);
    const lng = Number(loc.longitude ?? loc.lng);

    if (Number.isFinite(lat) && Number.isFinite(lng)) {
      return { lat, lng };
    }
  }

  if (typeof loc === 'string') {
    const match = loc.match(
      /POINT\s*\(\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*\)/i
    );

    if (match) {
      return {
        lng: Number(match[1]),
        lat: Number(match[2]),
      };
    }
  }

  const lat = Number(row.latitude ?? row.lat);
  const lng = Number(row.longitude ?? row.lng);

  return { lat, lng };
}

export default function RouteMapping({
  lineId,
  initialDirection = DIR.outbound,
}) {
  const [direction, setDirection] = useState(initialDirection);

  const {
    rows,
    loading,
    savingId,
    err,
    fetchByLine,
    createOne,
    remove,
  } = useRoutePoints({ autoLoad: false });

  const {
    rows: lines,
    loading: loadingLines,
    err: errLines,
  } = useTransportLines();

  const [internalLineId, setInternalLineId] = useState(null);
  const [comboText, setComboText] = useState('');

  const effectiveLineId =
    typeof lineId === 'number' ? lineId : internalLineId;

  useEffect(() => {
    if (!lines || !effectiveLineId) return;

    const found = lines.find((line) => Number(line.id) === Number(effectiveLineId));

    setComboText(found ? `${found.name} (#${found.id})` : String(effectiveLineId));
  }, [effectiveLineId, lines]);

  const suggestions = useMemo(() => {
    const text = comboText.trim().toLowerCase();

    if (!text) return lines ?? [];

    return (lines ?? []).filter((line) => {
      const name = String(line.name || '').toLowerCase();
      const id = String(line.id || '');

      return name.includes(text) || id.includes(text);
    });
  }, [comboText, lines]);

  const resolveToId = useCallback(
    (value) => {
      const raw = String(value || '').trim();

      if (/^\d+$/.test(raw)) return Number(raw);

      const match = raw.match(/#(\d+)/);

      if (match?.[1]) return Number(match[1]);

      const byName = (lines ?? []).find(
        (line) => String(line.name || '').toLowerCase() === raw.toLowerCase()
      );

      if (byName) return byName.id;

      if (suggestions.length === 1) return suggestions[0].id;

      return null;
    },
    [lines, suggestions]
  );

  const commitCombo = useCallback(() => {
    const id = resolveToId(comboText);

    if (id) {
      setInternalLineId(id);
    }
  }, [comboText, resolveToId]);

  const refresh = useCallback(async () => {
    if (!effectiveLineId) return;

    await fetchByLine(Number(effectiveLineId), direction);
  }, [fetchByLine, effectiveLineId, direction]);

  useEffect(() => {
    if (effectiveLineId) {
      fetchByLine(Number(effectiveLineId), direction);
    }
  }, [effectiveLineId, direction, fetchByLine]);

  const pointsSameDir = useMemo(() => {
    return (rows || [])
      .filter((row) => String(row.direction || '').toLowerCase() === direction)
      .sort((a, b) => Number(a.stop_order ?? 0) - Number(b.stop_order ?? 0));
  }, [rows, direction]);

  const nextOrder = useMemo(() => {
    if (!pointsSameDir.length) return 0;

    return (
      Math.max(...pointsSameDir.map((point) => Number(point.stop_order ?? 0))) + 1
    );
  }, [pointsSameDir]);

  const [form, setForm] = useState({
    lat: -17.3895,
    lng: -66.1568,
  });

  const mapValue = useMemo(
    () => ({
      lat: Number(form.lat),
      lng: Number(form.lng),
    }),
    [form.lat, form.lng]
  );

  const handleMapChange = ({ lat, lng }) => {
    setForm({
      lat,
      lng,
    });
  };

  const handleCreate = async (event) => {
    event?.preventDefault?.();

    if (!effectiveLineId) {
      toast.error('Selecciona una línea primero');
      return;
    }

    const lat = Number(form.lat);
    const lng = Number(form.lng);

    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      toast.error('Selecciona un punto válido en el mapa');
      return;
    }

    try {
      await createOne({
        transport_line_id: Number(effectiveLineId),
        direction,
        stop_order: nextOrder,
        location: {
          latitude: lat,
          longitude: lng,
        },
      });

      toast.success('Punto añadido');
    } catch (error) {
      console.error(error);
      toast.error('No se pudo añadir el punto');
    }
  };

  const handleRemove = async (id) => {
    const ok = window.confirm('¿Eliminar este punto de la ruta?');

    if (!ok) return;

    try {
      await remove(id);
      toast.success('Punto eliminado');
    } catch (error) {
      console.error(error);
      toast.error('No se pudo eliminar el punto');
    }
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <div className="flex items-center gap-3 flex-wrap">
          <span className="text-lg font-semibold text-slate-800">
            Gestión de Transporte · Trazador de rutas
          </span>

          {typeof lineId === 'number' ? (
            <span
              className="px-2 py-0.5 text-xs rounded-full bg-slate-100 text-slate-600 border"
              style={{ borderColor: UI.border }}
            >
              Línea #{lineId}
            </span>
          ) : (
            <div className="flex items-center gap-2">
              <div className="flex flex-col">
                <input
                  list="line-options"
                  className="px-3 py-1.5 rounded-lg border border-slate-300 text-sm w-72 text-slate-800 bg-white"
                  placeholder={
                    loadingLines ? 'Cargando líneas…' : 'Escribe nombre o ID…'
                  }
                  value={comboText}
                  onChange={(e) => setComboText(e.target.value)}
                  onBlur={commitCombo}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      commitCombo();
                    }
                  }}
                  disabled={loadingLines}
                />

                <datalist id="line-options">
                  {(suggestions ?? []).map((line) => (
                    <option
                      key={line.id}
                      value={`${line.name || 'Sin nombre'} (#${line.id})`}
                    />
                  ))}
                </datalist>
              </div>

              {effectiveLineId && (
                <span
                  className="px-2 py-0.5 text-xs rounded-full bg-slate-100 text-slate-600 border"
                  style={{ borderColor: UI.border }}
                >
                  Línea #{effectiveLineId}
                </span>
              )}
            </div>
          )}
        </div>

        <div className="flex items-center gap-2">
          {Object.values(DIR).map((value) => {
            const active = direction === value;

            return (
              <button
                key={value}
                type="button"
                onClick={() => setDirection(value)}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium border transition-colors ${active
                    ? 'bg-sky-600 text-white border-sky-600 shadow-sm'
                    : 'bg-white text-slate-700 border-slate-300 hover:bg-slate-50'
                  }`}
              >
                {DIR_LABEL[value]}
              </button>
            );
          })}

          <button
            type="button"
            onClick={async () => {
              try {
                await refresh();
                toast.success('Ruta actualizada');
              } catch (error) {
                console.error(error);
                toast.error('No se pudo recargar la ruta');
              }
            }}
            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-slate-200 text-slate-900 hover:bg-slate-300"
          >
            <FaSync /> Recargar
          </button>
        </div>
      </div>

      {errLines && (
        <div className="px-3 py-2 bg-red-50 text-red-700 border border-red-200 rounded-md text-sm">
          {errLines}
        </div>
      )}

      {err && (
        <div className="px-3 py-2 bg-red-50 text-red-700 border border-red-200 rounded-md text-sm">
          {err}
        </div>
      )}

      {!effectiveLineId && (
        <div
          className="px-4 py-3 rounded-md bg-white border text-slate-600 text-sm"
          style={{ borderColor: UI.border }}
        >
          Ingresa un <b>nombre</b> o <b>ID de línea</b> para comenzar.
        </div>
      )}

      <form
        onSubmit={handleCreate}
        className="grid md:grid-cols-3 gap-4 bg-white border rounded-xl p-4"
        style={{ borderColor: UI.border }}
      >
        <div className="md:col-span-3 grid gap-2">
          <label className="text-sm font-medium text-slate-700">
            Mapa ({DIR_LABEL[direction]})
          </label>

          <div className="w-full flex justify-center">
            <div className="w-full max-w-5xl">
              <MapPickerLine
                value={mapValue}
                onChange={handleMapChange}
                points={pointsSameDir
                  .map((row) => {
                    const { lat, lng } = parsePoint(row);

                    return {
                      id: row.id,
                      lat,
                      lng,
                      stop_order: row.stop_order,
                      order: row.stop_order,
                    };
                  })
                  .filter(
                    (point) =>
                      Number.isFinite(point.lat) && Number.isFinite(point.lng)
                  )}
                height={500}
                showMyLocation
                showPolyline
                showMarkers
                fitToRoute
                disabled={!effectiveLineId}
                toolbarExtra={
                  <span
                    className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-sky-800 bg-sky-100 border text-sm"
                    style={{ borderColor: UI.primary }}
                  >
                    Próximo: <b>{nextOrder}</b>
                    <span className="text-xs text-slate-500">(auto)</span>
                  </span>
                }
              />
            </div>
          </div>

          <div className="text-xs text-black text-center">
            Lat: <b>{Number(mapValue.lat).toFixed(5)}</b> · Lng:{' '}
            <b>{Number(mapValue.lng).toFixed(5)}</b>
          </div>
        </div>

        <div className="md:col-span-3 flex justify-end gap-2">
          <button
            type="submit"
            disabled={savingId === 'new' || !effectiveLineId}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg text-white disabled:opacity-60"
            style={{ backgroundColor: UI.primary }}
            onMouseOver={(e) =>
              (e.currentTarget.style.backgroundColor = UI.primaryHover)
            }
            onMouseOut={(e) =>
              (e.currentTarget.style.backgroundColor = UI.primary)
            }
          >
            <FaPlus /> {savingId === 'new' ? 'Guardando…' : 'Añadir punto'}
          </button>
        </div>
      </form>

      <div
        className="overflow-x-auto bg-white border rounded-xl"
        style={{ borderColor: UI.border }}
      >
        <table className="min-w-full text-sm">
          <thead className="bg-sky-50 text-slate-700">
            <tr>
              <th className="px-4 py-3 text-left">Orden</th>
              <th className="px-4 py-3 text-left">Lat</th>
              <th className="px-4 py-3 text-left">Lng</th>
              <th className="px-4 py-3 text-right">Acciones</th>
            </tr>
          </thead>

          <tbody className="[&>tr:nth-child(odd)]:bg-slate-50/60">
            {loading && pointsSameDir.length === 0 ? (
              <tr>
                <td className="px-4 py-6 text-center text-slate-500" colSpan={4}>
                  Cargando…
                </td>
              </tr>
            ) : pointsSameDir.length === 0 ? (
              <tr>
                <td className="px-4 py-6 text-center text-slate-500" colSpan={4}>
                  No hay puntos en {DIR_LABEL[direction]}.
                </td>
              </tr>
            ) : (
              pointsSameDir.map((row) => {
                const { lat, lng } = parsePoint(row);

                return (
                  <tr
                    key={row.id}
                    className="border-t"
                    style={{ borderColor: UI.border }}
                  >
                    <td className="px-4 py-3 font-medium text-slate-800">
                      {row.stop_order}
                    </td>

                    <td className="px-4 py-3 text-black">
                      {Number.isFinite(lat) ? lat.toFixed(5) : '—'}
                    </td>

                    <td className="px-4 py-3 text-black">
                      {Number.isFinite(lng) ? lng.toFixed(5) : '—'}
                    </td>

                    <td className="px-4 py-3 text-right">
                      <button
                        type="button"
                        onClick={() => handleRemove(row.id)}
                        disabled={savingId === row.id}
                        className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-white disabled:opacity-60"
                        style={{ backgroundColor: UI.danger }}
                      >
                        <FaTrash /> Eliminar
                      </button>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}