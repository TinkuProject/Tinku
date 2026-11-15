'use client';

import { useState } from 'react';
import {
    FaEdit,
    FaPlus,
    FaSearch,
    FaSyncAlt,
    FaTimes,
} from 'react-icons/fa';
import toast from 'react-hot-toast';

import useSystemConfig from '@/hooks/useSystemConfig';
import FormSystemConfig from '@/components/SystemConfig/FormSystemConfig';

const UI = {
    primary: '#0077B6',
    border: '#E2E8F0',
};

const initialForm = {
    key: '',
    value: '',
    description: '',
};

function formatDate(value) {
    if (!value) return '—';

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) return '—';

    return new Intl.DateTimeFormat('es-BO', {
        dateStyle: 'short',
        timeStyle: 'short',
    }).format(date);
}

export default function SystemConfigManager() {
    const {
        rows,
        loading,
        err,
        savingKey,
        search,
        setSearch,
        fetchAll,
        save,
    } = useSystemConfig();

    const [isModalOpen, setIsModalOpen] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
    const [form, setForm] = useState(initialForm);
    const [formError, setFormError] = useState('');

    const closeModal = () => {
        if (savingKey) return;

        setIsModalOpen(false);
        setFormError('');
        setForm(initialForm);
    };

    const openCreate = () => {
        setIsEditing(false);
        setForm(initialForm);
        setFormError('');
        setIsModalOpen(true);
    };

    const openEdit = (config) => {
        setIsEditing(true);
        setForm({
            key: config.key || '',
            value: config.value ?? '',
            description: config.description ?? '',
        });
        setFormError('');
        setIsModalOpen(true);
    };

    const handleChange = (event) => {
        const { name, value } = event.target;

        setForm((previous) => ({
            ...previous,
            [name]: value,
        }));
    };

    const handleSubmit = async (event) => {
        event.preventDefault();
        setFormError('');

        const key = String(form.key || '').trim();
        const value = String(form.value ?? '');

        if (!key) {
            setFormError('La clave es obligatoria.');
            return;
        }

        if (!value.trim()) {
            setFormError('El valor es obligatorio.');
            return;
        }

        const result = await save(key, {
            value,
            description: form.description.trim() || null,
        });

        if (!result) return;

        setIsModalOpen(false);
        setForm(initialForm);
    };

    const handleReload = async () => {
        try {
            await fetchAll();
            toast.success('Configuraciones actualizadas');
        } catch (error) {
            console.error(error);
            toast.error('No se pudieron actualizar las configuraciones');
        }
    };

    return (
        <div className="p-0">
            <div
                className="bg-white rounded-xl shadow-md border p-5 space-y-4"
                style={{ borderColor: UI.border }}
            >
                <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
                    <div>
                        <h1
                            className="text-3xl font-bold"
                            style={{ color: UI.primary }}
                        >
                            Configuraciones del sistema
                        </h1>

                        <p className="text-sm text-slate-600">
                            Administra los valores globales utilizados por la plataforma.
                        </p>
                    </div>

                    <button
                        type="button"
                        onClick={openCreate}
                        className="inline-flex items-center gap-2 px-4 py-2 rounded-lg text-white font-semibold"
                        style={{ background: UI.primary }}
                    >
                        <FaPlus />
                        Nueva configuración
                    </button>
                </div>

                <div className="flex flex-wrap items-center gap-3 justify-between">
                    <div className="flex-1 min-w-[260px] max-w-2xl">
                        <div className="relative">
                            <FaSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />

                            <input
                                value={search}
                                onChange={(event) => setSearch(event.target.value)}
                                placeholder="Buscar por clave, valor o descripción…"
                                className="w-full pl-10 pr-3 py-2 text-sm rounded-lg border bg-white outline-none
                  text-slate-900 placeholder:text-slate-400
                  focus:ring-2 focus:ring-[#0077B6]/30 focus:border-[#0077B6]"
                                style={{ borderColor: UI.border, boxShadow: 'none' }}
                            />
                        </div>
                    </div>

                    <button
                        type="button"
                        onClick={handleReload}
                        disabled={loading}
                        className="inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold border
              bg-[#EFF4FB] text-slate-800 hover:bg-[#E7EEF9] transition text-sm disabled:opacity-60"
                        style={{ borderColor: UI.border }}
                    >
                        <FaSyncAlt className={loading ? 'animate-spin opacity-70' : 'opacity-70'} />
                        Recargar
                    </button>
                </div>

                {err && (
                    <div className="px-3 py-2 rounded-md bg-red-50 text-red-700 border border-red-200 text-sm">
                        {err}
                    </div>
                )}

                <div
                    className="overflow-x-auto border rounded-lg"
                    style={{ borderColor: UI.border }}
                >
                    <table className="min-w-full text-sm">
                        <thead className="bg-slate-50 text-slate-700">
                            <tr>
                                <th className="px-4 py-3 text-left font-semibold">Clave</th>
                                <th className="px-4 py-3 text-left font-semibold">Valor</th>
                                <th className="px-4 py-3 text-left font-semibold">Descripción</th>
                                <th className="px-4 py-3 text-left font-semibold">Actualizado</th>
                                <th className="px-4 py-3 text-right font-semibold">Acciones</th>
                            </tr>
                        </thead>

                        <tbody className="divide-y divide-slate-100">
                            {loading && rows.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="px-4 py-8 text-center text-slate-500">
                                        Cargando configuraciones…
                                    </td>
                                </tr>
                            ) : rows.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="px-4 py-8 text-center text-slate-500">
                                        No hay configuraciones que coincidan con tu búsqueda.
                                    </td>
                                </tr>
                            ) : (
                                rows.map((config) => (
                                    <tr key={config.key} className="hover:bg-slate-50/70">
                                        <td className="px-4 py-3 font-mono text-xs font-semibold text-slate-800">
                                            {config.key}
                                        </td>

                                        <td className="px-4 py-3 text-slate-900 break-all">
                                            {config.value}
                                        </td>

                                        <td className="px-4 py-3 text-slate-600 max-w-md">
                                            {config.description || '—'}
                                        </td>

                                        <td className="px-4 py-3 text-slate-500 whitespace-nowrap">
                                            {formatDate(config.updated_at)}
                                        </td>

                                        <td className="px-4 py-3 text-right">
                                            <button
                                                type="button"
                                                onClick={() => openEdit(config)}
                                                className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg
                          bg-sky-50 text-sky-700 border border-sky-200 hover:bg-sky-100"
                                            >
                                                <FaEdit />
                                                Editar
                                            </button>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
                    <div className="bg-white rounded-xl shadow-xl max-w-xl w-full p-6">
                        <div className="flex items-start justify-between gap-4 mb-5">
                            <div>
                                <h2 className="text-lg font-semibold text-slate-900">
                                    {isEditing
                                        ? 'Editar configuración'
                                        : 'Nueva configuración'}
                                </h2>

                                <p className="text-xs text-slate-500">
                                    {isEditing
                                        ? 'Actualiza el valor o la descripción de esta clave.'
                                        : 'Registra una nueva configuración global.'}
                                </p>
                            </div>

                            <button
                                type="button"
                                onClick={closeModal}
                                disabled={Boolean(savingKey)}
                                className="p-2 rounded-full hover:bg-slate-100 text-slate-500 disabled:opacity-60"
                                aria-label="Cerrar"
                            >
                                <FaTimes />
                            </button>
                        </div>

                        <FormSystemConfig
                            formData={form}
                            isEditing={isEditing}
                            isSubmitting={Boolean(savingKey)}
                            errorMsg={formError}
                            onChange={handleChange}
                            onSubmit={handleSubmit}
                            onCancel={closeModal}
                        />
                    </div>
                </div>
            )}
        </div>
    );
}