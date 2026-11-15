// File: src/components/Tag/TagForm.jsx
'use client';

import { useEffect, useState } from 'react';

const UI = { primary: '#0077B6', border: '#E2E8F0' };

export default function TagForm({
  initialValue,
  onSubmit,
  onCancel,
  isSubmitting = false,
  errorMsg = '',
}) {
  const [form, setForm] = useState({
    name: '',
    description: '',
    status: 'active',
  });

  useEffect(() => {
    setForm({
      name: initialValue?.name ?? '',
      description: initialValue?.description ?? '',
      status: initialValue?.status ?? 'active',
    });
  }, [initialValue]);

  const change = (e) => {
    const { name, value } = e.target;

    setForm((f) => ({
      ...f,
      [name]: value,
    }));
  };

  const submit = (e) => {
    e.preventDefault();

    const name = String(form.name || '').trim();
    const description = String(form.description || '').trim();

    if (!name) {
      alert('Ingresa un nombre.');
      return;
    }

    onSubmit?.({
      name,
      description: description === '' ? null : description,
      status: form.status || 'active',
    });
  };

  return (
    <form onSubmit={submit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-slate-700 mb-1">
          Nombre
        </label>

        <input
          name="name"
          value={form.name}
          onChange={change}
          className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
          placeholder="Ej. Patrimonio, Mirador, Iglesia…"
          required
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-slate-700 mb-1">
          Descripción
        </label>

        <textarea
          name="description"
          rows={3}
          value={form.description}
          onChange={change}
          className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
          placeholder="Breve descripción del tag…"
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-slate-700 mb-1">
          Estado
        </label>

        <select
          name="status"
          value={form.status}
          onChange={change}
          className="w-full border border-slate-300 p-3 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
        >
          <option value="active">Activo</option>
          <option value="inactive">Inactivo</option>
          <option value="archived">Archivado</option>
        </select>
      </div>

      {errorMsg && <p className="text-sm text-rose-600">{errorMsg}</p>}

      <div className="flex justify-end gap-2 pt-1">
        <button
          type="button"
          onClick={onCancel}
          className="px-6 py-2 rounded-md font-semibold border bg-white text-slate-900 hover:bg-[#F2F4F7]"
          style={{ borderColor: UI.border }}
          disabled={isSubmitting}
        >
          Cancelar
        </button>

        <button
          type="submit"
          className="px-6 py-2 rounded-md font-semibold text-white disabled:opacity-60"
          disabled={isSubmitting || !form.name}
          style={{ background: UI.primary }}
        >
          {isSubmitting ? 'Guardando…' : 'Guardar'}
        </button>
      </div>
    </form>
  );
}