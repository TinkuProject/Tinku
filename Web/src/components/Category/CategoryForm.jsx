// File: src/components/Category/CategoryForm.jsx
'use client';

import ImageUploader from './ImageUploader';

export default function CategoryForm({
  formData,

  preview,
  hasImage,

  entityTypes = [],
  businessTypes = [],

  isSubmitting,
  isUploading,

  errorMsg,
  editIndex,

  onChange,
  onFileChange,

  onSubmit,
  onCancel,
}) {
  const isBusiness =
    formData.entity_type === 'business';

  return (
    <form
      onSubmit={onSubmit}
      className="space-y-6"
    >
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
        <div>
          <label className="block text-sm font-semibold text-gray-800 mb-1">
            Nombre
          </label>

          <input
            type="text"
            name="name"
            placeholder="Ej. Restaurantes"
            value={formData.name}
            onChange={onChange}
            className="w-full border border-gray-300 p-3 rounded-lg bg-white text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-sky-500"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-semibold text-gray-800 mb-1">
            Entidad
          </label>

          <select
            name="entity_type"
            value={
              formData.entity_type
            }
            onChange={onChange}
            required
            className="w-full border border-gray-300 p-3 rounded-lg bg-white text-gray-900 focus:outline-none focus:ring-2 focus:ring-sky-500"
          >
            <option
              value=""
              disabled
            >
              Selecciona entidad…
            </option>

            {entityTypes.map((opt) => (
              <option
                key={opt.value}
                value={opt.value}
              >
                {opt.label}
              </option>
            ))}
          </select>
        </div>

        {isBusiness && (
          <div>
            <label className="block text-sm font-semibold text-gray-800 mb-1">
              Tipo de negocio
            </label>

            <select
              name="business_type"
              value={
                formData.business_type ||
                ''
              }
              onChange={onChange}
              required={isBusiness}
              className="w-full border border-gray-300 p-3 rounded-lg bg-white text-gray-900 focus:outline-none focus:ring-2 focus:ring-sky-500"
            >
              <option
                value=""
                disabled
              >
                Selecciona tipo…
              </option>

              {businessTypes.map(
                (opt) => (
                  <option
                    key={opt.value}
                    value={opt.value}
                  >
                    {opt.label}
                  </option>
                )
              )}
            </select>
          </div>
        )}
      </div>

      <ImageUploader
        value={
          formData.file
        }
        preview={preview}
        hasImage={hasImage}
        isUploading={isUploading}
        isSubmitting={isSubmitting}
        onFileChange={
          onFileChange
        }
        onClear={() =>
          onChange({
            target: {
              name: 'file',
              value: null,
            },
          })
        }
      />

      {errorMsg && (
        <p className="text-sm font-medium text-red-600 bg-red-50 border border-red-200 rounded-md px-3 py-2">
          ⚠️ {errorMsg}
        </p>
      )}

      <div className="flex flex-wrap gap-4 pt-2">
        <button
          type="submit"
          disabled={
            isSubmitting ||
            isUploading
          }
          className="px-6 py-2 rounded-lg font-semibold text-white bg-sky-600 hover:bg-sky-700 active:bg-sky-800 shadow-sm transition disabled:opacity-60 disabled:pointer-events-none"
        >
          {editIndex !== null
            ? isSubmitting
              ? 'Actualizando…'
              : 'Actualizar Categoría'
            : isSubmitting
              ? 'Creando…'
              : 'Crear Categoría'}
        </button>

        {editIndex !== null && (
          <button
            type="button"
            onClick={onCancel}
            disabled={
              isSubmitting ||
              isUploading
            }
            className="px-6 py-2 rounded-lg font-semibold bg-gray-200 text-gray-900 hover:bg-gray-300 active:bg-gray-400 transition disabled:opacity-60"
          >
            Cancelar
          </button>
        )}
      </div>
    </form>
  );
}