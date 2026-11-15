// File: src/pages/vehicle-types.jsx
'use client';

import { useState } from 'react';
import { FaPlus, FaTrash, FaEdit, FaSave, FaTimes, FaSync } from 'react-icons/fa';
import useVehicleTypes from '@/hooks/useVehicleTypes';
import toast from 'react-hot-toast';

export default function VehicleTypes() {
  const {
    rows, loading, err, savingId,
    search, setSearch,
    fetchAll, create, update, remove,
  } = useVehicleTypes();

  const [newName, setNewName] = useState('');
  const [editId, setEditId] = useState(null);
  const [editName, setEditName] = useState('');

  const startEdit = (row) => {
    setEditId(row.id);
    setEditName(row.name || '');
  };

  const cancelEdit = () => {
    setEditId(null);
    setEditName('');
  };

  const handleReload = async () => {
    try {
      await fetchAll();
      toast.success('Lista de tipos de vehículos actualizada');
    } catch (e) {
      console.error(e);
      toast.error('No se pudo actualizar la lista');
    }
  };

  return (
    <div className="space-y-6">
      {/* 🔹 Header y búsqueda */}
      <div className="flex flex-col md:flex-row gap-3 items-center justify-between">
        <h2 className="text-2xl font-semibold text-[#0077B6] flex-1">
          Tipos de vehículos
        </h2>

        <div className="flex gap-2 items-center">
          {/* buscador con placeholder visible */}
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Buscar por nombre…"
            className="
              w-full md:w-[420px]
              px-3 py-2 rounded-md border
              border-slate-300 bg-white
              text-slate-800
              placeholder:text-slate-500
              focus:outline-none focus:ring-2 focus:ring-[#0077B6]
            "
            aria-label="Buscar tipo de vehículo"
          />

          {/* Recargar con buen contraste */}
          <button
            onClick={handleReload}
            className="
              inline-flex items-center gap-2
              px-3 py-2 rounded-md
              bg-white text-[#0077B6]
              border border-[#0077B6]
              hover:bg-[#E0F4FF]
              active:bg-[#CCE9FF]
              transition
            "
            title="Recargar"
            type="button"
          >
            <FaSync />
            <span className="font-semibold">Recargar</span>
          </button>
        </div>
      </div>

      {/* 🟩 Crear nuevo tipo */}
      <form
        onSubmit={async (e) => {
          e.preventDefault();
          if (!newName.trim()) return;
          await create(newName.trim());
          setNewName('');
        }}
        className="flex flex-wrap items-center gap-2"
      >
        <input
          type="text"
          value={newName}
          onChange={(e) => setNewName(e.target.value)}
          placeholder="Nuevo tipo (p.ej. Minibús)"
          className="
            flex-1 px-3 py-2 rounded-md
            border border-slate-300
            bg-white text-slate-800
            placeholder:text-slate-500
            focus:outline-none focus:ring-2 focus:ring-[#0077B6]
          "
          aria-label="Nuevo tipo de vehículo"
        />
        <button
          type="submit"
          className="
            inline-flex items-center gap-2
            px-4 py-2 rounded-md
            bg-[#16A34A] text-white font-medium
            hover:bg-[#15803D] transition-colors
          "
        >
          <FaPlus /> Añadir
        </button>
      </form>

      {/* 📋 Tabla de resultados */}
      <div className="overflow-x-auto border border-slate-200 rounded-lg shadow-sm bg-white">
        <table className="min-w-full border-collapse">
          <thead className="bg-[#0077B6]">
            <tr>
              <th className="p-3 border border-[#006494] w-24 text-left text-white font-semibold">
                ID
              </th>
              <th className="p-3 border border-[#006494] text-left text-white font-semibold">
                Nombre
              </th>
              <th className="p-3 border border-[#006494] w-40 text-center text-white font-semibold">
                Acciones
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={3} className="p-6 text-center text-slate-500">
                  Cargando…
                </td>
              </tr>
            ) : rows.length === 0 ? (
              <tr>
                <td colSpan={3} className="p-6 text-center text-slate-500">
                  Sin resultados.
                </td>
              </tr>
            ) : (
              rows.map((row, index) => (
                <tr
                  key={row.id}
                  className={`${index % 2 === 0 ? 'bg-[#F8FAFC]' : 'bg-white'
                    } hover:bg-[#E0F2FE] transition-colors`}
                >
                  <td className="p-2 border border-slate-200 text-center font-medium text-slate-700">
                    {row.id}
                  </td>
                  <td className="p-2 border border-slate-200">
                    {editId === row.id ? (
                      <input
                        value={editName}
                        onChange={(e) => setEditName(e.target.value)}
                        className="
                          w-full px-3 py-2
                          rounded-md
                          bg-white text-slate-800
                          border border-slate-300
                          placeholder:text-slate-500
                          focus:outline-none focus:ring-2 focus:ring-[#0077B6]
                        "
                        placeholder="Nombre del tipo"
                        aria-label="Editar nombre de tipo"
                      />
                    ) : (
                      <span className="text-slate-800">{row.name || '—'}</span>
                    )}
                  </td>
                  <td className="p-2 border border-slate-200">
                    <div className="flex items-center justify-center gap-2">
                      {editId === row.id ? (
                        <>
                          <button
                            onClick={async () => {
                              await update(row.id, editName.trim());
                              cancelEdit();
                            }}
                            disabled={savingId === row.id || !editName.trim()}
                            className="
                              p-2 rounded-full
                              bg-green-100 text-green-700
                              hover:bg-green-200
                              disabled:opacity-50
                              transition-colors
                            "
                            title="Guardar"
                            type="button"
                          >
                            <FaSave />
                          </button>
                          <button
                            onClick={cancelEdit}
                            className="
                              p-2 rounded-full
                              bg-slate-100 text-slate-700
                              hover:bg-slate-200
                              transition-colors
                            "
                            title="Cancelar"
                            type="button"
                          >
                            <FaTimes />
                          </button>
                        </>
                      ) : (
                        <>
                          <button
                            onClick={() => startEdit(row)}
                            className="
                              p-2 rounded-full
                              bg-blue-50 text-blue-600
                              hover:bg-blue-100
                              transition-colors
                            "
                            title="Editar"
                            type="button"
                          >
                            <FaEdit />
                          </button>
                          <button
                            onClick={() => remove(row.id)}
                            disabled={savingId === row.id}
                            className="
                              p-2 rounded-full
                              bg-rose-50 text-rose-600
                              hover:bg-rose-100
                              disabled:opacity-50
                              transition-colors
                            "
                            title="Eliminar"
                            type="button"
                          >
                            <FaTrash />
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
