// src/components/Review/TransactionCardReview.jsx
'use client';

import {
    FaMoneyBillWave,
    FaUser,
    FaClock,
    FaImage,
    FaCheck,
    FaTimes,
} from 'react-icons/fa';

const UI = {
    primary: '#0077B6',
    border: '#E2E8F0',
};

function getStatusPill(status) {
    const s = String(status || '').toLowerCase();

    if (s === 'approved') {
        return {
            label: 'Aprobada',
            cls: 'bg-green-100 text-green-700 border-green-300',
        };
    }

    if (s === 'rejected') {
        return {
            label: 'Rechazada',
            cls: 'bg-red-100 text-red-700 border-red-300',
        };
    }

    if (s === 'pending') {
        return {
            label: 'Pendiente',
            cls: 'bg-amber-100 text-amber-700 border-amber-300',
        };
    }

    return {
        label: 'Desconocido',
        cls: 'bg-gray-100 text-gray-700 border-gray-300',
    };
}

function getTypeLabel(type) {
    switch (type) {
        case 'subscription':
            return 'Suscripción';

        case 'coin_purchase':
            return 'Compra de Tinku';

        default:
            return type || '—';
    }
}

export default function TransactionCardReview({
    tx,
    user,
    onEvaluate,
    onApprove,
    onReject,
    onImageClick,
    savingId,
}) {
    const statusInfo = getStatusPill(tx.status);
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

    const amount =
        tx.payment?.amount ??
        tx.amount ??
        0;

    const proofUrl =
        tx.proof_url ||
        tx.payment?.proof_url ||
        tx.media?.[0]?.url ||
        '';

    const dateStr =
        tx.createdAt ||
        tx.created_at ||
        tx.payment?.created_at ||
        null;

    const formattedDate = dateStr
        ? new Date(dateStr).toLocaleString('es-BO', {
            dateStyle: 'short',
            timeStyle: 'short',
        })
        : 'Sin fecha';

    const displayUser = user
        ? user.username ||
        `${user.first_name ?? ''} ${user.last_name ?? ''}`.trim() ||
        user.email ||
        String(user.id ?? '')
        : String(tx.userId ?? tx.user_id ?? '—');

    return (
        <div
            className="flex flex-col bg-white border rounded-2xl shadow-sm overflow-hidden"
            style={{ borderColor: UI.border }}
        >
            <div
                className="px-4 py-2 flex items-center justify-between border-b bg-slate-50"
                style={{ borderColor: UI.border }}
            >
                <span
                    className={`px-2 py-1 text-[11px] rounded-full border font-semibold flex items-center gap-1 ${statusInfo.cls}`}
                >
                    <span className="w-2 h-2 rounded-full bg-current" />
                    {statusInfo.label}
                </span>

                <div className="flex items-center gap-3 text-[11px] text-gray-500">
                    <span>{currency}</span>
                    <span>Solicitud #{tx.id}</span>
                </div>
            </div>

            {proofUrl ? (
                <button
                    type="button"
                    onClick={() => onImageClick?.(proofUrl)}
                    className="h-40 bg-slate-100 overflow-hidden"
                    title="Ver comprobante"
                >
                    <img
                        src={proofUrl}
                        alt="Comprobante de pago"
                        className="w-full h-full object-cover hover:scale-105 transition"
                    />
                </button>
            ) : (
                <div className="h-40 bg-slate-100 grid place-items-center text-slate-400">
                    <div className="flex flex-col items-center gap-2">
                        <FaImage />
                        <span className="text-xs">Sin comprobante</span>
                    </div>
                </div>
            )}

            <div className="flex-1 px-4 py-3 space-y-2 text-sm text-gray-700">
                <div className="flex items-start gap-2">
                    <FaMoneyBillWave className="mt-1 text-gray-400" />

                    <div>
                     

                        <p className="text-[11px] text-gray-500">
                            Tipo: {getTypeLabel(tx.type)}
                        </p>

                        <p className="text-[11px] text-gray-500">
                            Pago #{tx.paymentId ?? tx.payment_id ?? '—'}
                        </p>
                    </div>
                </div>

         

                {tx.comment && (
                    <p className="text-[11px] text-gray-600 line-clamp-2">
                        Comentario: {tx.comment}
                    </p>
                )}

                <div className="flex items-center gap-1 text-[11px] text-gray-500 mt-1">
                    <FaClock />
                    <span>{formattedDate}</span>
                </div>
            </div>

            <div className="px-4 pb-3 pt-1 space-y-2">

                <button
                    type="button"
                    onClick={() => onEvaluate?.(tx)}
                    className="w-full rounded-lg bg-[#0077B6] hover:bg-[#005f8c] text-white font-semibold text-sm py-2 transition"
                >
                    Ver detalle
                </button>

                {isPending && (
                    <div className="grid grid-cols-2 gap-2">

                        <button
                            type="button"
                            onClick={() => onApprove?.(tx)}
                            disabled={isSaving}
                            className="inline-flex justify-center items-center gap-2 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-sm py-2 transition disabled:opacity-60"
                        >
                            <FaCheck />
                            Aprobar
                        </button>

                        <button
                            type="button"
                            onClick={() => onReject?.(tx)}
                            disabled={isSaving}
                            className="inline-flex justify-center items-center gap-2 rounded-lg bg-rose-600 hover:bg-rose-700 text-white font-semibold text-sm py-2 transition disabled:opacity-60"
                        >
                            <FaTimes />
                            Rechazar
                        </button>

                    </div>
                )}

            </div>
        </div>
    );
}