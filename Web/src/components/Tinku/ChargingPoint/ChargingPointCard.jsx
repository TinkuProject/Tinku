// File: src/components/Tinku/ChargingPoint/ChargingPointCard.jsx
'use client';

import {
  FaMapMarkerAlt,
  FaEdit,
  FaPowerOff,
  FaCheckCircle,
  FaImage,
  FaEye,
  FaTools,
} from 'react-icons/fa';

const UI = {
  primary: '#0077B6',
  primaryHover: '#005f92',
  danger: '#E11D48',
  border: '#E2E8F0',
};

export default function ChargingPointCard({
  item,
  onEdit,
  onToggleActive,
  onMaintenance,
  onViewImage,
}) {
  const lat = item?.location?.latitude;

  const lng = item?.location?.longitude;

  const status = String(
    item?.status || ''
  ).toLowerCase();

  const active =
    status === 'active';

  const maintenance =
    status ===
    'maintenance';

  const latStr =
    typeof lat === 'number'
      ? lat.toFixed(5)
      : '—';

  const lngStr =
    typeof lng === 'number'
      ? lng.toFixed(5)
      : '—';

  const image =
    item?.image_url ||
    item?.image ||
    item?.media?.[0]?.url ||
    null;

  return (
    <div
      className="rounded-xl border bg-white overflow-hidden flex flex-col shadow-sm hover:shadow-lg hover:-translate-y-[2px] transition-all duration-200"
      style={{
        borderColor: UI.border,
      }}
    >
      {/* IMAGE */}
      <div className="relative bg-slate-100">
        <div className="aspect-[16/10] overflow-hidden">
          {image ? (
            <img
              src={image}
              alt={item.name}
              className="h-full w-full object-cover hover:scale-105 transition-transform duration-300 cursor-pointer"
              onClick={() =>
                onViewImage?.(image)
              }
            />
          ) : (
            <div className="h-full w-full grid place-items-center text-slate-400 text-sm">
              <div className="flex flex-col items-center gap-1">
                <FaImage className="text-2xl" />

                <span>
                  Sin imagen
                </span>
              </div>
            </div>
          )}
        </div>

        {/* STATUS */}
        <div className="absolute top-2 right-2">
          <span
            className={`inline-flex items-center gap-1 px-2 py-0.5 text-[11px] font-medium rounded-full border backdrop-blur ${active
                ? 'bg-emerald-50/80 text-emerald-700 border-emerald-200'
                : maintenance
                  ? 'bg-amber-50/90 text-amber-700 border-amber-200'
                  : 'bg-slate-50/80 text-slate-600 border-slate-200'
              }`}
          >
            <span
              className={`h-1.5 w-1.5 rounded-full ${active
                  ? 'bg-emerald-600'
                  : maintenance
                    ? 'bg-amber-500'
                    : 'bg-slate-400'
                }`}
            />

            {active
              ? 'Activo'
              : maintenance
                ? 'Mantenimiento'
                : 'Inactivo'}
          </span>
        </div>
      </div>

      {/* CONTENT */}
      <div className="p-3 flex-1 flex flex-col gap-1.5">
        <h4
          className="text-base font-semibold text-slate-900 leading-tight line-clamp-1"
          title={item.name}
        >
          {item.name}
        </h4>

        <p
          className="text-sm text-slate-600 flex items-center gap-1 line-clamp-2"
          title={item.address || ''}
        >
          <FaMapMarkerAlt className="text-[#0077B6] shrink-0" />

          {item.address ||
            'Sin dirección'}
        </p>

        <div className="flex flex-wrap items-center gap-x-4 text-[11px] text-slate-500">
          <span>
            Lat:{' '}
            <b className="text-slate-700">
              {latStr}
            </b>
          </span>

          <span>
            Lng:{' '}
            <b className="text-slate-700">
              {lngStr}
            </b>
          </span>
        </div>
      </div>

      {/* ACTIONS */}
      <div
        className="p-3 pt-0 flex flex-wrap items-center gap-2 border-t"
        style={{
          borderColor: UI.border,
        }}
      >
        {/* EDIT */}
        <button
          onClick={() =>
            onEdit?.(item)
          }
          className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-md border text-[#0077B6] font-medium hover:bg-sky-50 active:bg-sky-100 transition text-sm"
          style={{
            borderColor:
              UI.primary,
          }}
        >
          <FaEdit />
          Editar
        </button>

        {/* ACTIVE */}
        <button
          onClick={() =>
            onToggleActive?.(
              item
            )
          }
          className={`inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-white font-medium text-sm transition ${active
              ? 'bg-[#E11D48] hover:bg-[#be123c]'
              : 'bg-[#0077B6] hover:bg-[#005f92]'
            }`}
        >
          {active ? (
            <>
              <FaPowerOff />
              Inactivar
            </>
          ) : (
            <>
              <FaCheckCircle />
              Activar
            </>
          )}
        </button>

        {/* MAINTENANCE */}
        <button
          onClick={() =>
            onMaintenance?.(
              item
            )
          }
          className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-white font-medium text-sm transition bg-amber-500 hover:bg-amber-600"
        >
          <FaTools />
          Mant.
        </button>

        {/* VIEW */}
        {image && (
          <button
            onClick={() =>
              onViewImage?.(
                image
              )
            }
            className="ml-auto inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-md border text-slate-700 font-medium hover:bg-slate-50 active:bg-slate-100 transition text-sm"
            style={{
              borderColor:
                UI.border,
            }}
          >
            <FaEye />
            Ver
          </button>
        )}
      </div>
    </div>
  );
}