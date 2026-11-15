// src/components/Events/FormEvent.jsx
'use client';

import { useEffect, useState } from 'react';
import MapPicker from '@/components/Business/MapPicker';

export default function FormEvent({
  formData,
  isSubmitting,
  errorMsg,
  onChange,
  onSubmit,
  onCancel,
  categoryOptions = [],
  files = [],
  onFilesChange = () => { },
  showStatus = false,
  existingImageUrls = [],
  onExistingImageUrlsChange = () => { },
}) {
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
    if (!list.length) return;

    const ALLOWED = new Set(['image/jpeg', 'image/png', 'image/webp']);
    const MAX = 10 * 1024 * 1024;

    const ok = list.filter((f) => ALLOWED.has(f.type) && f.size <= MAX);

    onFilesChange([...(files || []), ...ok]);
    e.target.value = '';
  };

  const removeNewAt = (idx) => {
    const copy = [...files];
    copy.splice(idx, 1);
    onFilesChange(copy);
  };

  const removeExistingAt = (idx) => {
    const copy = [...(existingImageUrls || [])];
    copy.splice(idx, 1);
    onExistingImageUrlsChange(copy);
  };

  const toLocalInputValue = (v) => (v ? String(v).slice(0, 16) : '');

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <div className="space-y-6 max-h-[70vh] overflow-y-auto pr-1">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Empresa
            </label>

            <input
              type="text"
              name="business_name"
              value={formData.business_name || ''}
              className="w-full border rounded-lg px-3 py-2 text-sm text-black"
              disabled
              readOnly
            />

            <input
              type="hidden"
              name="business_id"
              value={formData.business_id ?? ''}
            />
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
              Nombre del evento *
            </label>

            <input
              type="text"
              name="name"
              placeholder="Ej. Tinku Music Fest"
              value={formData.name || ''}
              onChange={onChange}
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
              required
            />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-4 gap-6">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Fecha y hora de inicio *
            </label>

            <input
              type="datetime-local"
              name="start_date"
              value={toLocalInputValue(formData.start_date)}
              onChange={onChange}
              required
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Fecha y hora de fin *
            </label>

            <input
              type="datetime-local"
              name="end_date"
              value={toLocalInputValue(formData.end_date)}
              onChange={onChange}
              required
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Capacidad
            </label>

            <input
              type="number"
              min={0}
              name="capacity"
              placeholder="Ej. 150"
              value={formData.capacity ?? ''}
              onChange={onChange}
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Precio en Tinkus
            </label>

            <input
              type="number"
              min={0}
              name="tinku_price"
              placeholder="Ej. 50"
              value={formData.tinku_price ?? ''}
              onChange={onChange}
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            />
          </div>
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <label className="block text-sm font-medium text-slate-700">
              Ubicación del evento en el mapa
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
            height={300}
            scrollWheelZoom={false}
          />
        </div>


        {showStatus && (
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Estado del evento
              </label>

              <select
                name="status"
                value={formData.status || 'pending'}
                onChange={onChange}
                className="w-full border border-slate-300 p-3 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
              >
                <option value="pending">Pendiente</option>
                <option value="active">Activo</option>
                <option value="finished">Finalizado</option>
                <option value="cancelled">Cancelado</option>
              </select>
            </div>
          </div>
        )}

        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">
            Descripción del evento
          </label>

          <textarea
            name="description"
            rows={3}
            placeholder="Breve descripción del evento…"
            value={formData.description || ''}
            onChange={onChange}
            className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
          />
        </div>

        <div className="space-y-3">
          <label className="block text-sm font-medium text-slate-700">
            Imágenes del evento
          </label>

          {existingImageUrls?.length > 0 && (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3 mb-2">
              {existingImageUrls.map((item, idx) => {
                const url = typeof item === 'string' ? item : item.url;

                return (
                  <div key={`${url}-${idx}`} className="relative group">
                    <img
                      src={url}
                      alt={`Imagen ${idx + 1}`}
                      className="w-full h-28 object-cover rounded-md border border-slate-200"
                    />

                    <button
                      type="button"
                      onClick={() => removeExistingAt(idx)}
                      className="absolute top-1 right-1 bg-red-600 text-white text-xs px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition"
                    >
                      Quitar
                    </button>
                  </div>
                );
              })}
            </div>
          )}

          <input
            id="event-images"
            type="file"
            multiple
            accept="image/png,image/jpeg,image/webp"
            onChange={handleFileInput}
            className="hidden"
          />

          <label
            htmlFor="event-images"
            className="block border border-dashed border-slate-300 rounded-lg p-5 text-center cursor-pointer hover:border-[#0077B6]"
          >
            <p className="text-slate-700 font-medium">
              Haz clic para seleccionar imágenes
            </p>

            <p className="text-slate-500 text-sm">
              PNG/JPG/WEBP — máx. 10MB c/u
            </p>

            {files?.length > 0 && (
              <p className="text-slate-500 text-xs mt-1">
                Nuevas seleccionadas: {files.length}
              </p>
            )}
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
                    onClick={() => removeNewAt(idx)}
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

      <div className="flex justify-end gap-3 pt-2">
        {onCancel && (
          <button
            type="button"
            onClick={onCancel}
            className="px-4 py-2 rounded-lg border border-slate-300 text-slate-700 text-sm font-medium hover:bg-slate-50"
            disabled={isSubmitting}
          >
            Cancelar
          </button>
        )}

        <button
          type="submit"
          disabled={isSubmitting}
          className="px-4 py-2 rounded-lg bg-[#0077B6] hover:bg-[#005f90] text-white text-sm font-semibold disabled:opacity-60"
        >
          {isSubmitting ? 'Guardando…' : 'Guardar evento'}
        </button>
      </div>
    </form>
  );
}