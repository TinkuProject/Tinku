// src/components/Admin/UpdateUser.jsx
'use client';

import React, { useMemo, useRef, useState } from 'react';
import { motion } from 'framer-motion';
import { FaUser, FaEnvelope, FaIdBadge } from 'react-icons/fa';
import toast from 'react-hot-toast';
import { updateUser } from '@/services/usersService';

const isRequired = (v) => String(v ?? '').trim().length > 0;

function validateUpdate(values) {
    const errors = {};

    if (!isRequired(values.first_name)) {
        errors.first_name = 'El nombre es obligatorio';
    }

    if (!isRequired(values.last_name)) {
        errors.last_name = 'Los apellidos son obligatorios';
    }

    return errors;
}

export default function UpdateUser({ user, onClose, onUpdated }) {
    if (!user) return null;

    const [values, setValues] = useState({
        first_name: user.first_name || '',
        last_name: user.last_name || '',
        email: user.email || '',
    });

    const [errors, setErrors] = useState({});
    const [isSubmitting, setIsSubmitting] = useState(false);
    const firstErrorRef = useRef(null);

    const usernameDisplay = useMemo(() => {
        return (
            user.username ||
            `${(user.first_name || '').toLowerCase()}${(user.last_name || '').toLowerCase()}`
                .replace(/\s+/g, '')
                .slice(0, 20)
        );
    }, [user.username, user.first_name, user.last_name]);

    const handleChange = (e) => {
        const { name, value } = e.target;

        setErrors((prev) => ({
            ...prev,
            [name]: undefined,
        }));

        setValues((prev) => ({
            ...prev,
            [name]: value,
        }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        if (isSubmitting) return;

        const vErrors = validateUpdate(values);

        if (Object.keys(vErrors).length > 0) {
            setErrors(vErrors);
            firstErrorRef.current?.focus?.();
            return;
        }

        try {
            setIsSubmitting(true);

            await updateUser(user.id, {
                first_name: values.first_name.trim(),
                last_name: values.last_name.trim(),
            });

            toast.success('Usuario actualizado');

            onUpdated?.();
            onClose?.();
        } catch (err) {
            toast.error(err?.message || 'No se pudo actualizar el usuario');
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/15 p-4">
            <motion.div
                initial={{
                    opacity: 0,
                    y: 16,
                    scale: 0.98,
                }}
                animate={{
                    opacity: 1,
                    y: 0,
                    scale: 1,
                }}
                transition={{ duration: 0.18 }}
                className="max-w-3xl rounded-2xl bg-white shadow-2xl ring-1 ring-slate-200"
                role="dialog"
                aria-modal="true"
            >
                <div className="rounded-t-2xl bg-gradient-to-r from-[#0077B6] to-[#00B4D8] px-6 py-4 text-white">
                    <h2 className="text-center text-xl font-bold">
                        Actualizar Usuario
                    </h2>
                </div>

                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    {/* NOMBRES */}
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
                                className={`w-full pl-10 py-2.5 rounded-xl border bg-white text-sm text-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-[#0077B6] ${errors.first_name ? 'border-red-500' : 'border-slate-300'
                                    }`}
                            />

                            {errors.first_name && (
                                <p className="mt-1 text-xs text-red-600">
                                    {errors.first_name}
                                </p>
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
                                className={`w-full pl-10 py-2.5 rounded-xl border bg-white text-sm text-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-[#0077B6] ${errors.last_name ? 'border-red-500' : 'border-slate-300'
                                    }`}
                            />

                            {errors.last_name && (
                                <p className="mt-1 text-xs text-red-600">
                                    {errors.last_name}
                                </p>
                            )}
                        </div>
                    </div>

                    {/* EMAIL + USERNAME SOLO LECTURA */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="relative">
                            <FaEnvelope className="absolute left-3 top-1/2 -translate-y-1/2 text-[#0077B6]" />

                            <input
                                type="email"
                                name="email"
                                placeholder="Correo"
                                value={values.email}
                                readOnly
                                className="w-full pl-10 py-2.5 rounded-xl border border-slate-300 bg-slate-50 text-sm text-slate-700 shadow-sm cursor-not-allowed"
                            />

                            <p className="mt-1 text-xs text-slate-500">
                                El correo no se modifica desde este formulario.
                            </p>
                        </div>

                        <div className="relative">
                            <FaIdBadge className="absolute left-3 top-1/2 -translate-y-1/2 text-[#0077B6]" />

                            <input
                                type="text"
                                value={usernameDisplay}
                                readOnly
                                className="w-full pl-10 py-2.5 rounded-xl border border-slate-300 bg-slate-50 text-sm text-slate-800 shadow-sm cursor-not-allowed"
                            />

                            <p className="mt-1 text-xs text-slate-500">
                                El usuario es solo informativo.
                            </p>
                        </div>
                    </div>

                    {/* ACCIONES */}
                    <div className="mt-2 flex gap-3">
                        <button
                            type="submit"
                            disabled={isSubmitting}
                            className="flex-1 rounded-xl bg-[#4BAC5E] py-2.5 font-semibold text-white shadow-md transition hover:bg-[#3d8c4e] disabled:cursor-not-allowed disabled:opacity-60"
                        >
                            {isSubmitting ? 'Guardando…' : 'Guardar cambios'}
                        </button>

                        <button
                            type="button"
                            onClick={() => onClose?.()}
                            disabled={isSubmitting}
                            className="flex-1 rounded-xl bg-slate-200 py-2.5 font-semibold text-slate-800 transition hover:bg-slate-300 disabled:opacity-60"
                        >
                            Cancelar
                        </button>
                    </div>
                </form>
            </motion.div>
        </div>
    );
}