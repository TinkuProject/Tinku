'use client';

import { useEffect, useMemo, useState } from 'react';
import MapPicker from '@/components/Business/MapPicker';
import { FaImage, FaTimes } from 'react-icons/fa';

const UI = { primary: '#0077B6', border: '#E2E8F0' };

export default function TouristPlaceFormEdit({
  initialValue,                // { id, category_id, name, description, address, lat, lng }
  categoryOptions = [],
  tagOptions = [],             // [{value, label}]
  initialSelectedTagIds = [],  // number[]
  onSelectedTagIdsChange = () => { },
  existingImageUrls = [],      // string[]
  onRemoveExistingUrl = null,  // (url) => void|Promise<void>
  newFiles = [],               // File[]
  onNewFilesChange = () => { },
  isSubmitting = false,
  errorMsg = '',
  onCancel,
  onSubmit,                    // (payload) => void
}) {
  const [form, setForm] = useState({
    category_id: initialValue?.category_id ?? '',
    name: initialValue?.name ?? '',
    description: initialValue?.description ?? '',
    address: initialValue?.address ?? '',
    lat: typeof initialValue?.lat === 'number' ? initialValue.lat : -17.3895,
    lng: typeof initialValue?.lng === 'number' ? initialValue.lng : -66.1568,
  });

  useEffect(() => {
    setForm({
      category_id: initialValue?.category_id ?? '',
      name: initialValue?.name ?? '',
      description: initialValue?.description ?? '',
      address: initialValue?.address ?? '',
      lat: typeof initialValue?.lat === 'number' ? initialValue.lat : -17.3895,
      lng: typeof initialValue?.lng === 'number' ? initialValue.lng : -66.1568,
    });
  }, [initialValue]);

  const mapValue = useMemo(() => ({
    lat: Number(form.lat) || -17.3895,
    lng: Number(form.lng) || -66.1568,
    address: form.address || '',
  }), [form.lat, form.lng, form.address]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((f) => ({ ...f, [name]: value }));
  };

  const handleMapChange = ({ lat, lng, address }) => {
    setForm((f) => ({ ...f, lat, lng, address }));
  };

  // ---- TAGS ----
  const [selectedTagIds, setSelectedTagIds] = useState(initialSelectedTagIds || []);
  useEffect(() => setSelectedTagIds(initialSelectedTagIds || []), [initialSelectedTagIds]);

  const toggleTag = (id) => {
    const next = selectedTagIds.includes(id)
      ? selectedTagIds.filter((x) => x !== id)
      : [...selectedTagIds, id];
    setSelectedTagIds(next);
    onSelectedTagIdsChange(next);
  };

  // ---- NUEVAS IMÁGENES ----
  const handlePickImages = (e) => {
    const picked = Array.from(e.target.files || []);
    if (!picked.length) return;
    onNewFilesChange([...(newFiles || []), ...picked]);
    e.target.value = '';
  };

  const removeNewAt = (idx) => {
    const next = [...(newFiles || [])];
    next.splice(idx, 1);
    onNewFilesChange(next);
  };

  // ---- SUBMIT ----
  const submit = (e) => {
    e.preventDefault();
    if (!form.category_id) return alert('Selecciona una categoría.');
    if (!form.name.trim()) return alert('Ingresa el nombre del lugar turístico.');
    const payload = {
      category_id: Number(form.category_id),
      name: form.name.trim(),
      description: (form.description || '').trim() || null,
      address: form.address || null,
      location: {
        latitude: Number(form.lat),
        longitude: Number(form.lng),
      },
    };
    onSubmit?.(payload);
  };

  return (
    <form onSubmit={submit} className="relative">
      {/* BODY con scroll */}
      <div className="space-y-6 max-h-[70vh] overflow-y-auto pr-1">

        {/* Categoría + Nombre */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Categoría *</label>
            <select
              name="category_id"
              value={form.category_id}
              onChange={handleChange}
              required
              className="w-full border border-slate-300 p-3 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            >
              <option value="" disabled>Selecciona una categoría…</option>
              {categoryOptions.map((opt) => (
                <option key={opt.value} value={opt.value}>{opt.label}</option>
              ))}
            </select>
          </div>

          <div className="sm:col-span-2">
            <label className="block text-sm font-medium text-slate-700 mb-1">Nombre *</label>
            <input
              type="text"
              name="name"
              value={form.name}
              onChange={handleChange}
              required
              placeholder="Ej. Cristo de la Concordia"
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            />
          </div>
        </div>

        {/* Descripción */}
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Descripción</label>
          <textarea
            name="description"
            rows={3}
            value={form.description}
            onChange={handleChange}
            placeholder="Breve descripción del lugar…"
            className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
          />
        </div>

        {/* Mapa */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <label className="block text-sm font-medium text-slate-700">Selecciona la ubicación en el mapa</label>
            <span className="text-xs text-slate-500">Tip: clic en el mapa o arrastra el marcador</span>
          </div>
          <MapPicker value={mapValue} onChange={handleMapChange} height={320} />
        </div>

        {/* Imágenes actuales */}
        <div className="space-y-2">
          <label className="block text-sm font-medium text-slate-700">Imágenes actuales</label>
          {existingImageUrls?.length ? (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
              {existingImageUrls.map((url) => (
                <div key={url} className="relative group">
                  <img
                    src={url}
                    alt="img"
                    className="w-full h-28 object-cover rounded-lg border"
                    style={{ borderColor: UI.border }}
                  />
                  {onRemoveExistingUrl && (
                    <button
                      type="button"
                      onClick={() => onRemoveExistingUrl(url)}
                      className="absolute top-1 right-1 p-1 rounded-full bg-black/60 text-white opacity-0 group-hover:opacity-100 transition"
                      title="Eliminar"
                    >
                      <FaTimes className="text-xs" />
                    </button>
                  )}
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-slate-500">Sin imágenes registradas.</p>
          )}
        </div>

        {/* Añadir imágenes nuevas */}
        <div className="space-y-3">
          <label className="block text-sm font-medium text-slate-700">Añadir imágenes</label>

          <label
            className="inline-flex items-center gap-2 w-fit px-3 py-2 rounded-lg border bg-white text-[#0077B6] hover:bg-[#E0F4FF] cursor-pointer transition"
            style={{ borderColor: UI.border }}
          >
            <FaImage />
            <span className="font-semibold">Elegir archivos</span>
            <input type="file" accept="image/*" multiple onChange={handlePickImages} className="hidden" />
          </label>

          {Array.isArray(newFiles) && newFiles.length > 0 && (
            <>
              <p className="text-xs text-slate-500">
                {newFiles.length} archivo{newFiles.length > 1 ? 's' : ''} seleccionad{newFiles.length > 1 ? 'os' : 'o'}.
                PNG/JPG/WEBP — máx. ~5 MB c/u
              </p>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                {newFiles.map((f, idx) => {
                  const url = URL.createObjectURL(f);
                  return (
                    <div key={idx} className="relative group">
                      <img
                        src={url}
                        alt={`preview-new-${idx}`}
                        className="w-full h-28 object-cover rounded-lg border"
                        style={{ borderColor: UI.border }}
                        onLoad={() => URL.revokeObjectURL(url)}
                      />
                      <button
                        type="button"
                        onClick={() => removeNewAt(idx)}
                        className="absolute top-1 right-1 p-1 rounded-full bg-black/60 text-white opacity-0 group-hover:opacity-100 transition"
                        title="Quitar"
                      >
                        <FaTimes className="text-xs" />
                      </button>
                    </div>
                  );
                })}
              </div>
            </>
          )}
        </div>

        {/* Tags */}
        <div className="space-y-2">
          <label className="block text-sm font-medium text-slate-700">Tags</label>
          {tagOptions && tagOptions.length ? (
            <div className="flex flex-wrap gap-2">
              {tagOptions.map((t) => {
                const checked = selectedTagIds.includes(Number(t.value));
                return (
                  <label
                    key={t.value}
                    className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full border cursor-pointer transition
                               ${checked ? 'bg-[#E0F4FF] text-[#0B63A1] border-[#A8D8F0]'
                        : 'bg-white text-slate-800 hover:bg-slate-50'}`}
                    style={{ borderColor: UI.border }}
                  >
                    <input
                      type="checkbox"
                      className="accent-[#0077B6]"
                      checked={checked}
                      onChange={() => toggleTag(Number(t.value))}
                    />
                    <span className="text-sm font-medium">{t.label}</span>
                  </label>
                );
              })}
            </div>
          ) : (
            <p className="text-sm text-slate-500">No hay tags disponibles.</p>
          )}
        </div>

        {errorMsg && <p className="text-sm text-rose-600">{errorMsg}</p>}
        <div className="h-2" />
      </div>

      {/* FOOTER fijo */}
      <div
        className="sticky bottom-0 mt-4 pt-3 flex justify-end gap-2 bg-white"
        style={{ borderTop: `1px solid ${UI.border}` }}
      >
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
          disabled={isSubmitting || !form.category_id || !form.name}
          className="px-6 py-2 rounded-md font-semibold text-white disabled:opacity-60"
          style={{ background: UI.primary }}
        >
          {isSubmitting ? 'Guardando…' : 'Guardar cambios'}
        </button>
      </div>
    </form>
  );
}
