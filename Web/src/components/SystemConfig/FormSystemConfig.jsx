'use client';

export default function FormSystemConfig({
    formData,
    isSubmitting,
    errorMsg,
    onChange,
    onSubmit,
    onCancel,
    isEditing = false,
}) {
    return (
        <form onSubmit={onSubmit} className="space-y-4">
            <div className="space-y-5">
                <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                        Clave de configuración *
                    </label>

                    <input
                        type="text"
                        name="key"
                        value={formData.key || ''}
                        onChange={onChange}
                        disabled={isEditing}
                        required
                        placeholder="Ej. max_booking_days"
                        className="w-full border border-slate-300 p-3 rounded-lg text-slate-800
              focus:outline-none focus:ring-2 focus:ring-[#0077B6]
              disabled:bg-slate-100 disabled:text-slate-500"
                    />

                    <p className="mt-1 text-xs text-slate-500">
                        La clave no puede modificarse una vez creada.
                    </p>
                </div>

                <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                        Valor *
                    </label>

                    <input
                        type="text"
                        name="value"
                        value={formData.value ?? ''}
                        onChange={onChange}
                        required
                        placeholder="Ej. 30"
                        className="w-full border border-slate-300 p-3 rounded-lg text-slate-800
              focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                    />
                </div>

                <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                        Descripción
                    </label>

                    <textarea
                        name="description"
                        rows={3}
                        value={formData.description || ''}
                        onChange={onChange}
                        placeholder="Explica para qué sirve esta configuración…"
                        className="w-full border border-slate-300 p-3 rounded-lg text-slate-800
              focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                    />
                </div>

                {errorMsg && (
                    <p className="text-sm text-red-600">{errorMsg}</p>
                )}
            </div>

            <div className="flex justify-end gap-3 pt-2">
                <button
                    type="button"
                    onClick={onCancel}
                    disabled={isSubmitting}
                    className="px-4 py-2 rounded-lg border border-slate-300 text-slate-700
            text-sm font-medium hover:bg-slate-50 disabled:opacity-60"
                >
                    Cancelar
                </button>

                <button
                    type="submit"
                    disabled={isSubmitting}
                    className="px-4 py-2 rounded-lg bg-[#0077B6] hover:bg-[#005f90]
            text-white text-sm font-semibold disabled:opacity-60"
                >
                    {isSubmitting ? 'Guardando…' : 'Guardar configuración'}
                </button>
            </div>
        </form>
    );
}