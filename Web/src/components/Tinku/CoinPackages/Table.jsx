// File: src/components/CoinPackages/Table.jsx
'use client';

import {
    FaSyncAlt,
    FaEdit,
    FaTrashAlt,
    FaToggleOn,
    FaToggleOff,
    FaRedoAlt,
    FaImage,
    FaCoins,
} from 'react-icons/fa';

export default function Table({
    UI,
    rows = [],
    loading,
    onRefresh,
    onEditById,
    onSoftDeleteById,
    onToggleActiveById,
    onImageClick,
}) {
    const isActive = (status) => {
        return status === 'active' || status === 1 || status === true;
    };

    return (
        <div
            className="bg-white border rounded-xl shadow-sm overflow-hidden"
            style={{ borderColor: UI.border }}
        >
            <div
                className="flex items-center justify-between px-4 py-3 border-b bg-sky-50"
                style={{ borderColor: UI.border }}
            >
                <div className="text-sm font-semibold text-slate-800">
                    <span className="text-[#0077B6] font-bold">
                        Paquetes de monedas
                    </span>{' '}
                    · {rows.length} registro
                    {rows.length === 1 ? '' : 's'}
                </div>

                <button
                    onClick={onRefresh}
                    className="inline-flex items-center gap-2 px-3 py-2 rounded-lg text-white font-semibold shadow-sm transition"
                    style={{ backgroundColor: UI.primary }}
                >
                    <FaSyncAlt className={loading ? 'animate-spin' : ''} />
                    {loading ? 'Actualizando…' : 'Recargar'}
                </button>
            </div>

            <div className="overflow-x-auto">
                <table className="min-w-full text-sm text-slate-800">
                    <thead className="bg-sky-100 font-semibold text-slate-900">
                        <tr>
                            <th className="px-4 py-3 text-left">ID</th>
                            <th className="px-4 py-3 text-left">Imagen</th>
                            <th className="px-4 py-3 text-left">Nombre</th>
                            <th className="px-4 py-3 text-left">Tinkus</th>
                            <th className="px-4 py-3 text-left">Precio Bs.</th>
                            <th className="px-4 py-3 text-left">Estado</th>
                            <th className="px-4 py-3 text-right">Acciones</th>
                        </tr>
                    </thead>

                    <tbody className="[&>tr:nth-child(odd)]:bg-slate-50">
                        {loading ? (
                            <tr>
                                <td
                                    colSpan={7}
                                    className="px-4 py-6 text-center text-slate-500"
                                >
                                    Cargando…
                                </td>
                            </tr>
                        ) : rows.length === 0 ? (
                            <tr>
                                <td
                                    colSpan={7}
                                    className="px-4 py-6 text-center text-slate-500"
                                >
                                    Sin resultados.
                                </td>
                            </tr>
                        ) : (
                            rows.map((p) => {
                                const active = isActive(p.status);
                                const archived = p.status === 'archived';

                                return (
                                    <tr
                                        key={p.id}
                                        className="border-t hover:bg-slate-100 transition"
                                        style={{ borderColor: UI.border }}
                                    >
                                        {/* ID */}
                                        <td className="px-4 py-3 font-medium">
                                            #{p.id}
                                        </td>

                                        {/* Imagen */}
                                        <td className="px-4 py-3">
                                            {p.image_url ? (
                                                <img
                                                    src={p.image_url}
                                                    alt={p.name}
                                                    className="h-14 w-20 object-cover rounded-lg border border-slate-300 cursor-pointer hover:scale-105 transition"
                                                    onClick={() =>
                                                        onImageClick?.(p.image_url)
                                                    }
                                                />
                                            ) : (
                                                <div className="h-14 w-20 rounded-lg border border-dashed border-slate-300 bg-slate-50 flex items-center justify-center text-slate-400">
                                                    <FaImage />
                                                </div>
                                            )}
                                        </td>

                                        {/* Nombre */}
                                        <td className="px-4 py-3 font-semibold text-slate-800">
                                            {p.name}
                                        </td>

                                        {/* Tinkus */}
                                        <td className="px-4 py-3">
                                            <span className="inline-flex items-center gap-2 font-semibold text-amber-700">
                                                <FaCoins />
                                                {Number(
                                                    p.tinkus_amount || 0
                                                )}{' '}
                                                Tinkus
                                            </span>
                                        </td>

                                        {/* Precio */}
                                        <td className="px-4 py-3">
                                            <span className="font-medium">
                                                Bs.{' '}
                                                {Number(
                                                    p.cash_amount || 0
                                                ).toFixed(2)}
                                            </span>
                                        </td>

                                        {/* Estado */}
                                        <td className="px-4 py-3">
                                            <span
                                                className={`px-2 py-1 text-xs rounded-full border font-medium flex items-center gap-1 w-fit ${archived
                                                        ? 'bg-red-100 text-red-700 border-red-300'
                                                        : active
                                                            ? 'bg-green-100 text-green-700 border-green-300'
                                                            : 'bg-gray-100 text-gray-600 border-gray-300'
                                                    }`}
                                            >
                                                {active ? (
                                                    <FaToggleOn className="text-green-600" />
                                                ) : (
                                                    <FaToggleOff className="text-gray-500" />
                                                )}

                                                {archived
                                                    ? 'Archivado'
                                                    : active
                                                        ? 'Activo'
                                                        : 'Inactivo'}
                                            </span>
                                        </td>

                                        {/* Acciones */}
                                        <td className="px-4 py-3 text-right">
                                            <div className="inline-flex gap-2 flex-wrap justify-end">
                                                {/* Editar */}
                                                <button
                                                    onClick={() =>
                                                        onEditById?.(p.id)
                                                    }
                                                    className="px-3 py-1.5 rounded-lg border font-semibold text-sky-700 hover:bg-sky-100 flex items-center gap-2 transition"
                                                    style={{
                                                        borderColor: UI.primary,
                                                    }}
                                                >
                                                    <FaEdit />
                                                    Editar
                                                </button>

                                                {/* Archivar */}
                                                {!archived && (
                                                    <button
                                                        onClick={() =>
                                                            onSoftDeleteById?.(p.id)
                                                        }
                                                        className="px-3 py-1.5 rounded-lg font-semibold text-white hover:opacity-90 flex items-center gap-2 transition"
                                                        style={{
                                                            backgroundColor:
                                                                UI.danger,
                                                        }}
                                                    >
                                                        <FaTrashAlt />
                                                        Archivar
                                                    </button>
                                                )}

                                                {/* Toggle active */}
                                                {!archived && (
                                                    <button
                                                        onClick={() =>
                                                            onToggleActiveById?.(
                                                                p.id
                                                            )
                                                        }
                                                        className={`px-3 py-1.5 rounded-lg border font-semibold flex items-center gap-2 transition ${active
                                                                ? 'text-amber-700 bg-amber-50 hover:bg-amber-100 border-amber-300'
                                                                : 'text-emerald-700 bg-emerald-50 hover:bg-emerald-100 border-emerald-300'
                                                            }`}
                                                    >
                                                        {active ? (
                                                            <FaRedoAlt />
                                                        ) : (
                                                            <FaToggleOn />
                                                        )}

                                                        {active
                                                            ? 'Desactivar'
                                                            : 'Activar'}
                                                    </button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
}