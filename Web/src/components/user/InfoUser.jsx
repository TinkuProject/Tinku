'use client';
import { useMemo, useState } from 'react';
import { useUser } from '../../context/UserContext';
import EditUser from './EditUser';

export default function InfoUser() {
  const { user } = useUser();
  const [showEdit, setShowEdit] = useState(false);

  if (!user?.id) {
    return (
      <p className="p-10 text-center text-gray-500 italic">Cargando usuario...</p>
    );
  }

  return (
    <div className="max-w-3xl mx-auto mt-8">
      {!showEdit ? (
        <div className="p-6 bg-white rounded-2xl shadow-sm border border-slate-200">
          {/* Header con avatar + nombre */}
          <HeaderCard user={user} onEdit={() => setShowEdit(true)} />

          {/* Grid de info */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6">
            <InfoField label="Nombre" value={user.first_name} />
            <InfoField label="Apellido" value={user.last_name} />
            <InfoField label="Usuario" value={user.username} />
            <InfoField label="Email" value={user.email} />
            <InfoField label="Teléfono" value={user.phone} />
            <InfoField label="C.I." value={user.ci} />
            <InfoField className="md:col-span-2" label="Dirección" value={user.address} />
          </div>
        </div>
      ) : (
        <EditUser onClose={() => setShowEdit(false)} />
      )}
    </div>
  );
}

/* ---------- Subcomponentes ---------- */

function HeaderCard({ user, onEdit }) {
  const displayName = useMemo(() => {
    const base =
      user?.username ||
      [user?.first_name, user?.last_name].filter(Boolean).join(' ') ||
      user?.email ||
      'Usuario';
    return base.trim();
  }, [user]);

  const initials = useMemo(() => {
    const parts = displayName.split(' ').filter(Boolean);
    return (parts[0]?.[0] || '').toUpperCase() + (parts[1]?.[0] || '').toUpperCase();
  }, [displayName]);

  const role = (user?.user_type || '').toString();

  return (
    <div className="flex items-center gap-5">
      {/* Avatar: si hay foto la usamos, si no, círculo con iniciales */}
      <div className="relative w-24 h-24 shrink-0">
        {user?.photo ? (
          <img
            src={user.photo}
            alt="Foto de perfil"
            className="w-24 h-24 rounded-full object-cover border-2 border-[#0077B6]/40 shadow-sm"
          />
        ) : (
          <div className="w-24 h-24 rounded-full bg-[#0077B6]/10 text-[#0077B6] flex items-center justify-center text-2xl font-semibold border border-[#0077B6]/20">
            {initials || 'U'}
          </div>
        )}
      </div>

      <div className="flex-1">
        <h2 className="text-2xl font-semibold text-slate-800">{displayName}</h2>
        <div className="mt-1 flex flex-wrap items-center gap-2">
          {role && (
            <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-[#0077B6]/10 text-[#0077B6] capitalize">
              {role}
            </span>
          )}
          {user?.email && (
            <span className="text-sm text-slate-600">{user.email}</span>
          )}
        </div>
      </div>

      <div className="ml-auto">
        <button
          onClick={onEdit}
          className="px-6 py-2 bg-[#0077B6] text-white font-semibold rounded-lg hover:bg-[#005F92] active:scale-95 transition"
          title="Editar perfil"
        >
          Editar
        </button>
      </div>
    </div>
  );
}

function InfoField({ label, value, className = '' }) {
  return (
    <div className={`p-4 bg-slate-50 rounded-lg border border-slate-200 ${className}`}>
      <span className="block text-xs font-semibold text-slate-500 mb-1">
        {label}
      </span>
      <span className="text-slate-800 font-medium">{value || '—'}</span>
    </div>
  );
}
