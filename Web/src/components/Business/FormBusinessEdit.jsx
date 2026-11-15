// src/components/Business/FormBusinessEdit.jsx
'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import MapPicker from '@/components/Business/MapPicker';
import mediaService from '@/services/mediaService';
import { uploadImages } from '@/services/storageService';

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

function authHeader() {
  if (typeof window === 'undefined') return {};
  const token = localStorage.getItem('token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function http(path, { method = 'GET', body, signal } = {}) {
  const isFormData = body instanceof FormData;

  const res = await fetch(`${API_URL}${path}`, {
    method,
    signal,
    headers: isFormData
      ? { ...authHeader() }
      : { 'Content-Type': 'application/json', ...authHeader() },
    body: body ? (isFormData ? body : JSON.stringify(body)) : undefined,
  });

  let json = null;

  try {
    json = await res.json();
  } catch (_) { }

  if (!res.ok) {
    const e = new Error(json?.error || json?.message || `HTTP ${res.status}`);
    e.status = res.status;
    e.details = json;
    throw e;
  }

  return res.status === 204 ? null : json ?? {};
}

export default function FormBusinessEdit({
  businessId,
  onClose,
  onSaved,
  categoryOptions = [],
  businessTypes = [
    { value: 'business', label: 'Negocio' },
    { value: 'service', label: 'Servicio' },
  ],
}) {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const [form, setForm] = useState({
    category_id: '',
    name: '',
    nit: '',
    description: '',
    phone: '',
    email: '',
    business_type: 'business',
    address: '',
    location: {
      latitude: -17.3895,
      longitude: -66.1568,
    },
    website: '',
  });

  const [mediaItems, setMediaItems] = useState([]);
  const [files, setFiles] = useState([]);
  const [previews, setPreviews] = useState([]);

  const reqRef = useRef({ n: 0, controller: null });

  useEffect(() => {
    let mounted = true;

    setMediaItems([]);
    setFiles([]);
    setPreviews([]);
    setLoading(true);
    setErrorMsg('');

    try {
      reqRef.current.controller?.abort();
    } catch { }

    const controller = new AbortController();
    const ticket = ++reqRef.current.n;
    reqRef.current.controller = controller;

    (async () => {
      try {
        const biz = await http(`/businesses/${businessId}`, {
          signal: controller.signal,
        });

        if (!mounted || ticket !== reqRef.current.n) return;

        const latitude = Number(biz?.location?.latitude ?? -17.3895);
        const longitude = Number(biz?.location?.longitude ?? -66.1568);

        setForm({
          category_id: biz?.category_id ?? '',
          name: biz?.name ?? '',
          nit: biz?.nit ?? '',
          description: biz?.description ?? '',
          phone: biz?.phone ?? '',
          email: biz?.email ?? '',
          business_type: biz?.business_type ?? 'business',
          address: biz?.address ?? '',
          location: {
            latitude: Number.isFinite(latitude) ? latitude : -17.3895,
            longitude: Number.isFinite(longitude) ? longitude : -66.1568,
          },
          website: biz?.website ?? '',
        });

        const list = await mediaService.listByEntity(
          'business',
          Number(businessId),
          { signal: controller.signal }
        );

        if (!mounted || ticket !== reqRef.current.n) return;

        const safe = (Array.isArray(list) ? list : [])
          .filter((m) => String(m.entity_id) === String(businessId))
          .map((m) => ({
            id: m.id ?? m.media_id ?? m._id,
            url: m.url,
            type: m.type ?? 'image',
            description: m.description ?? '',
            entity_id: m.entity_id,
          }))
          .filter((m) => m.id && m.url);

        setMediaItems(safe);
      } catch (e) {
        if (e.name !== 'AbortError') {
          setErrorMsg(e.message || 'No se pudo cargar el negocio');
        }
      } finally {
        if (mounted && ticket === reqRef.current.n) {
          setLoading(false);
        }
      }
    })();

    return () => {
      mounted = false;
      try {
        controller.abort();
      } catch { }
    };
  }, [businessId]);

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

  const onChange = (e) => {
    const { name, value } = e.target;

    setForm((f) => ({
      ...f,
      [name]: value,
    }));
  };

  const handleFileInput = (e) => {
    const list = Array.from(e.target.files || []);

    if (!list.length) return;

    const ALLOWED = new Set(['image/jpeg', 'image/png', 'image/webp']);
    const MAX = 10 * 1024 * 1024;

    const ok = list.filter((f) => ALLOWED.has(f.type) && f.size <= MAX);

    setFiles((prev) => [...prev, ...ok]);

    e.target.value = '';
  };

  const removeNewAt = (idx) => {
    setFiles((prev) => {
      const copy = [...prev];
      copy.splice(idx, 1);
      return copy;
    });
  };

  const removeExisting = async (mediaId) => {
    try {
      await mediaService.remove(mediaId);

      setMediaItems((prev) =>
        prev.filter((m) => String(m.id) !== String(mediaId))
      );
    } catch (e) {
      setErrorMsg(e.message || 'No se pudo eliminar la imagen');
    }
  };

  const onSubmit = async (e) => {
    e.preventDefault();

    setSaving(true);
    setErrorMsg('');

    try {
      const cleanText = (value) => {
        const v = String(value || '').trim();
        return v === '' ? null : v;
      };

      const payload = {
        category_id: Number(form.category_id),
        name: String(form.name || '').trim(),
        nit: cleanText(form.nit),
        description: cleanText(form.description),
        phone: cleanText(form.phone),
        email: cleanText(form.email),
        business_type: form.business_type,
        address: String(form.address || '').trim(),
        location: {
          latitude: Number(form.location.latitude),
          longitude: Number(form.location.longitude),
        },
        website: cleanText(form.website),
      };

      await http(`/businesses/${businessId}`, {
        method: 'PUT',
        body: payload,
      });

      if (files.length) {
        const urls = await uploadImages(files, {
          entityType: 'business',
          entityId: Number(businessId),
        });

        console.log('UPLOADED URLS:', urls);

      }

      await onSaved?.();
    } catch (e) {
      setErrorMsg(e.message || 'No se pudo guardar');
      setSaving(false);
      return;
    }

    setSaving(false);
  };

  const categoryValue = useMemo(
    () => form?.category_id ?? '',
    [form?.category_id]
  );

  const imagesForThisBiz = useMemo(
    () => mediaItems.filter((m) => String(m.entity_id ?? '') === String(businessId)),
    [mediaItems, businessId]
  );

  if (loading) {
    return <div className="text-sm text-slate-600">Cargando negocio…</div>;
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <div className="space-y-6 max-h-[70vh] overflow-y-auto pr-1">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Tipo de negocio
            </label>
            <select
              name="business_type"
              value={form.business_type}
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
              value={categoryValue}
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
              value={form.name}
              onChange={onChange}
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
              required
            />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              NIT
            </label>
            <input
              type="text"
              name="nit"
              value={form.nit}
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
              value={form.email}
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
              value={form.phone}
              onChange={onChange}
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            />
          </div>
        </div>

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
              lat: Number(form.location?.latitude) || -17.3895,
              lng: Number(form.location?.longitude) || -66.1568,
              address: form.address || '',
            }}
            onChange={({ lat, lng, address }) => {
              setForm((f) => ({
                ...f,
                address,
                location: {
                  latitude: lat,
                  longitude: lng,
                },
              }));
            }}
            height={300}
            scrollWheelZoom={false}
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
          <div className="sm:col-span-1">
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Website
            </label>
            <input
              type="text"
              name="website"
              value={form.website}
              onChange={onChange}
              className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">
            Descripción
          </label>
          <textarea
            name="description"
            rows={3}
            value={form.description}
            onChange={onChange}
            className="w-full border border-slate-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
          />
        </div>

        <div className="space-y-2">
          <p className="text-sm font-medium text-slate-700">
            Imágenes existentes
          </p>

          {imagesForThisBiz.length ? (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
              {imagesForThisBiz.map((m) => (
                <div key={m.id ?? m.url} className="relative group">
                  <img
                    src={m.url}
                    alt="media"
                    className="w-full h-28 object-cover rounded-md border border-slate-200"
                  />
                  <button
                    type="button"
                    onClick={() => removeExisting(m.id)}
                    className="absolute top-1 right-1 bg-red-600 text-white text-xs px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition"
                  >
                    Quitar
                  </button>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-xs text-slate-500">No hay imágenes registradas.</p>
          )}
        </div>

        <div className="space-y-2">
          <label
            htmlFor="biz-images-edit"
            className="block text-sm font-medium text-slate-700"
          >
            Agregar imágenes (múltiples)
          </label>

          <input
            id="biz-images-edit"
            type="file"
            multiple
            accept="image/png,image/jpeg,image/webp"
            onChange={handleFileInput}
            className="hidden"
          />

          <label
            htmlFor="biz-images-edit"
            className="block border border-dashed border-slate-300 rounded-lg p-5 text-center cursor-pointer hover:border-[#0077B6]"
          >
            <div>
              <p className="text-slate-700 font-medium">
                Haz clic para seleccionar imágenes
              </p>
              <p className="text-slate-500 text-sm">
                PNG/JPG/WEBP — máx. 10MB c/u
              </p>
              {files.length > 0 && (
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

      <div className="flex justify-end gap-2 pt-1">
        <button
          type="button"
          onClick={onClose}
          className="px-6 py-2 rounded-md font-semibold border bg-white text-slate-900 hover:bg-[#F2F4F7]"
        >
          Cancelar
        </button>

        <button
          type="submit"
          disabled={saving}
          className="px-6 py-2 rounded-md font-semibold text-white disabled:opacity-60"
          style={{ background: '#0077B6' }}
        >
          {saving ? 'Guardando…' : 'Guardar cambios'}
        </button>
      </div>
    </form>
  );
}