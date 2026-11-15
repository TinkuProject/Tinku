// File: src/components/Category/CategoryRow.jsx
'use client';

import { FaEdit, FaPlay, FaPause, FaTrash } from 'react-icons/fa';

function entityLabel(type) {
  switch (type) {
    case 'business':
      return 'Negocio';
    case 'event':
      return 'Evento';
    case 'tourist_place':
      return 'Lugar turístico';
    case 'product':
      return 'Producto';
    default:
      return type || '—';
  }
}

function businessLabel(type) {
  switch (type) {
    case 'business':
      return 'Negocio';
    case 'service':
      return 'Servicio';
    default:
      return type || '—';
  }
}

export default function CategoryRow({
  category,
  index,
  rowUpdatingId,
  onEdit,
  onToggleActive,
  onDelete,
  isSubmitting,
}) {
  const isLoading = rowUpdatingId === category.id;
  const isActive = category.status === 'active';

  const img =
    category.media?.[0]?.url ||
    category.image_url ||
    category.cover ||
    '';

  return (
    <tr className="hover:bg-[#F0F8FF] transition duration-150">
      <td className="border border-slate-200 px-4 py-3 font-medium text-slate-800">
        {category.name}
      </td>

      <td className="border border-slate-200 px-4 py-3">
        {entityLabel(category.entity_type)}
      </td>

      <td className="border border-slate-200 px-4 py-3">
        {category.entity_type === 'business'
          ? businessLabel(category.business_type)
          : '—'}
      </td>

      <td className="border border-slate-200 px-4 py-3 text-center">
        {img ? (
          <img
            src={img}
            alt={category.name || 'Categoría'}
            className="h-16 w-24 object-cover rounded-md mx-auto border border-slate-200 shadow-sm"
          />
        ) : (
          <span className="text-slate-400 italic">Sin imagen</span>
        )}
      </td>

      <td className="border border-slate-200 px-4 py-3 text-center">
        <span
          className={`px-2 py-1 rounded-full text-xs font-medium ${isActive
              ? 'bg-green-100 text-green-700'
              : 'bg-red-100 text-red-600'
            }`}
        >
          {isActive ? 'Activo' : 'Inactivo'}
        </span>
      </td>

      <td className="border border-slate-200 px-4 py-3 text-center">
        <div className="flex justify-center items-center gap-2">
          <button
            type="button"
            onClick={() => onEdit(index)}
            disabled={isLoading || isSubmitting}
            className="p-2 rounded-md bg-white hover:bg-slate-100 border border-slate-300 transition disabled:opacity-60"
            title="Editar"
          >
            <FaEdit className="text-[#0077B6]" />
          </button>

          <button
            type="button"
            onClick={() => onToggleActive(index)}
            disabled={isLoading || isSubmitting}
            className={`p-2 rounded-md border transition disabled:opacity-60 ${!isActive
                ? 'bg-teal-50 text-[#0077B6] hover:bg-teal-100 border-teal-200'
                : 'bg-rose-50 text-red-500 hover:bg-rose-100 border-rose-200'
              }`}
            title={isLoading ? 'Actualizando…' : !isActive ? 'Activar' : 'Desactivar'}
          >
            {!isActive ? <FaPlay /> : <FaPause />}
          </button>

          <button
            type="button"
            onClick={() => onDelete(index)}
            disabled={isLoading || isSubmitting}
            className="p-2 rounded-md border border-rose-200 bg-rose-50 text-rose-600 hover:bg-rose-100 transition disabled:opacity-60"
            title="Eliminar"
          >
            <FaTrash />
          </button>
        </div>
      </td>
    </tr>
  );
}