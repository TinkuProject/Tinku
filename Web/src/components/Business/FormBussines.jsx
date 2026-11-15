// src/components/Business/FormBussines.jsx
'use client';

import { useEffect, useState } from 'react';
import MapPicker from '@/components/Business/MapPicker';

export default function BusinessForm({
  formData,
  isSubmitting,
  errorMsg,
  onChange,
  onSubmit,
  onCancel, // opcional
  categoryOptions = [],
  businessTypes = [
    { value: 'business', label: 'Negocio' },
    { value: 'service', label: 'Servicio' },
  ],

  // imágenes controladas por el padre
  files = [],
  onFilesChange = () => { },
}) {
  // Previews confiables con cleanup
  const [previews, setPreviews] = useState([]);

  useEffect(() => {
    const urls = (files || []).map((f) => ({
      name: f.name,
      url: URL.createObjectURL(f),
      size: f.size,
      type: f.type,
    }));
    setPreviews(urls);

    return () => {
      urls.forEach((u) => URL.revokeObjectURL(u.url));
    };
  }, [files]);

  const handleFileInput = (e) => {
    const list = Array.from(e.target.files || []);
    if (list.length === 0) return;

    // filtro básico
    const ALLOWED = new Set(['image/jpeg', 'image/png', 'image/webp']);
    const MAX = 10 * 1024 * 1024;

    const ok = list.filter(f => ALLOWED.has(f.type) && f.size <= MAX);
    onFilesChange([...(files || []), ...ok]);

    // reset para permitir volver a seleccionar las mismas
    e.target.value = '';
  };

  const removeAt = (idx) => {
    const copy = [...files];
    copy.splice(idx, 1);
    onFilesChange(copy);
  };

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <div className="space-y-6 max-h-[70vh] overflow-y-auto pr-1">
        {/* Fila 1: Tipo de negocio / Categoría / Nombre */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Tipo de negocio
            </label>
            <select
              name="business_type"
              value={formData.business_type}
              onChange={onChange}
              className="w-full border border-slate-300 p-3 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            >
              {businessTypes.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Categoría *
            </label>
            <select
              name="category_id"
              value={formData.category_id ?? ''}
              onChange={onChange}
              required
              className="w-full border border-slate-300 p-3 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            >
              <option value="" disabled>
                Selecciona una categoría…
              </option>
              {categoryOptions.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Nombre *
            </label>
            <input
              type="text"
              name="name"
              placeholder="Ej. Café Andino"
              value={formData.name}
              onChange={onChange}
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
              required
            />
          </div>
        </div>

        {/* Fila 2: NIT / Email / Teléfono */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              NIT
            </label>
            <input
              type="text"
              name="nit"
              placeholder="Opcional"
              value={formData.nit}
              onChange={onChange}
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Email
            </label>
            <input
              type="email"
              name="email"
              placeholder="correo@dominio.com"
              value={formData.email}
              onChange={onChange}
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Teléfono
            </label>
            <input
              type="text"
              name="phone"
              placeholder="+591..."
              value={formData.phone}
              onChange={onChange}
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            />
          </div>
        </div>

        {/* Mapa */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <label className="block text-sm font-medium text-slate-700">
              Selecciona ubicación en el mapa
            </label>
            <span className="text-xs text-slate-500">
              Tip: arrastra el marcador o haz clic en el mapa
            </span>
          </div>

          <MapPicker
            value={{
              lat: Number(formData.location?.latitude) || -17.3895,
              lng: Number(formData.location?.longitude) || -66.1568,
              address: formData.address || '',
            }}
            onChange={({ lat, lng, address }) => {
              onChange({
                target: {
                  name: 'location',
                  value: {
                    latitude: lat,
                    longitude: lng,
                  },
                },
              });

              onChange({
                target: {
                  name: 'address',
                  value: address,
                },
              });
            }}
          />
        </div>

        {/* Website */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
          <div className="sm:col-span-1">
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Website
            </label>
            <input
              type="text"
              name="website"
              placeholder="https://..."
              value={formData.website}
              onChange={onChange}
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            />
          </div>
        </div>

        {/* Descripción */}
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">
            Descripción
          </label>
          <textarea
            name="description"
            rows={3}
            placeholder="Breve descripción del negocio…"
            value={formData.description}
            onChange={onChange}
            className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
          />
        </div>

        {/* 📸 Imágenes */}
        <div className="space-y-2">
          <label
            htmlFor="business-images"
            className="block text-sm font-medium text-slate-700"
          >
            Imágenes (múltiples)
          </label>

          <input
            id="business-images"
            type="file"
            multiple
            accept="image/png,image/jpeg,image/webp"
            onChange={handleFileInput}
            className="hidden"
          />

          <label
            htmlFor="business-images"
            className="block border border-dashed border-slate-300 rounded-lg p-5 text-center cursor-pointer hover:border-[#0077B6]"
          >
            <div>
              <p className="text-slate-700 font-medium">
                Haz clic para seleccionar imágenes
              </p>
              <p className="text-slate-500 text-sm">
                PNG/JPG/WEBP — máx. 10MB c/u
              </p>
              {files?.length > 0 && (
                <p className="text-slate-500 text-xs mt-1">
                  Seleccionadas: {files.length}
                </p>
              )}
            </div>
          </label>

          {previews.length > 0 && (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
              {previews.map((p, idx) => (
                <div key={`${p.url}-${idx}`} className="relative group">
                  <img
                    src={p.url}
                    alt={p.name}
                    className="w-full h-28 object-cover rounded-md border border-slate-200"
                  />
                  <button
                    type="button"
                    onClick={() => removeAt(idx)}
                    className="absolute top-1 right-1 bg-red-600 text-white text-xs px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition"
                  >
                    Quitar
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        {errorMsg && <p className="text-sm text-red-600">{errorMsg}</p>}
      </div>
    </form>
  );

}
