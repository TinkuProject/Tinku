// File: src/components/Review/BusinessClaimCardReview.jsx
'use client';

import {
    FaBuilding,
    FaUser,
    FaCalendarAlt,
    FaFileAlt,
    FaCommentAlt,
} from 'react-icons/fa';

const PLACEHOLDER =
    'https://via.placeholder.com/800x400?text=Sin+imagen';

function getStatusInfo(rawStatus) {
    const status = String(rawStatus || '')
        .trim()
        .toLowerCase();

    if (status === 'approved') {
        return {
            label: 'Aprobada',
            bg: 'bg-emerald-100',
            text: 'text-emerald-700',
            border: 'border-emerald-200',
        };
    }

    if (status === 'rejected') {
        return {
            label: 'Rechazada',
            bg: 'bg-rose-100',
            text: 'text-rose-700',
            border: 'border-rose-200',
        };
    }

    return {
        label: 'Pendiente',
        bg: 'bg-amber-100',
        text: 'text-amber-700',
        border: 'border-amber-200',
    };
}

function getBusinessName(claim, business) {
    return (
        business?.name ||
        claim?.business?.name ||
        claim?.business_name ||
        `Negocio #${claim?.business_id ?? '—'}`
    );
}

function getClaimantName(claim, user) {
    if (user) {
        const fullName = [
            user.first_name,
            user.last_name,
        ]
            .filter(Boolean)
            .join(' ')
            .trim();

        return (
            fullName ||
            user.username ||
            user.email ||
            `Usuario ${user.id ?? ''}`
        );
    }

    const claimUser = claim?.user;

    if (claimUser) {
        const fullName = [
            claimUser.first_name,
            claimUser.last_name,
        ]
            .filter(Boolean)
            .join(' ')
            .trim();

        return (
            fullName ||
            claimUser.username ||
            claimUser.email ||
            `Usuario ${claim?.user_id ?? ''}`
        );
    }

    return `Usuario #${claim?.user_id ?? '—'}`;
}

function formatDate(value) {
    if (!value) return 'Sin fecha';

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
        return 'Sin fecha';
    }

    return date.toLocaleString('es-BO', {
        dateStyle: 'short',
        timeStyle: 'short',
    });
}

export default function BusinessClaimCardReview({
    claim,
    business = null,
    user = null,
    imageUrl,
    onEvaluate,
}) {
    const cover =
        imageUrl ||
        business?.image_url ||
        claim?.business?.image_url ||
        PLACEHOLDER;

    const status =
        getStatusInfo(claim?.status);

    const businessName =
        getBusinessName(
            claim,
            business
        );

    const claimantName =
        getClaimantName(
            claim,
            user
        );

    const documents =
        Array.isArray(claim?.documents)
            ? claim.documents
            : [];

    return (
        <article className="relative bg-white border border-[#0077B6] rounded-xl shadow-md overflow-hidden transition hover:shadow-lg">
            <div className="absolute top-2 left-2 z-10">
                <span
                    className={`inline-flex items-center gap-1 px-2 py-1 text-xs font-semibold rounded-full border ${status.bg} ${status.text} ${status.border}`}
                >
                    ● {status.label}
                </span>
            </div>

            <img
                src={cover}
                alt={businessName}
                className="w-full h-44 object-cover"
                loading="lazy"
                decoding="async"
                onError={(event) => {
                    event.currentTarget.src =
                        PLACEHOLDER;
                }}
            />

            <div className="p-4 flex flex-col gap-3">
                <div>
                    <h3
                        className="text-lg font-bold text-[#0077B6] truncate"
                        title={businessName}
                    >
                        {businessName}
                    </h3>

                    <p className="text-sm text-[#0077B6]/80 inline-flex items-center gap-2">
                        <FaBuilding className="opacity-80" />

                        Negocio #{claim?.business_id ?? '—'}
                    </p>
                </div>

                <div className="space-y-2 text-sm">
                    <div className="flex items-start gap-2 text-slate-700">
                        <FaUser className="mt-0.5 shrink-0 text-[#0077B6]" />

                        <div className="min-w-0">
                            <p className="text-xs text-slate-500">
                                Reclamante
                            </p>

                            <p
                                className="font-medium truncate"
                                title={claimantName}
                            >
                                {claimantName}
                            </p>
                        </div>
                    </div>

                    <div className="flex items-center gap-2 text-slate-700">
                        <FaCalendarAlt className="shrink-0 text-[#0077B6]" />

                        <span className="text-xs">
                            {formatDate(
                                claim?.created_at ??
                                claim?.createdAt
                            )}
                        </span>
                    </div>

                    <div className="flex items-center gap-2 text-slate-700">
                        <FaFileAlt className="shrink-0 text-[#0077B6]" />

                        <span className="text-xs">
                            {documents.length}{' '}
                            {documents.length === 1
                                ? 'documento'
                                : 'documentos'}
                        </span>
                    </div>

                    {claim?.comment && (
                        <div className="flex items-start gap-2 text-slate-700">
                            <FaCommentAlt className="mt-0.5 shrink-0 text-[#0077B6]" />

                            <p className="text-xs line-clamp-2">
                                {claim.comment}
                            </p>
                        </div>
                    )}
                </div>

                <button
                    type="button"
                    onClick={() =>
                        onEvaluate?.({
                            claim,
                            business,
                            user,
                        })
                    }
                    className="w-full bg-[#0077B6] hover:bg-[#005f90] text-white font-semibold py-2 rounded-lg transition"
                >
                    Revisar reclamación
                </button>
            </div>
        </article>
    );
}