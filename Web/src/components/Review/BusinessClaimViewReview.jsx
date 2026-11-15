// File: src/components/Review/BusinessClaimViewReview.jsx
'use client';

import {
    useEffect,
    useMemo,
    useState,
} from 'react';

import {
    FaTimes,
    FaGlobe,
    FaPhone,
    FaEnvelope,
    FaMapMarkerAlt,
    FaExternalLinkAlt,
    FaUser,
    FaIdBadge,
    FaInfoCircle,
    FaCheckCircle,
    FaClock,
    FaBan,
    FaFileAlt,
    FaBuilding,
    FaCommentAlt,
    FaDownload,
    FaImage,
} from 'react-icons/fa';

const UI = {
    primary: '#0077B6',
    border: '#E2E8F0',
    chipApproved: '#DCFCE7',
    chipPending: '#FEF3C7',
    chipRejected: '#FEE2E2',
};

const PLACEHOLDER =
    'https://via.placeholder.com/1280x720?text=Sin+imagen';

// =====================================================
// HELPERS
// =====================================================

function ensureHttp(url) {
    if (!url) return '';

    if (/^https?:\/\//i.test(url)) {
        return url;
    }

    return `https://${url}`;
}

function osmEmbedUrl(
    lat,
    lng,
    zoom = 14
) {
    const bbox = [
        lng - 0.02,
        lat - 0.02,
        lng + 0.02,
        lat + 0.02,
    ].join('%2C');

    return (
        'https://www.openstreetmap.org/export/embed.html' +
        `?bbox=${bbox}` +
        '&layer=mapnik' +
        `&marker=${lat}%2C${lng}` +
        `&zoom=${zoom}`
    );
}

function displayNameFrom(user) {
    if (!user) return '—';

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
        user.name ||
        '—'
    );
}

function normalizeDocuments(documents) {
    if (Array.isArray(documents)) {
        return documents.filter(Boolean);
    }

    if (typeof documents === 'string') {
        try {
            const parsed = JSON.parse(documents);

            if (Array.isArray(parsed)) {
                return parsed.filter(Boolean);
            }

            return documents
                ? [documents]
                : [];
        } catch (_) {
            return documents
                ? [documents]
                : [];
        }
    }

    return [];
}

function isImageDocument(url) {
    const cleanUrl = String(url || '')
        .split('?')[0]
        .toLowerCase();

    return /\.(jpg|jpeg|png|webp|gif|bmp|svg)$/i.test(
        cleanUrl
    );
}

function isPdfDocument(url) {
    const cleanUrl = String(url || '')
        .split('?')[0]
        .toLowerCase();

    return cleanUrl.endsWith('.pdf');
}

function getDocumentName(
    url,
    index
) {
    try {
        const pathname =
            new URL(url).pathname;

        const lastPart =
            pathname.split('/').pop();

        if (lastPart) {
            return decodeURIComponent(
                lastPart
            );
        }
    } catch (_) {
        // URL posiblemente relativa
    }

    return `Documento ${index + 1}`;
}

function formatDate(value) {
    if (!value) return '—';

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
        return '—';
    }

    return date.toLocaleString(
        'es-BO',
        {
            dateStyle: 'medium',
            timeStyle: 'short',
        }
    );
}

function StatusBadge({ status }) {
    const normalized = String(
        status || 'pending'
    )
        .trim()
        .toLowerCase();

    if (normalized === 'approved') {
        return (
            <span
                className="text-xs font-semibold px-3 py-1 rounded-full"
                style={{
                    background:
                        UI.chipApproved,
                    color: '#166534',
                }}
            >
                Aprobada
            </span>
        );
    }

    if (normalized === 'rejected') {
        return (
            <span
                className="text-xs font-semibold px-3 py-1 rounded-full"
                style={{
                    background:
                        UI.chipRejected,
                    color: '#991B1B',
                }}
            >
                Rechazada
            </span>
        );
    }

    return (
        <span
            className="text-xs font-semibold px-3 py-1 rounded-full"
            style={{
                background:
                    UI.chipPending,
                color: '#92400E',
            }}
        >
            Pendiente
        </span>
    );
}

// =====================================================
// COMPONENT
// =====================================================

export default function BusinessClaimViewReview({
    claim,
    business,
    claimant,
    images = [],
    categoryName = '—',
    submitting = false,
    onClose,
    onApprove,
    onReject,
}) {
    const gallery =
        Array.isArray(images) &&
            images.length > 0
            ? images
            : [PLACEHOLDER];

    const documents =
        normalizeDocuments(
            claim?.documents
        );

    const [currentImage, setCurrentImage] =
        useState(0);

    const [reviewComment, setReviewComment] =
        useState('');

    const [documentPreview, setDocumentPreview] =
        useState(null);

    useEffect(() => {
        setCurrentImage(0);
        setReviewComment('');
        setDocumentPreview(null);
    }, [claim?.id]);

    useEffect(() => {
        const handleEscape = (
            event
        ) => {
            if (
                event.key === 'Escape' &&
                !submitting
            ) {
                if (documentPreview) {
                    setDocumentPreview(null);
                    return;
                }

                onClose?.();
            }
        };

        window.addEventListener(
            'keydown',
            handleEscape
        );

        return () => {
            window.removeEventListener(
                'keydown',
                handleEscape
            );
        };
    }, [
        submitting,
        onClose,
        documentPreview,
    ]);

    const meta = useMemo(() => {
        const location =
            business?.location;

        const coordinates =
            location?.coordinates;

        const latitude = Number(
            location?.latitude ??
            location?.lat ??
            coordinates?.[1] ??
            business?.latitude ??
            business?.lat ??
            -17.3895
        );

        const longitude = Number(
            location?.longitude ??
            location?.lng ??
            coordinates?.[0] ??
            business?.longitude ??
            business?.lng ??
            -66.1568
        );

        return {
            latitude:
                Number.isFinite(latitude)
                    ? latitude
                    : -17.3895,

            longitude:
                Number.isFinite(longitude)
                    ? longitude
                    : -66.1568,

            status: String(
                claim?.status ||
                'pending'
            )
                .trim()
                .toLowerCase(),
        };
    }, [
        claim,
        business,
    ]);

    const canEvaluate =
        meta.status === 'pending';

    const businessName =
        business?.name ||
        claim?.business?.name ||
        claim?.business_name ||
        `Negocio #${claim?.business_id ?? '—'}`;

    const claimantName =
        displayNameFrom(
            claimant ||
            claim?.user
        );

    const claimId =
        claim?.id ??
        claim?.claim_id ??
        '—';

    const businessId =
        claim?.business_id ??
        claim?.businessId ??
        business?.id ??
        '—';

    const claimantId =
        claim?.user_id ??
        claim?.userId ??
        claimant?.id ??
        '—';

    const handleApprove = async () => {
        if (
            submitting ||
            !canEvaluate
        ) {
            return;
        }

        await onApprove?.(
            reviewComment.trim()
        );
    };

    const handleReject = async () => {
        if (
            submitting ||
            !canEvaluate
        ) {
            return;
        }

        const comment =
            reviewComment.trim();

        if (!comment) {
            window.alert(
                'Ingresa un comentario indicando el motivo del rechazo.'
            );

            return;
        }

        await onReject?.(
            comment
        );
    };

    return (
        <>
            <div className="fixed inset-0 z-50">
                <div
                    className="absolute inset-0 bg-black/50"
                    onClick={() => {
                        if (!submitting) {
                            onClose?.();
                        }
                    }}
                />

                <div className="absolute inset-0 grid place-items-center p-3 md:p-6">
                    <div
                        className="w-full max-w-7xl bg-white rounded-xl shadow-2xl border overflow-hidden"
                        style={{
                            borderColor: UI.border,
                        }}
                    >
                        {/* HEADER */}
                        <header
                            className="px-4 md:px-6 py-4 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4"
                            style={{
                                borderBottom:
                                    `1px solid ${UI.border}`,
                                background: '#F8FAFC',
                            }}
                        >
                            <div className="min-w-0">
                                <div className="flex items-center gap-2">
                                    <FaBuilding className="text-[#0077B6]" />

                                    <h2 className="text-xl md:text-2xl font-bold text-slate-900 truncate">
                                        {businessName}
                                    </h2>
                                </div>

                                <p className="mt-1 text-sm text-[#0077B6] font-medium">
                                    Reclamación #{claimId}
                                    {' · '}
                                    {categoryName}
                                    {' · '}
                                    {business?.business_type ||
                                        '—'}
                                </p>
                            </div>

                            <div className="flex flex-wrap items-center gap-2">
                                <StatusBadge
                                    status={meta.status}
                                />

                                {canEvaluate && (
                                    <>
                                        <button
                                            type="button"
                                            onClick={
                                                handleApprove
                                            }
                                            disabled={
                                                submitting
                                            }
                                            className="inline-flex items-center gap-2 px-3 py-2 rounded-md text-white font-semibold bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 disabled:cursor-not-allowed transition"
                                        >
                                            <FaCheckCircle />

                                            {submitting
                                                ? 'Procesando…'
                                                : 'Aprobar'}
                                        </button>

                                        <button
                                            type="button"
                                            onClick={
                                                handleReject
                                            }
                                            disabled={
                                                submitting
                                            }
                                            className="inline-flex items-center gap-2 px-3 py-2 rounded-md text-white font-semibold bg-rose-600 hover:bg-rose-700 disabled:opacity-60 disabled:cursor-not-allowed transition"
                                        >
                                            <FaBan />

                                            {submitting
                                                ? 'Procesando…'
                                                : 'Rechazar'}
                                        </button>
                                    </>
                                )}

                                <button
                                    type="button"
                                    onClick={onClose}
                                    disabled={
                                        submitting
                                    }
                                    className="inline-flex items-center justify-center w-10 h-10 rounded-full border text-slate-700 hover:bg-slate-100 disabled:opacity-60"
                                    title="Cerrar"
                                    aria-label="Cerrar"
                                >
                                    <FaTimes />
                                </button>
                            </div>
                        </header>

                        {/* CONTENT */}
                        <div className="p-4 md:p-6 grid grid-cols-1 xl:grid-cols-3 gap-6 max-h-[78vh] overflow-y-auto">
                            {/* COLUMNA PRINCIPAL */}
                            <div className="xl:col-span-2 space-y-5">
                                {/* GALERÍA NEGOCIO */}
                                <section
                                    className="rounded-lg overflow-hidden border"
                                    style={{
                                        borderColor:
                                            UI.border,
                                    }}
                                >
                                    <img
                                        src={
                                            gallery[
                                            currentImage
                                            ] ||
                                            PLACEHOLDER
                                        }
                                        alt={businessName}
                                        className="w-full h-64 md:h-80 object-cover bg-slate-100"
                                        onError={(
                                            event
                                        ) => {
                                            event.currentTarget.src =
                                                PLACEHOLDER;
                                        }}
                                    />

                                    {gallery.length > 1 && (
                                        <div className="p-3 grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 gap-2 bg-white">
                                            {gallery.map(
                                                (
                                                    url,
                                                    index
                                                ) => (
                                                    <button
                                                        key={`${url}-${index}`}
                                                        type="button"
                                                        className={`relative aspect-[4/3] rounded-md overflow-hidden border ${index ===
                                                                currentImage
                                                                ? 'ring-2 ring-[#0077B6]'
                                                                : 'hover:opacity-90'
                                                            }`}
                                                        style={{
                                                            borderColor:
                                                                UI.border,
                                                        }}
                                                        onClick={() =>
                                                            setCurrentImage(
                                                                index
                                                            )
                                                        }
                                                    >
                                                        <img
                                                            src={url}
                                                            alt={`Imagen ${index + 1
                                                                }`}
                                                            className="w-full h-full object-cover"
                                                            onError={(
                                                                event
                                                            ) => {
                                                                event.currentTarget.src =
                                                                    PLACEHOLDER;
                                                            }}
                                                        />
                                                    </button>
                                                )
                                            )}
                                        </div>
                                    )}
                                </section>

                                {/* DATOS DEL NEGOCIO */}
                                <section
                                    className="bg-white rounded-lg border p-4"
                                    style={{
                                        borderColor:
                                            UI.border,
                                    }}
                                >
                                    <div className="flex items-center gap-2 mb-4 text-slate-800">
                                        <FaInfoCircle />

                                        <h3 className="font-semibold">
                                            Información del negocio
                                        </h3>
                                    </div>

                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-3 text-sm">
                                        <Row
                                            label="ID"
                                            value={
                                                businessId
                                            }
                                            icon={
                                                <FaIdBadge className="text-slate-400" />
                                            }
                                        />

                                        <Row
                                            label="Categoría"
                                            value={
                                                categoryName
                                            }
                                        />

                                        <Row
                                            label="Tipo"
                                            value={
                                                business?.business_type ||
                                                '—'
                                            }
                                        />

                                        <Row
                                            label="NIT"
                                            value={
                                                business?.nit ||
                                                '—'
                                            }
                                        />

                                        <Row
                                            label="Email"
                                            value={
                                                business?.email ||
                                                '—'
                                            }
                                            render={(
                                                value
                                            ) =>
                                                value !==
                                                    '—' ? (
                                                    <a
                                                        href={`mailto:${value}`}
                                                        className="inline-flex items-center gap-2 text-slate-700 hover:underline break-all"
                                                    >
                                                        <FaEnvelope />
                                                        {value}
                                                    </a>
                                                ) : (
                                                    '—'
                                                )
                                            }
                                        />

                                        <Row
                                            label="Teléfono"
                                            value={
                                                business?.phone ||
                                                '—'
                                            }
                                            render={(
                                                value
                                            ) =>
                                                value !==
                                                    '—' ? (
                                                    <a
                                                        href={`tel:${value}`}
                                                        className="inline-flex items-center gap-2 text-slate-700 hover:underline"
                                                    >
                                                        <FaPhone />
                                                        {value}
                                                    </a>
                                                ) : (
                                                    '—'
                                                )
                                            }
                                        />

                                        <Row
                                            label="Website"
                                            value={
                                                business?.website ||
                                                '—'
                                            }
                                            render={(
                                                value
                                            ) =>
                                                value !==
                                                    '—' ? (
                                                    <a
                                                        href={ensureHttp(
                                                            value
                                                        )}
                                                        target="_blank"
                                                        rel="noreferrer"
                                                        className="inline-flex items-center gap-2 text-[#0077B6] hover:underline break-all"
                                                    >
                                                        <FaGlobe />
                                                        {value}
                                                        <FaExternalLinkAlt className="opacity-70" />
                                                    </a>
                                                ) : (
                                                    '—'
                                                )
                                            }
                                        />

                                        <Row
                                            label="Dirección"
                                            value={
                                                business?.address ||
                                                '—'
                                            }
                                            icon={
                                                <FaMapMarkerAlt className="text-[#0077B6]" />
                                            }
                                        />

                                        <Row
                                            label="Coordenadas"
                                            value={`${meta.latitude.toFixed(
                                                5
                                            )}, ${meta.longitude.toFixed(
                                                5
                                            )}`}
                                        />
                                    </div>

                                    <div className="mt-5">
                                        <p className="text-sm font-medium text-slate-700 mb-1">
                                            Descripción
                                        </p>

                                        <p className="text-slate-700 whitespace-pre-line">
                                            {business?.description ||
                                                '—'}
                                        </p>
                                    </div>
                                </section>

                                {/* DOCUMENTOS */}
                                <section
                                    className="bg-white rounded-lg border p-4"
                                    style={{
                                        borderColor:
                                            UI.border,
                                    }}
                                >
                                    <div className="flex items-center justify-between gap-3 mb-4">
                                        <div className="flex items-center gap-2 text-slate-800">
                                            <FaFileAlt />

                                            <h3 className="font-semibold">
                                                Documentos presentados
                                            </h3>
                                        </div>

                                        <span className="text-xs px-2 py-1 rounded-full bg-slate-100 text-slate-600">
                                            {documents.length}{' '}
                                            {documents.length ===
                                                1
                                                ? 'documento'
                                                : 'documentos'}
                                        </span>
                                    </div>

                                    {documents.length ===
                                        0 ? (
                                        <div className="py-8 text-center text-slate-500 text-sm">
                                            No se adjuntaron documentos.
                                        </div>
                                    ) : (
                                        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                                            {documents.map(
                                                (
                                                    documentUrl,
                                                    index
                                                ) => {
                                                    const image =
                                                        isImageDocument(
                                                            documentUrl
                                                        );

                                                    const pdf =
                                                        isPdfDocument(
                                                            documentUrl
                                                        );

                                                    const name =
                                                        getDocumentName(
                                                            documentUrl,
                                                            index
                                                        );

                                                    return (
                                                        <article
                                                            key={`${documentUrl}-${index}`}
                                                            className="border rounded-lg overflow-hidden bg-slate-50"
                                                            style={{
                                                                borderColor:
                                                                    UI.border,
                                                            }}
                                                        >
                                                            {image ? (
                                                                <button
                                                                    type="button"
                                                                    onClick={() =>
                                                                        setDocumentPreview(
                                                                            documentUrl
                                                                        )
                                                                    }
                                                                    className="block w-full h-36 bg-slate-100 overflow-hidden"
                                                                >
                                                                    <img
                                                                        src={
                                                                            documentUrl
                                                                        }
                                                                        alt={
                                                                            name
                                                                        }
                                                                        className="w-full h-full object-cover hover:scale-105 transition"
                                                                    />
                                                                </button>
                                                            ) : (
                                                                <div className="h-24 grid place-items-center bg-slate-100 text-slate-500">
                                                                    {pdf ? (
                                                                        <FaFileAlt className="text-4xl text-rose-500" />
                                                                    ) : (
                                                                        <FaFileAlt className="text-4xl text-sky-600" />
                                                                    )}
                                                                </div>
                                                            )}

                                                            <div className="p-3">
                                                                <p
                                                                    className="text-sm font-medium text-slate-800 truncate"
                                                                    title={
                                                                        name
                                                                    }
                                                                >
                                                                    {name}
                                                                </p>

                                                                <div className="mt-2 flex flex-wrap gap-2">
                                                                    {image && (
                                                                        <button
                                                                            type="button"
                                                                            onClick={() =>
                                                                                setDocumentPreview(
                                                                                    documentUrl
                                                                                )
                                                                            }
                                                                            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-md bg-[#0077B6] text-white text-xs font-semibold hover:bg-[#005f90]"
                                                                        >
                                                                            <FaImage />
                                                                            Ver
                                                                        </button>
                                                                    )}

                                                                    <a
                                                                        href={
                                                                            documentUrl
                                                                        }
                                                                        target="_blank"
                                                                        rel="noreferrer"
                                                                        className="inline-flex items-center gap-2 px-3 py-1.5 rounded-md border bg-white text-slate-700 text-xs font-semibold hover:bg-slate-100"
                                                                        style={{
                                                                            borderColor:
                                                                                UI.border,
                                                                        }}
                                                                    >
                                                                        <FaExternalLinkAlt />
                                                                        Abrir
                                                                    </a>

                                                                    <a
                                                                        href={
                                                                            documentUrl
                                                                        }
                                                                        target="_blank"
                                                                        rel="noreferrer"
                                                                        download
                                                                        className="inline-flex items-center gap-2 px-3 py-1.5 rounded-md border bg-white text-slate-700 text-xs font-semibold hover:bg-slate-100"
                                                                        style={{
                                                                            borderColor:
                                                                                UI.border,
                                                                        }}
                                                                    >
                                                                        <FaDownload />
                                                                        Descargar
                                                                    </a>
                                                                </div>
                                                            </div>
                                                        </article>
                                                    );
                                                }
                                            )}
                                        </div>
                                    )}
                                </section>
                            </div>

                            {/* COLUMNA DERECHA */}
                            <aside className="space-y-5">
                                {/* RECLAMANTE */}
                                <section
                                    className="bg-white rounded-lg border p-4"
                                    style={{
                                        borderColor:
                                            UI.border,
                                    }}
                                >
                                    <div className="flex items-center gap-2 mb-4 text-slate-800">
                                        <FaUser className="text-[#0077B6]" />

                                        <h3 className="font-semibold">
                                            Usuario reclamante
                                        </h3>
                                    </div>

                                    <div className="space-y-3 text-sm">
                                        <Row
                                            label="Nombre"
                                            value={
                                                claimantName
                                            }
                                        />

                                        <Row
                                            label="ID"
                                            value={
                                                claimantId
                                            }
                                        />

                                        <Row
                                            label="Username"
                                            value={
                                                claimant?.username ||
                                                claim?.user
                                                    ?.username ||
                                                '—'
                                            }
                                        />

                                        <Row
                                            label="Correo"
                                            value={
                                                claimant?.email ||
                                                claim?.user
                                                    ?.email ||
                                                '—'
                                            }
                                        />

                                        <Row
                                            label="Teléfono"
                                            value={
                                                claimant?.phone ||
                                                claim?.user
                                                    ?.phone ||
                                                '—'
                                            }
                                        />

                                        <Row
                                            label="CI"
                                            value={
                                                claimant?.ci ||
                                                claim?.user?.ci ||
                                                '—'
                                            }
                                        />
                                    </div>
                                </section>

                                {/* SOLICITUD */}
                                <section
                                    className="bg-white rounded-lg border p-4"
                                    style={{
                                        borderColor:
                                            UI.border,
                                    }}
                                >
                                    <div className="flex items-center gap-2 mb-4 text-slate-800">
                                        <FaClock className="text-[#0077B6]" />

                                        <h3 className="font-semibold">
                                            Datos de la solicitud
                                        </h3>
                                    </div>

                                    <div className="space-y-3 text-sm">
                                        <Row
                                            label="ID"
                                            value={
                                                claimId
                                            }
                                        />

                                        <Row
                                            label="Estado"
                                            value={
                                                meta.status ===
                                                    'approved'
                                                    ? 'Aprobada'
                                                    : meta.status ===
                                                        'rejected'
                                                        ? 'Rechazada'
                                                        : 'Pendiente'
                                            }
                                        />

                                        <Row
                                            label="Creada"
                                            value={formatDate(
                                                claim?.created_at ??
                                                claim?.createdAt
                                            )}
                                        />

                                        <Row
                                            label="Revisada"
                                            value={formatDate(
                                                claim?.reviewed_at ??
                                                claim?.reviewedAt
                                            )}
                                        />

                                        <Row
                                            label="Revisada por"
                                            value={
                                                claim?.reviewed_by ??
                                                claim?.reviewedBy ??
                                                '—'
                                            }
                                        />
                                    </div>
                                </section>

                                {/* COMENTARIO DEL RECLAMANTE */}
                                <section
                                    className="bg-white rounded-lg border p-4"
                                    style={{
                                        borderColor:
                                            UI.border,
                                    }}
                                >
                                    <div className="flex items-center gap-2 mb-3 text-slate-800">
                                        <FaCommentAlt className="text-[#0077B6]" />

                                        <h3 className="font-semibold">
                                            Comentario de la reclamación
                                        </h3>
                                    </div>

                                    <p className="text-sm text-slate-700 whitespace-pre-line">
                                        {claim?.comment ||
                                            'El usuario no agregó ningún comentario.'}
                                    </p>
                                </section>

                                {/* COMENTARIO ADMIN */}
                                {canEvaluate && (
                                    <section
                                        className="bg-white rounded-lg border p-4"
                                        style={{
                                            borderColor:
                                                UI.border,
                                        }}
                                    >
                                        <label
                                            htmlFor="claim-review-comment"
                                            className="block text-sm font-semibold text-slate-800 mb-2"
                                        >
                                            Comentario de revisión
                                        </label>

                                        <textarea
                                            id="claim-review-comment"
                                            value={
                                                reviewComment
                                            }
                                            onChange={(
                                                event
                                            ) =>
                                                setReviewComment(
                                                    event.target
                                                        .value
                                                )
                                            }
                                            rows={4}
                                            maxLength={500}
                                            disabled={
                                                submitting
                                            }
                                            placeholder="Opcional al aprobar. Obligatorio para indicar el motivo del rechazo."
                                            className="w-full border border-slate-300 rounded-lg p-3 text-sm text-slate-800 resize-none focus:outline-none focus:ring-2 focus:ring-[#0077B6]/30 focus:border-[#0077B6] disabled:bg-slate-100"
                                        />

                                        <p className="mt-1 text-right text-xs text-slate-500">
                                            {
                                                reviewComment.length
                                            }
                                            /500
                                        </p>

                                        <div className="mt-3 grid grid-cols-2 gap-2">
                                            <button
                                                type="button"
                                                onClick={
                                                    handleApprove
                                                }
                                                disabled={
                                                    submitting
                                                }
                                                className="inline-flex justify-center items-center gap-2 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-sm py-2.5 disabled:opacity-60"
                                            >
                                                <FaCheckCircle />
                                                Aprobar
                                            </button>

                                            <button
                                                type="button"
                                                onClick={
                                                    handleReject
                                                }
                                                disabled={
                                                    submitting
                                                }
                                                className="inline-flex justify-center items-center gap-2 rounded-lg bg-rose-600 hover:bg-rose-700 text-white font-semibold text-sm py-2.5 disabled:opacity-60"
                                            >
                                                <FaBan />
                                                Rechazar
                                            </button>
                                        </div>
                                    </section>
                                )}

                                {/* MAPA */}
                                <section
                                    className="bg-white rounded-lg border overflow-hidden"
                                    style={{
                                        borderColor:
                                            UI.border,
                                    }}
                                >
                                    <div
                                        className="px-4 py-2 text-sm font-semibold text-slate-700 border-b"
                                        style={{
                                            borderColor:
                                                UI.border,
                                        }}
                                    >
                                        Ubicación
                                    </div>

                                    <div className="h-56">
                                        <iframe
                                            title="Ubicación del negocio"
                                            className="w-full h-full"
                                            loading="lazy"
                                            referrerPolicy="no-referrer-when-downgrade"
                                            src={osmEmbedUrl(
                                                meta.latitude,
                                                meta.longitude
                                            )}
                                        />
                                    </div>

                                    <div className="px-4 py-3 text-xs text-slate-600">
                                        Lat:{' '}
                                        <b>
                                            {meta.latitude.toFixed(
                                                5
                                            )}
                                        </b>
                                        {' · '}
                                        Lng:{' '}
                                        <b>
                                            {meta.longitude.toFixed(
                                                5
                                            )}
                                        </b>
                                    </div>
                                </section>
                            </aside>
                        </div>
                    </div>
                </div>
            </div>

            {/* PREVIEW DE DOCUMENTO */}
            {documentPreview && (
                <div
                    className="fixed inset-0 z-[60] flex items-center justify-center bg-black/75 p-4"
                    onClick={() =>
                        setDocumentPreview(
                            null
                        )
                    }
                >
                    <div
                        className="relative max-w-6xl max-h-[92vh]"
                        onClick={(event) =>
                            event.stopPropagation()
                        }
                    >
                        <img
                            src={documentPreview}
                            alt="Documento de la reclamación"
                            className="max-w-[92vw] max-h-[88vh] object-contain rounded-lg bg-white shadow-2xl"
                        />

                        <button
                            type="button"
                            onClick={() =>
                                setDocumentPreview(
                                    null
                                )
                            }
                            className="absolute -top-3 -right-3 w-10 h-10 inline-flex items-center justify-center rounded-full bg-white text-slate-800 shadow-lg hover:bg-slate-100"
                            aria-label="Cerrar documento"
                        >
                            <FaTimes />
                        </button>
                    </div>
                </div>
            )}
        </>
    );
}

// =====================================================
// ROW
// =====================================================

function Row({
    label,
    value,
    icon,
    render,
}) {
    const content = render
        ? render(value)
        : value;

    return (
        <div className="grid grid-cols-[115px_1fr] items-start gap-3">
            <div className="text-slate-500 font-medium flex items-center gap-2">
                {icon}
                {label}
            </div>

            <div className="text-slate-800 min-w-0 break-words">
                {content ?? '—'}
            </div>
        </div>
    );
}