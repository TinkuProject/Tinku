// src/components/Admin/RegisterUser.jsx
'use client';

import React from 'react';
import { motion } from 'framer-motion';
import toast from 'react-hot-toast';
import {
  FaUser,
  FaLock,
  FaEnvelope,
  FaUserShield,
  FaIdBadge,
} from 'react-icons/fa';
import useRegisterForm from '@/hooks/useRegisterForm';
import { registerUser as registerUserService } from '@/services/authService';

const ROLE_OPTIONS = [
  { label: 'Usuario', value: 'user' },
  { label: 'Socio', value: 'partner' },
  { label: 'Administrador', value: 'admin' },
];

export default function RegisterUser({ onClose, onRegistered }) {
  const [role, setRole] = React.useState('user');

  const {
    values,
    errors,
    isSubmitting,
    firstErrorRef,
    handleChange,
    handleSubmit,
    generateUsername,
  } = useRegisterForm({
    onRegister: (payload) =>
      registerUserService({
        ...payload,
        role,
      }),
    onSuccess: () => {
      toast.success('Usuario registrado correctamente');
      onRegistered?.();
      onClose?.();
    },
    onError: (msg) => {
      toast.error(msg || 'No se pudo registrar el usuario');
    },
  });

  const computedUsername = React.useMemo(
    () => generateUsername(values.first_name, values.last_name),
    [generateUsername, values.first_name, values.last_name]
  );

  return (
    <motion.div
      initial={{ opacity: 0, y: 16, scale: 0.98 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{ duration: 0.18 }}
      className="w-full rounded-2xl bg-white shadow-2xl border border-[#CBD5E0]"
    >
      <div className="rounded-t-2xl bg-[#0077B6] px-6 py-4 text-white border-b border-[#005f92]">
        <h2 className="text-center text-xl font-bold">Registrar Usuario</h2>
      </div>

      <form onSubmit={handleSubmit} className="p-6 bg-[#F8F9FA] space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="relative">
            <FaUser className="absolute left-3 top-1/2 -translate-y-1/2 text-[#0077B6]" />
            <input
              ref={firstErrorRef}
              type="text"
              name="first_name"
              placeholder="Nombre"
              value={values.first_name}
              onChange={handleChange}
              required
              className={`w-full pl-10 py-2.5 rounded-lg border bg-white text-sm text-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-[#0077B6] ${errors.first_name ? 'border-red-500' : 'border-[#CBD5E0]'
                }`}
            />
            {errors.first_name && (
              <p className="mt-1 text-xs text-red-600">{errors.first_name}</p>
            )}
          </div>

          <div className="relative">
            <FaUser className="absolute left-3 top-1/2 -translate-y-1/2 text-[#0077B6]" />
            <input
              type="text"
              name="last_name"
              placeholder="Apellidos"
              value={values.last_name}
              onChange={handleChange}
              required
              className={`w-full pl-10 py-2.5 rounded-lg border bg-white text-sm text-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-[#0077B6] ${errors.last_name ? 'border-red-500' : 'border-[#CBD5E0]'
                }`}
            />
            {errors.last_name && (
              <p className="mt-1 text-xs text-red-600">{errors.last_name}</p>
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="relative">
            <FaEnvelope className="absolute left-3 top-1/2 -translate-y-1/2 text-[#0077B6]" />
            <input
              type="email"
              name="email"
              placeholder="Correo Electrónico"
              value={values.email}
              onChange={handleChange}
              required
              className={`w-full pl-10 py-2.5 rounded-lg border bg-white text-sm text-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-[#0077B6] ${errors.email ? 'border-red-500' : 'border-[#CBD5E0]'
                }`}
            />
            {errors.email && (
              <p className="mt-1 text-xs text-red-600">{errors.email}</p>
            )}
          </div>

          <div className="relative">
            <FaIdBadge className="absolute left-3 top-1/2 -translate-y-1/2 text-[#0077B6]" />
            <input
              type="text"
              name="username_display"
              placeholder="Usuario auto-generado"
              value={computedUsername}
              readOnly
              className="w-full pl-10 py-2.5 rounded-lg border border-[#CBD5E0] bg-slate-50 text-sm text-slate-800 shadow-sm"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="relative">
            <FaLock className="absolute left-3 top-1/2 -translate-y-1/2 text-[#0077B6]" />
            <input
              type="password"
              name="password"
              placeholder="Contraseña"
              value={values.password}
              onChange={handleChange}
              required
              className={`w-full pl-10 py-2.5 rounded-lg border bg-white text-sm text-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-[#0077B6] ${errors.password ? 'border-red-500' : 'border-[#CBD5E0]'
                }`}
            />
            {errors.password && (
              <p className="mt-1 text-xs text-red-600">{errors.password}</p>
            )}
          </div>

          <div className="relative">
            <FaLock className="absolute left-3 top-1/2 -translate-y-1/2 text-[#0077B6]" />
            <input
              type="password"
              name="confirmPassword"
              placeholder="Confirmar Contraseña"
              value={values.confirmPassword}
              onChange={handleChange}
              required
              className={`w-full pl-10 py-2.5 rounded-lg border bg-white text-sm text-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-[#0077B6] ${errors.confirmPassword ? 'border-red-500' : 'border-[#CBD5E0]'
                }`}
            />
            {errors.confirmPassword && (
              <p className="mt-1 text-xs text-red-600">
                {errors.confirmPassword}
              </p>
            )}
          </div>
        </div>

        <div className="relative">
          <FaUserShield className="absolute left-3 top-1/2 -translate-y-1/2 text-[#0077B6]" />
          <select
            value={role}
            onChange={(e) => setRole(e.target.value)}
            className="w-full pl-10 py-2.5 rounded-lg border border-[#CBD5E0] bg-white text-sm text-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
          >
            {ROLE_OPTIONS.map((r) => (
              <option key={r.value} value={r.value}>
                {r.label}
              </option>
            ))}
          </select>
        </div>

        <div className="mt-2 flex gap-3">
          <button
            type="submit"
            disabled={isSubmitting}
            className="flex-1 rounded-lg bg-[#4BAC5E] py-2.5 font-semibold text-white shadow-md transition hover:bg-[#3d8c4e] disabled:cursor-not-allowed disabled:opacity-60"
          >
            {isSubmitting ? 'Registrando…' : 'Registrar'}
          </button>

          <button
            type="button"
            onClick={() => onClose?.()}
            className="flex-1 rounded-lg bg-slate-200 py-2.5 font-semibold text-slate-800 transition hover:bg-slate-300"
          >
            Cancelar
          </button>
        </div>
      </form>
    </motion.div>
  );
}