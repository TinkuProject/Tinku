'use client';

import { useState } from 'react';
import {
    FaTimes,
    FaMoneyBillWave,
    FaUser,
    FaTag,
    FaCommentDots,
    FaEnvelope,
    FaPhone,
    FaImage,
} from 'react-icons/fa';

const UI = {
    primary: '#0077B6',
    border: '#E2E8F0',
    soft: '#F8FAFC',
};

function getStatusLabel(status) {
    const s = String(status || '').toLowerCase();

    switch (s) {
        case 'pending':
            return 'Pendiente';

        case 'approved':
            return 'Aprobada';

        case 'rejected':
            return 'Rechazada';

        default:
            return 'Desconocido';
    }
}

export default function TransactionViewReview({
    tx,
    user,          // usuario enriquecido
    isOpen,
    onClose,
    onApprove,
    onReject,
    savingId,
    proofUrl,
}) {
    if (!isOpen || !tx) return null;

    const [showProof, setShowProof] = useState(false);

    const requestStatus = String(tx.status || '').toLowerCase();
    const paymentStatus = String(tx.payment?.status || 'pending').toLowerCase();

    const isPending =
        requestStatus === 'pending' &&
        paymentStatus === 'pending';
    const isSaving = savingId === tx.id;

    const currency =
        tx.payment?.currency ||
        tx.currency ||
        'BOB';
    const isBOB = String(currency).toUpperCase() === 'BOB';

    const dateStr =
        tx.transaction_date ??
        tx.transactionDate ??
        tx.created_at ??
        tx.createdAt ??
        null;

    const updatedStr = tx.updated_at ?? tx.updatedAt ?? null;

    const formattedDate = dateStr
        ? new Date(dateStr).toLocaleString('es-BO', {
            dateStyle: 'short',
            timeStyle: 'short',
        })
        : 'Sin fecha';

    const formattedUpdated = updatedStr
        ? new Date(updatedStr).toLocaleString('es-BO', {
            dateStyle: 'short',
            timeStyle: 'short',
        })
        : '—';

    // Datos amigables del usuario (si existen)
    const displayName = user
        ? (
            user.username ||
            `${user.first_name ?? ''} ${user.last_name ?? ''}`.trim() ||
            user.email ||
            'Usuario'
        ).trim()
        : null;

    const initials = displayName
        ? (() => {
            const parts = displayName.split(' ').filter(Boolean);
            const first = parts[0]?.[0] ?? '';
            const second = parts[1]?.[0] ?? '';
            return (first + second).toUpperCase() || 'U';
        })()
        : 'U';

    const email = user?.email ?? null;
    const phone = user?.phone ?? null;
    const username = user?.username ?? null;
    const fullName = user
        ? `${user.first_name ?? ''} ${user.last_name ?? ''}`.trim() || displayName
        : null;

    const coinBalance =
        typeof user?.coin_balance === 'number'
            ? user.coin_balance
            : user?.coin_balance != null
                ? Number(user.coin_balance)
                : null;

    return (
        <>
            {/* MODAL PRINCIPAL */}
            <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40">
                <div className="bg-white rounded-2xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
                    {/* Header */}
                    <div
                        className="flex items-center justify-between px-5 py-3 border-b"
                        style={{ borderColor: UI.border }}
                    >
                        <div>
                            <h2 className="text-lg font-semibold text-gray-800">
                                Transacción #{tx.id ?? '—'}
                            </h2>
                            <p className="text-xs text-gray-500">
                                Estado:{' '}
                                <span className="font-medium">
                                    {getStatusLabel(tx.status)}
                                </span>
                            </p>
                        </div>

                        <button
                            type="button"
                            onClick={onClose}
                            className="p-1 rounded-full hover:bg-gray-100 text-black"
                        >
                            <FaTimes />
                        </button>
                    </div>

                    {/* Body */}
                    <div className="flex-1 overflow-y-auto px-5 py-4 space-y-4 bg-slate-50/60">
                        {/* Detalle del pago */}
                        <section
                            className="bg-white rounded-xl border p-4 space-y-2"
                            style={{ borderColor: UI.border }}
                        >
                            <div className="flex items-center gap-2 text-gray-700">
                                <FaMoneyBillWave className="text-gray-500" />
                                <h3 className="text-sm font-semibold">Detalle del pago</h3>
                            </div>

                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs md:text-sm mt-2">
                                {/* Monto */}
                                <div className="flex flex-col">
                                    <span className="text-gray-500">Monto</span>
                                    <span className="text-slate-800 text-sm md:text-base font-semibold">
                                        {tx.payment?.amount ?? tx.amount ?? 0}
                                        <span
                                            className={`font-normal ${isBOB ? 'text-slate-700' : 'text-amber-700'
                                                }`}
                                        >
                                            {currency}
                                        </span>
                                    </span>
                                </div>

                                {/* Estado del pago */}
                                <div className="flex flex-col">
                                    <span className="text-gray-500">Estado del pago</span>
                                    <span
                                        className={`text-sm font-medium ${String(tx.status || '').toLowerCase() === 'completed'
                                            ? 'text-green-600'
                                            : String(tx.status || '').toLowerCase() === 'failed'
                                                ? 'text-red-600'
                                                : String(tx.status || '').toLowerCase() ===
                                                    'reverted'
                                                    ? 'text-blue-600'
                                                    : 'text-amber-600'
                                            }`}
                                    >
                                        {getStatusLabel(tx.status)}
                                    </span>
                                </div>

                                {/* Tipo de destino */}
                                <div className="flex flex-col">
                                    <span className="text-gray-500">Tipo de destino</span>
                                    <span className="text-slate-800">
                                        {tx.type ?? '—'}
                                    </span>
                                </div>
                            </div>
                        </section>

                        {/* Usuario */}
                        <section
                            className="bg-white rounded-xl border p-4 space-y-3"
                            style={{ borderColor: UI.border }}
                        >
                            <div className="flex items-center gap-2 text-gray-700">
                                <FaUser className="text-gray-500" />
                                <h3 className="text-sm font-semibold">Usuario</h3>
                            </div>

                            {user ? (
                                <>
                                    <div className="mt-2 flex items-start gap-4">
                                        {/* Avatar */}
                                        <div className="relative w-14 h-14 shrink-0">
                                            {user.photo ? (
                                                <img
                                                    src={user.photo}
                                                    alt="Foto de perfil"
                                                    className="w-14 h-14 rounded-full object-cover border-2 border-[#0077B6]/40 shadow-sm"
                                                />
                                            ) : (
                                                <div className="w-14 h-14 rounded-full bg-[#0077B6]/10 text-[#0077B6] flex items-center justify-center text-lg font-semibold border border-[#0077B6]/20">
                                                    {initials}
                                                </div>
                                            )}
                                        </div>

                                        {/* Info en dos columnas */}
                                        <div className="flex-1">
                                            <p className="font-semibold text-gray-900 text-sm md:text-base">
                                                {fullName}
                                            </p>

                                            <div className="mt-1 grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-1 text-[11px] md:text-xs">
                                                {/* Columna 1 */}
                                                <div className="space-y-1">
                                                    <p className="text-gray-500">
                                                        Usuario:{' '}
                                                        <span className="font-mono text-gray-800">
                                                            {username}
                                                        </span>
                                                        {user.user_type && (
                                                            <span className="ml-2 px-2 py-[2px] rounded-full bg-blue-50 text-blue-600 text-[9px] font-semibold uppercase">
                                                                {user.user_type}
                                                            </span>
                                                        )}
                                                    </p>

                                                    {email && (
                                                        <p className="flex items-center gap-1 text-gray-700">
                                                            <FaEnvelope className="text-gray-400" />
                                                            <span>{email}</span>
                                                        </p>
                                                    )}

                                                    {phone && (
                                                        <p className="flex items-center gap-1 text-gray-700">
                                                            <FaPhone className="text-gray-400" />
                                                            <span>{phone}</span>
                                                        </p>
                                                    )}

                                                    {/* Saldo Tinku */}
                                                    {coinBalance != null && !Number.isNaN(coinBalance) && (
                                                        <p className="text-gray-600">
                                                            <span className="font-semibold">
                                                                Saldo Tinku:{' '}
                                                            </span>
                                                            <span
                                                                className={`font-semibold ${coinBalance > 0
                                                                    ? 'text-emerald-600'
                                                                    : 'text-slate-700'
                                                                    }`}
                                                            >
                                                                {coinBalance} Tinku
                                                            </span>
                                                        </p>
                                                    )}
                                                </div>

                                                {/* Columna 2 */}
                                                <div className="space-y-1">
                                                    {user.address && (
                                                        <p className="text-gray-600">
                                                            <span className="font-semibold">
                                                                Dirección:{' '}
                                                            </span>
                                                            {user.address}
                                                        </p>
                                                    )}

                                                    {user.ci && (
                                                        <p className="text-gray-600">
                                                            <span className="font-semibold">C.I.: </span>
                                                            {user.ci}
                                                        </p>
                                                    )}

                                                    <p className="text-gray-500">
                                                        Estado:{' '}
                                                        <span
                                                            className={`font-semibold ${user.status === 1
                                                                ? 'text-green-600'
                                                                : 'text-red-600'
                                                                }`}
                                                        >
                                                            {user.status === 1
                                                                ? 'Activo'
                                                                : 'Inactivo'}
                                                        </span>
                                                    </p>

                                                    {user.created_at && (
                                                        <p className="text-gray-500">
                                                            Creado el:{' '}
                                                            {new Date(
                                                                user.created_at
                                                            ).toLocaleDateString('es-BO')}
                                                        </p>
                                                    )}
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </>
                            ) : (
                                <p className="mt-1 text-[11px] text-gray-400 italic">
                                    No se encontró información detallada del usuario.
                                </p>
                            )}
                        </section>

                        {/* Comprobante */}
                        <section
                            className="bg-white rounded-xl border p-4 space-y-2"
                            style={{ borderColor: UI.border }}
                        >
                            <div className="flex items-center gap-2 text-gray-700">
                                <FaImage className="text-gray-500" />
                                <h3 className="text-sm font-semibold">
                                    Comprobante de pago
                                </h3>
                            </div>

                            <div className="flex flex-col items-center">
                                {proofUrl ? (
                                    <>
                                        <img
                                            src={proofUrl}
                                            alt="Comprobante"
                                            onClick={() => setShowProof(true)}
                                            className="h-56 object-contain rounded-xl border bg-white shadow cursor-pointer hover:scale-[1.02] transition"
                                        />

                                        <p className="mt-2 text-xs text-gray-500 text-center">
                                            Click para ampliar imagen
                                        </p>
                                    </>
                                ) : (
                                    <div className="h-44 w-full rounded-xl border border-dashed border-slate-300 bg-slate-50 flex flex-col items-center justify-center text-slate-400">
                                        <FaImage className="text-2xl mb-2" />
                                        <span className="text-sm">
                                            Sin comprobante
                                        </span>
                                    </div>
                                )}
                            </div>

                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-4 text-xs md:text-sm">
                                <div className="flex flex-col">
                                    <span className="text-gray-700 font-medium">
                                        Fecha de solicitud
                                    </span>

                                    <span className="text-gray-900 text-sm">
                                        {formattedDate || '—'}
                                    </span>
                                </div>

                                <div className="flex flex-col">
                                    <span className="text-gray-700 font-medium">
                                        Última actualización
                                    </span>

                                    <span className="text-gray-900 text-sm">
                                        {formattedUpdated || '—'}
                                    </span>
                                </div>
                            </div>
                        </section>

                        {/* Comentario */}
                        <section
                            className="bg-white rounded-xl border p-4 space-y-2"
                            style={{ borderColor: UI.border }}
                        >
                            <div className="flex items-center gap-2 text-gray-700">
                                <FaCommentDots className="text-gray-500" />
                                <h3 className="text-sm font-semibold">Comentario</h3>
                            </div>
                            <p className="mt-1 text-xs md:text-sm text-gray-700 whitespace-pre-wrap">
                                {tx.comment || 'Sin comentario'}
                            </p>
                        </section>
                    </div>

                    {/* Footer: acciones */}
                    <div
                        className="px-5 py-3 border-t bg-white flex items-center justify-between gap-3"
                        style={{ borderColor: UI.border }}
                    >
                        <p className="text-[11px] text-gray-500">
                            Solo se pueden aprobar o rechazar transacciones en estado{' '}
                            <span className="font-semibold">Pendiente</span> y moneda{' '}
                            <span className="font-semibold">BOB</span>.
                        </p>

                        {isPending && (
                            <div className="flex items-center gap-2">
                                <button
                                    type="button"
                                    disabled={isSaving || !isBOB}
                                    onClick={() => onReject?.(tx)}
                                    className="px-3 py-1.5 rounded-lg text-xs font-semibold border border-red-500 text-red-600 hover:bg-red-50 disabled:opacity-60 disabled:cursor-not-allowed"
                                >
                                    {isSaving ? 'Procesando...' : 'Rechazar'}
                                </button>
                                <button
                                    type="button"
                                    disabled={isSaving || !isBOB}
                                    onClick={() => onApprove?.(tx)}
                                    className="px-3 py-1.5 rounded-lg text-xs font-semibold text-white hover:opacity-90 disabled:opacity-60 disabled:cursor-not-allowed"
                                    style={{ backgroundColor: UI.primary }}
                                >
                                    {isSaving ? 'Procesando...' : 'Aprobar'}
                                </button>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* OVERLAY PARA AMPLIAR COMPROBANTE */}
            {showProof && proofUrl && (
                <div
                    className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4"
                    onClick={() => setShowProof(false)}
                >
                    <div
                        className="bg-white rounded-2xl shadow-xl p-4 max-w-5xl max-h-[90vh] overflow-auto"
                        onClick={(e) => e.stopPropagation()}
                    >
                        <img
                            src={proofUrl}
                            alt="Comprobante ampliado"
                            className="max-w-full max-h-[80vh] object-contain rounded-lg"
                        />

                        <div className="mt-4 flex justify-end">
                            <button
                                type="button"
                                onClick={() => setShowProof(false)}
                                className="px-4 py-2 rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50"
                            >
                                Cerrar
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </>
    );
}
