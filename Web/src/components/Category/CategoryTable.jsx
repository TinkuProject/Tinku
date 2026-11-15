// File: src/components/Category/CategoryTable.jsx
'use client';

import { useMemo, useState } from 'react';

import CategoryRow from './CategoryRow';

const UI = {
  border: '#CBD5F5',
  primary: '#0EA5E9',
};

export default function CategoryTable({
  categories = [],
  loading,

  rowUpdatingId,

  onEdit,
  onToggleActive,
  onDelete,

  isSubmitting,

  entityTypes = [],
}) {
  const [typeFilter, setTypeFilter] =
    useState('all');

  const typeOptions = useMemo(() => {
    return [
      {
        value: 'all',
        label: 'Todos',
      },

      ...entityTypes,
    ];
  }, [entityTypes]);

  const filteredCategories =
    useMemo(() => {
      if (typeFilter === 'all') {
        return categories;
      }

      return categories.filter(
        (cat) =>
          cat.entity_type === typeFilter
      );
    }, [categories, typeFilter]);

  const isFiltered =
    typeFilter !== 'all';

  return (
    <>
      <div className="flex items-center justify-between mb-4 gap-3 flex-wrap">
        <h2 className="text-2xl font-semibold text-[#0369A1]">
          Lista de Categorías
        </h2>

        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-slate-700">
            Filtrar:
          </span>

          <select
            value={typeFilter}
            onChange={(e) =>
              setTypeFilter(
                e.target.value
              )
            }
            className={`px-3 py-2 rounded-lg text-sm font-semibold shadow-sm outline-none border-2 bg-white ${isFiltered
                ? 'text-sky-800'
                : 'text-slate-700'
              }`}
            style={{
              borderColor: isFiltered
                ? UI.primary
                : UI.border,
            }}
          >
            {typeOptions.map((opt) => (
              <option
                key={opt.value}
                value={opt.value}
              >
                {opt.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="max-h-[500px] overflow-y-auto overflow-x-auto border border-slate-200 rounded-lg shadow-sm">
        <table className="min-w-full border-collapse text-slate-700 text-sm">
          <thead className="bg-[#E2F3FF] text-left">
            <tr>
              <th className="border border-slate-200 p-3 font-semibold">
                Nombre
              </th>

              <th className="border border-slate-200 p-3 font-semibold">
                Entidad
              </th>

              <th className="border border-slate-200 p-3 font-semibold">
                Tipo negocio
              </th>

              <th className="border border-slate-200 p-3 font-semibold text-center">
                Imagen
              </th>

              <th className="border border-slate-200 p-3 font-semibold text-center">
                Estado
              </th>

              <th className="border border-slate-200 p-3 font-semibold text-center">
                Acciones
              </th>
            </tr>
          </thead>

          <tbody>
            {loading ? (
              <tr>
                <td
                  colSpan={6}
                  className="p-6 text-center text-slate-500"
                >
                  Cargando categorías…
                </td>
              </tr>
            ) : filteredCategories.length ===
              0 ? (
              <tr>
                <td
                  colSpan={6}
                  className="p-6 text-center text-slate-500"
                >
                  No hay categorías.
                </td>
              </tr>
            ) : (
              filteredCategories.map(
                (category, index) => (
                  <CategoryRow
                    key={
                      category.id ??
                      index
                    }
                    category={category}
                    index={index}
                    rowUpdatingId={
                      rowUpdatingId
                    }
                    onEdit={onEdit}
                    onToggleActive={
                      onToggleActive
                    }
                    onDelete={onDelete}
                    isSubmitting={
                      isSubmitting
                    }
                  />
                )
              )
            )}
          </tbody>
        </table>
      </div>
    </>
  );
}