// File: src/components/CoinPackages/Form.jsx
'use client';

import ImageUploader from '@/components/Category/ImageUploader';

import {
    FaSave,
    FaPlus,
    FaBroom,
    FaCoins,
    FaMoneyBillWave,
} from 'react-icons/fa';

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
            {/* Nombre */}
            <div className="grid gap-1">
                <label className="text-sm font-medium text-slate-800">
                    Nombre del paquete{' '}
                    <span className="text-rose-600">*</span>
                </label>

                <input
                    name="name"
                    value={formData.name}
                    onChange={handleChange}
                    required
                    placeholder="Pack Inicial"
                    className="px-3 py-2 rounded-lg border border-slate-300 text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                />
            </div>

            {/* Tinkus */}
            <div className="grid gap-1">
                <label className="text-sm font-medium text-slate-800 inline-flex items-center gap-2">
                    <FaCoins className="text-amber-500" />
                    Tinkus{' '}
                    <span className="text-rose-600">*</span>
                </label>

                <input
                    type="number"
                    min="1"
                    name="tinkus_amount"
                    value={formData.tinkus_amount}
                    onChange={handleChange}
                    required
                    placeholder="100"
                    className="px-3 py-2 rounded-lg border border-slate-300 text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                />
            </div>

            {/* Precio */}
            <div className="grid gap-1">
                <label className="text-sm font-medium text-slate-800 inline-flex items-center gap-2">
                    <FaMoneyBillWave className="text-emerald-600" />
                    Precio Bs.{' '}
                    <span className="text-rose-600">*</span>
                </label>

                <input
                    type="number"
                    step="0.01"
                    min="1"
                    name="cash_amount"
                    value={formData.cash_amount}
                    onChange={handleChange}
                    required
                    placeholder="50"
                    className="px-3 py-2 rounded-lg border border-slate-300 text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                />
            </div>

            {/* Estado */}
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
                    
                </select>
            </div>

            {/* Imagen */}
            <div className="grid gap-1 md:col-span-2">
                <label className="text-sm font-medium text-slate-800">
                    Imagen del paquete
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

            {/* Acciones */}
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
                            <FaPlus /> Crear paquete
                        </>
                    )}
                </button>
            </div>
        </form>
    );
}