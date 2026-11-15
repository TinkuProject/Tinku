// src/components/User/User.jsx
'use client';

import React, { useMemo, useState } from 'react';
import {
  FaSync,
  FaChevronLeft,
  FaChevronRight,
  FaSearch,
} from 'react-icons/fa';

import RegisterUser from '../Admin/RegisterUser';
import useUsers, { PAGE_SIZE } from '@/hooks/useUsers';

const ROLE_LABEL = {
  user: 'Usuario',
  partner: 'Socio',
  admin: 'Administrador',
  master: 'Master',
};

function isActiveStatus(status) {
  return status === 'active' || status === 1 || status === true;
}

export default function User() {
  const {
    filteredUsers,
    pageRows,
    loading,
    err,


    searchText,
    setSearchText,
    roleFilter,
    setRoleFilter,
    statusFilter,
    setStatusFilter,

    currentPage,
    totalPages,
    goToPage,
    prevPage,
    nextPage,
    fetchUsers,
  } = useUsers();

  const [showModal, setShowModal] = useState(false);

  const columns = useMemo(
    () => [
      { key: 'first_name', label: 'Nombre' },
      { key: 'last_name', label: 'Apellido' },
      { key: 'email', label: 'Correo' },
      { key: 'phone', label: 'Teléfono' },
      { key: 'role', label: 'Rol' },
      { key: 'status', label: 'Estado' },
    ],
    []
  );

  return (
    <div className="p-4 md:p-6 lg:p-10 bg-[#F8F9FA] shadow-md rounded-lg overflow-x-auto">
      <div className="min-w-[1024px]">
        <div className="flex items-center gap-3 mb-6">
          <h1 className="text-3xl font-bold text-[#0077B6] flex-1">
            Gestión de Usuarios
          </h1>

          <button
            type="button"
            onClick={() => fetchUsers({ notify: true })}
            disabled={loading}
            className="flex items-center gap-2 bg-slate-200 text-slate-800 px-3 py-2 rounded-md hover:bg-slate-300 transition disabled:opacity-60 disabled:cursor-not-allowed"
            title="Recargar"
          >
            <FaSync className={loading ? 'animate-spin' : ''} />
            Recargar
          </button>

          <button
            type="button"
            onClick={() => setShowModal(true)}
            className="bg-[#0077B6] text-white px-4 py-2 rounded-md hover:bg-[#005f92] transition font-semibold"
          >
            Crear Usuario
          </button>
        </div>

        <div className="mb-4 grid grid-cols-1 md:grid-cols-3 gap-3">
          <div className="relative">
            <FaSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
            <input
              type="text"
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              placeholder="Buscar por nombre, apellido, correo, teléfono…"
              className="w-full pl-10 pr-3 py-2 rounded-md border border-slate-300 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
            />
          </div>

          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="w-full px-3 py-2 rounded-md border border-slate-300 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
          >
            <option value="all">Todos los roles</option>
            <option value="user">Usuario</option>
            <option value="partner">Socio</option>
            <option value="admin">Administrador</option>
            <option value="master">Master</option>
          </select>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="w-full px-3 py-2 rounded-md border border-slate-300 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
          >
            <option value="all">Todos los estados</option>
            <option value="active">Activos</option>
            <option value="inactive">Inactivos</option>
          </select>
        </div>

        {err && <p className="mb-3 text-sm text-red-600">{err}</p>}

        {loading ? (
          <div className="py-10 text-center text-slate-500">
            Cargando usuarios…
          </div>
        ) : filteredUsers.length === 0 ? (
          <div className="py-10 text-center text-slate-500">
            No hay usuarios que coincidan.
          </div>
        ) : (
          <>
            <div className="border border-[#CBD5E0] rounded-md overflow-x-auto">
              <div className="max-h-[60vh] overflow-y-auto">
                <table className="min-w-[900px] md:min-w-full border-collapse">
                  <thead className="bg-[#E2E8F0] text-[#2D3748] font-semibold">
                    <tr>
                      {columns.map((c) => (
                        <th key={c.key} className="p-3 border border-[#CBD5E0]">
                          {c.label}
                        </th>
                      ))}
                    </tr>
                  </thead>

                  <tbody>
                    {pageRows.map((u) => {
                      const role = u.role || u.user_type || '—';
                      const isActive = isActiveStatus(u.status);

                      return (
                        <tr
                          key={u.id}
                          className="hover:bg-[#FFD70033] text-[#2D3748]"
                        >
                          <td className="p-2 border border-[#CBD5E0]">
                            {u.first_name || '—'}
                          </td>

                          <td className="p-2 border border-[#CBD5E0]">
                            {u.last_name || '—'}
                          </td>

                          <td className="p-2 border border-[#CBD5E0]">
                            {u.email || '—'}
                          </td>

                          <td className="p-2 border border-[#CBD5E0]">
                            {u.phone || '—'}
                          </td>

                          <td className="p-2 border border-[#CBD5E0]">
                            {ROLE_LABEL[role] || role}
                          </td>

                          <td className="p-2 border border-[#CBD5E0]">
                            <span
                              className={`px-2 py-1 rounded-full text-xs font-medium ${isActive
                                ? 'bg-green-100 text-green-700'
                                : 'bg-red-100 text-red-600'
                                }`}
                            >
                              {isActive ? 'Activo' : 'Inactivo'}
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="mt-4 flex flex-col md:flex-row items-center justify-between gap-3">
              <span className="text-sm text-slate-600">
                Mostrando{' '}
                <b>
                  {(currentPage - 1) * PAGE_SIZE + 1} –{' '}
                  {Math.min(currentPage * PAGE_SIZE, filteredUsers.length)}
                </b>{' '}
                de <b>{filteredUsers.length}</b>
              </span>

              <div className="flex items-center gap-1">
                <button
                  type="button"
                  onClick={prevPage}
                  disabled={currentPage === 1}
                  className="inline-flex items-center gap-2 px-3 py-2 rounded-md bg-[#0077B6] text-white hover:bg-[#005f92] disabled:bg-gray-300 disabled:cursor-not-allowed transition"
                >
                  <FaChevronLeft /> Anterior
                </button>

                {Array.from({ length: totalPages }, (_, i) => i + 1)
                  .slice(
                    Math.max(0, currentPage - 3),
                    Math.max(0, currentPage - 3) + 5
                  )
                  .map((p) => (
                    <button
                      key={p}
                      type="button"
                      onClick={() => goToPage(p)}
                      className={`px-3 py-2 rounded-md font-semibold border transition ${p === currentPage
                        ? 'bg-[#4BAC5E] text-white border-[#4BAC5E]'
                        : 'bg-white text-[#0077B6] border-[#0077B6] hover:bg-[#E0F4FF]'
                        }`}
                    >
                      {p}
                    </button>
                  ))}

                <button
                  type="button"
                  onClick={nextPage}
                  disabled={currentPage === totalPages}
                  className="inline-flex items-center gap-2 px-3 py-2 rounded-md bg-[#0077B6] text-white hover:bg-[#005f92] disabled:bg-gray-300 disabled:cursor-not-allowed transition"
                >
                  Siguiente <FaChevronRight />
                </button>
              </div>
            </div>
          </>
        )}

        {showModal && (
          <div className="fixed inset-0 bg-black/40 flex justify-center items-center z-50 p-4">
            <div className="bg-white rounded-2xl shadow-2xl w-full max-w-3xl">
              <RegisterUser
                onClose={() => setShowModal(false)}
                onRegistered={() => fetchUsers({ notify: true })}
              />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}