'use client';

import ImageUploader from '@/components/Category/ImageUploader';
import { FaSave, FaPlus, FaBroom } from 'react-icons/fa';

export default function Form({
    UI,
    formData,
    isSubmitting,
    uploading,
    editIndex,
    handleChange,
    handleSubmit,
    preview,
    onFileChange,
    onClearImage,
    onCancel,
}) {
    return (
        <form
            onSubmit={handleSubmit}
            className="grid md:grid-cols-3 gap-4 bg-white border rounded-xl p-4 shadow-sm"
            style={{ borderColor: UI.border }}
        >
            <div className="grid gap-1">
                <label className="text-sm font-medium text-slate-800">
                    Nombre <span className="text-rose-600">*</span>
                </label>
                <input
                    name="name"
                    value={formData.name}
                    onChange={handleChange}
                    required
                    placeholder="Tinku Pro"
                    className="px-3 py-2 rounded-lg border border-slate-300 text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                />
            </div>

            <div className="grid gap-1">
                <label className="text-sm font-medium text-slate-800">
                    Precio <span className="text-rose-600">*</span>
                </label>
                <input
                    type="number"
                    step="0.01"
                    min="0"
                    name="price"
                    value={formData.price}
                    onChange={handleChange}
                    required
                    placeholder="100"
                    className="px-3 py-2 rounded-lg border border-slate-300 text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                />
            </div>

            <div className="grid gap-1">
                <label className="text-sm font-medium text-slate-800">
                    Moneda
                </label>
                <input
                    name="currency"
                    value={formData.currency}
                    onChange={handleChange}
                    placeholder="BOB"
                    className="px-3 py-2 rounded-lg border border-slate-300 text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                />
            </div>

            <div className="grid gap-1">
                <label className="text-sm font-medium text-slate-800">
                    Tinku incluidas
                </label>
                <input
                    type="number"
                    min="0"
                    name="included_tinku"
                    value={formData.included_tinku}
                    onChange={handleChange}
                    placeholder="100"
                    className="px-3 py-2 rounded-lg border border-slate-300 text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                />
            </div>

            <div className="grid gap-1">
                <label className="text-sm font-medium text-slate-800">
                    Duración meses
                </label>
                <input
                    type="number"
                    min="1"
                    name="duration_months"
                    value={formData.duration_months}
                    onChange={handleChange}
                    placeholder="1"
                    className="px-3 py-2 rounded-lg border border-slate-300 text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                />
            </div>

            <div className="grid gap-1">
                <label className="text-sm font-medium text-slate-800">
                    Estado
                </label>
                <select
                    name="status"
                    value={formData.status}
                    onChange={handleChange}
                    className="px-3 py-2 rounded-lg border border-slate-300 text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                >
                    <option value="active">Activo</option>
                    <option value="inactive">Inactivo</option>
                    <option value="archived">Archivado</option>
                </select>
            </div>

            <div className="grid gap-1 md:col-span-3">
                <label className="text-sm font-medium text-slate-800">
                    Imagen del plan
                </label>

                <ImageUploader
                    value={preview}
                    preview={preview}
                    hasImage={!!preview}
                    isUploading={uploading}
                    isSubmitting={isSubmitting}
                    onFileChange={onFileChange}
                    onClear={onClearImage}
                />
            </div>

            <div className="md:col-span-3 flex items-center justify-end gap-2">
                <button
                    type="button"
                    onClick={() => {
                        onClearImage?.();
                        onCancel?.();
                    }}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border bg-white hover:bg-slate-50 text-slate-800 transition shadow-sm"
                    style={{ borderColor: UI.border }}
                >
                    <FaBroom />
                    Cancelar
                </button>

                <button
                    type="submit"
                    disabled={isSubmitting || uploading}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg text-white font-semibold disabled:opacity-60 disabled:cursor-not-allowed transition shadow-sm"
                    style={{ backgroundColor: UI.primary }}
                >
                    {uploading ? (
                        'Subiendo…'
                    ) : isSubmitting ? (
                        'Guardando…'
                    ) : editIndex !== null ? (
                        <>
                            <FaSave /> Actualizar
                        </>
                    ) : (
                        <>
                            <FaPlus /> Crear plan
                        </>
                    )}
                </button>
            </div>
        </form>
    );
}