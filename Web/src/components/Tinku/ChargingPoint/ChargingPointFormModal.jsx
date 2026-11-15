// File: src/components/Tinku/ChargingPoint/ChargingPointFormModal.jsx
'use client';

import {
  useEffect,
  useState,
  useRef,
} from 'react';

import MapPicker from '@/components/Business/MapPicker';

import {
  FaUpload,
  FaImage,
  FaTimes,
} from 'react-icons/fa';

const UI = {
  primary: '#0077B6',
  primaryHover: '#005f92',
  border: '#E2E8F0',
};

const DEFAULTS = {
  name: '',
  address: '',
  lat: -17.3895,
  lng: -66.1568,
  status: 'active',
  image_url: '',
};

export default function ChargingPointFormModal({
  open,
  initial = null,
  saving = false,
  onCancel,
  onSave,
}) {
  const [form, setForm] =
    useState(DEFAULTS);

  const [file, setFile] =
    useState(null);

  const [preview, setPreview] =
    useState('');

  const fileInputRef =
    useRef(null);

  /* =========================
     ESC
  ========================= */

  useEffect(() => {
    if (!open) return;

    const onKey = (e) => {
      if (
        e.key === 'Escape' &&
        !saving
      ) {
        onCancel?.();
      }
    };

    window.addEventListener(
      'keydown',
      onKey
    );

    return () =>
      window.removeEventListener(
        'keydown',
        onKey
      );
  }, [open, saving, onCancel]);

  /* =========================
     LOAD INITIAL
  ========================= */

  useEffect(() => {
    if (!open) return;

    const base = initial
      ? {
        name:
          initial.name ??
          '',

        address:
          initial.address ??
          '',

        lat: Number(
          initial?.location
            ?.latitude ??
          DEFAULTS.lat
        ),

        lng: Number(
          initial?.location
            ?.longitude ??
          DEFAULTS.lng
        ),

        status:
          initial.status ??
          'active',

        image_url:
          initial.image_url ??
          initial.image ??
          '',
      }
      : DEFAULTS;

    setForm(base);

    setFile(null);

    setPreview(
      base.image_url || ''
    );
  }, [open, initial]);

  /* =========================
     CHANGE
  ========================= */

  const onChange = (e) => {
    const { name, value } =
      e.target;

    setForm((p) => ({
      ...p,
      [name]: value,
    }));
  };

  /* =========================
     MAP
  ========================= */

  const onPickLocation = ({
    lat,
    lng,
    address,
  }) => {
    setForm((p) => ({
      ...p,
      lat,
      lng,
      address:
        address ||
        p.address,
    }));
  };

  /* =========================
     IMAGE
  ========================= */

  const onFileChange = (e) => {
    const f =
      e.target.files?.[0];

    if (!f) return;

    setFile(f);

    setPreview(
      URL.createObjectURL(f)
    );
  };

  const onClearImage = () => {
    setFile(null);

    setPreview('');

    setForm((p) => ({
      ...p,
      image_url: '',
    }));

    if (fileInputRef.current) {
      fileInputRef.current.value =
        '';
    }
  };

  /* =========================
     SUBMIT
  ========================= */

  const submit = async (e) => {
    e.preventDefault();

    await onSave?.({
      form,
      file,
    });
  };

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 grid place-items-center overflow-y-auto p-4"
      style={{
        background:
          'rgba(0,0,0,0.45)',
      }}
      onClick={() =>
        !saving &&
        onCancel?.()
      }
    >
      <div
        className="w-full max-w-3xl mx-4 bg-white rounded-2xl shadow-2xl border"
        style={{
          borderColor:
            UI.border,
        }}
        onClick={(e) =>
          e.stopPropagation()
        }
      >
        {/* HEADER */}
        <div
          className="px-5 py-4 border-b sticky top-0 bg-white rounded-t-2xl flex items-center justify-between"
          style={{
            borderColor:
              UI.border,
          }}
        >
          <h3 className="text-xl font-bold text-slate-800">
            {initial
              ? 'Editar punto de carga'
              : 'Registrar nuevo punto de carga'}
          </h3>

          <button
            type="button"
            onClick={() =>
              !saving &&
              onCancel?.()
            }
            className="inline-flex items-center gap-2 px-3 py-2 rounded-lg border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 transition disabled:opacity-60"
            disabled={saving}
          >
            <FaTimes />
          </button>
        </div>

        {/* BODY */}
        <form onSubmit={submit}>
          <div className="px-5 py-4 space-y-4 overflow-y-auto max-h-[70vh]">
            {/* NAME */}
            <div className="grid gap-1">
              <label className="text-sm font-medium text-slate-700">
                Nombre
              </label>

              <input
                name="name"
                value={form.name}
                onChange={onChange}
                required
                placeholder="Ej. Correo Central"
                className="px-3 py-2 rounded-lg border border-slate-300 focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
              />
            </div>

            {/* STATUS */}
            <div className="grid gap-1">
              <label className="text-sm font-medium text-slate-700">
                Estado
              </label>

              <select
                name="status"
                value={form.status}
                onChange={onChange}
                className="px-3 py-2 rounded-lg border border-slate-300 focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
              >
                <option value="active">
                  Activo
                </option>

                <option value="inactive">
                  Inactivo
                </option>

                <option value="maintenance">
                  Mantenimiento
                </option>
              </select>
            </div>

            {/* MAP */}
            <div className="grid gap-1">
              <label className="text-sm font-medium text-slate-700">
                Ubicación
              </label>

              <MapPicker
                value={{
                  lat: form.lat,
                  lng: form.lng,
                  address:
                    form.address,
                }}
                onChange={
                  onPickLocation
                }
                height={260}
              />
            </div>

            {/* IMAGE */}
            <div className="grid gap-2">
              <label className="text-sm font-medium text-slate-700">
                Imagen
              </label>

              <div className="flex items-center gap-3 flex-wrap">
                <button
                  type="button"
                  onClick={() =>
                    fileInputRef.current?.click()
                  }
                  disabled={saving}
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold text-white transition duration-200 shadow-sm disabled:opacity-60"
                  style={{
                    backgroundColor:
                      UI.primary,
                  }}
                >
                  <FaUpload />
                  Cargar imagen
                </button>

                <input
                  type="file"
                  accept="image/*"
                  ref={
                    fileInputRef
                  }
                  onChange={
                    onFileChange
                  }
                  className="hidden"
                />

                {(preview ||
                  form.image_url) && (
                    <button
                      type="button"
                      onClick={
                        onClearImage
                      }
                      disabled={
                        saving
                      }
                      className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-300 bg-gray-100 hover:bg-gray-200 text-gray-800 font-medium transition disabled:opacity-60"
                    >
                      <FaTimes className="text-red-500" />
                      Quitar
                    </button>
                  )}
              </div>

              <p className="text-xs text-gray-600 flex items-center gap-1">
                <FaImage className="text-sky-600" />
                JPG, PNG,
                WEBP, GIF
              </p>

              {(preview ||
                form.image_url) && (
                  <img
                    src={
                      preview ||
                      form.image_url
                    }
                    alt="Preview"
                    className="h-32 w-56 object-cover rounded-lg border border-slate-200 shadow-sm"
                  />
                )}
            </div>
          </div>

          {/* FOOTER */}
          <div
            className="px-5 py-4 border-t sticky bottom-0 bg-white rounded-b-2xl flex justify-end gap-3"
            style={{
              borderColor:
                UI.border,
            }}
          >
            <button
              type="button"
              onClick={() =>
                !saving &&
                onCancel?.()
              }
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold border text-slate-700 bg-white hover:bg-gray-50 transition duration-200 disabled:opacity-60"
              disabled={saving}
            >
              <FaTimes />
              Cancelar
            </button>

            <button
              type="submit"
              disabled={saving}
              className="px-4 py-2 rounded-lg font-semibold text-white transition duration-200 disabled:opacity-60"
              style={{
                backgroundColor:
                  UI.primary,
              }}
            >
              {saving
                ? 'Guardando…'
                : initial
                  ? 'Guardar cambios'
                  : 'Crear punto'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}