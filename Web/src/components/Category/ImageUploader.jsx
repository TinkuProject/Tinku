'use client';

import {
  FaUpload,
  FaImage,
  FaTimes,
} from 'react-icons/fa';

export default function ImageUploader({
  value,
  preview,
  hasImage,

  isUploading,
  isSubmitting,

  onFileChange,
  onClear,
}) {
  const imageSrc = preview || value || '';

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <label className="block text-sm font-semibold text-gray-800">
          Imagen de categoría
        </label>

        <div className="flex items-center gap-3 flex-wrap">
          <label
            className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-300 bg-white text-gray-800 font-medium cursor-pointer hover:bg-gray-50 active:bg-gray-100 transition ${isUploading || isSubmitting
                ? 'opacity-60 cursor-not-allowed'
                : ''
              }`}
          >
            <FaUpload className="text-sky-600" />

            <span>
              {isUploading
                ? 'Subiendo…'
                : hasImage
                  ? 'Cambiar imagen'
                  : 'Elegir imagen'}
            </span>

            <input
              type="file"
              accept="image/*"
              className="hidden"
              onChange={onFileChange}
              disabled={
                isUploading || isSubmitting
              }
            />
          </label>

          {hasImage && (
            <button
              type="button"
              onClick={onClear}
              disabled={
                isUploading || isSubmitting
              }
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-300 bg-gray-100 hover:bg-gray-200 text-gray-800 font-medium transition disabled:opacity-60"
              title="Quitar imagen"
            >
              <FaTimes className="text-red-500" />

              <span>Quitar</span>
            </button>
          )}
        </div>

        <p className="text-xs text-gray-600 flex items-center gap-1">
          <FaImage className="text-sky-600" />

          Formatos permitidos:
          JPG, PNG, WEBP, GIF
        </p>
      </div>

      {hasImage && imageSrc && (
        <div className="flex justify-center">
          <img
            src={imageSrc}
            alt="Vista previa"
            className="h-44 w-80 object-cover rounded-xl border border-slate-200 shadow-sm"
          />
        </div>
      )}
    </div>
  );
}