// File: src/components/Review/BusinessClaimReview.jsx
'use client';

import {
    useCallback,
    useEffect,
    useMemo,
    useState,
} from 'react';

import {
    FaSearch,
    FaSyncAlt,
} from 'react-icons/fa';

import toast from 'react-hot-toast';

import BusinessClaimCardReview from '@/components/Review/BusinessClaimCardReview';
import BusinessClaimViewReview from '@/components/Review/BusinessClaimViewReview';

import useBusinessClaimRequests from '@/hooks/useBusinessClaimRequests';
import useCategories from '@/hooks/useCategories';
import useMedia from '@/hooks/useMedia';

import {
    BusinessService,
} from '@/services/businessService';

import {
    NotificationsService,
} from '@/services/notificationsService';

import {
    useUser,
} from '@/context/UserContext';

const API_URL =
    process.env.NEXT_PUBLIC_API_URL ??
    'http://localhost:3000';

const UI = {
    primary: '#0077B6',
    border: '#E2E8F0',
};

const STATUS_FILTERS = [
    {
        id: 'pending',
        label: 'Pendientes',
    },
    {
        id: 'approved',
        label: 'Aprobadas',
    },
    {
        id: 'rejected',
        label: 'Rechazadas',
    },
    {
        id: 'all',
        label: 'Todas',
    },
];

// =====================================================
// HELPERS
// =====================================================

function normalizeId(value) {
    if (
        value === undefined ||
        value === null ||
        value === ''
    ) {
        return '';
    }

    return String(value);
}

function getClaimId(claim) {
    return Number(
        claim?.id ??
        claim?.claim_id ??
        claim?._id
    );
}

function getBusinessId(claim) {
    return Number(
        claim?.business_id ??
        claim?.businessId ??
        claim?.business?.id
    );
}

function getClaimantId(claim) {
    return (
        claim?.user_id ??
        claim?.userId ??
        claim?.user?.id ??
        null
    );
}

function getUserDisplayName(user) {
    if (!user) return '';

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
        ''
    );
}

function getBusinessName(claim, business) {
    return (
        business?.name ||
        claim?.business?.name ||
        claim?.business_name ||
        `Negocio #${getBusinessId(claim) || '—'}`
    );
}

function normalizeSingleResponse(response) {
    if (!response) return null;

    if (
        response.data &&
        !Array.isArray(response.data)
    ) {
        return response.data;
    }

    if (
        response.item &&
        typeof response.item === 'object'
    ) {
        return response.item;
    }

    if (
        response.user &&
        typeof response.user === 'object'
    ) {
        return response.user;
    }

    return response;
}

function authHeaders() {
    if (typeof window === 'undefined') {
        return {};
    }

    const token =
        localStorage.getItem('token');

    return token
        ? {
            Authorization: `Bearer ${token}`,
        }
        : {};
}

async function fetchUserById(
    userId,
    signal
) {
    if (!userId) return null;

    const response = await fetch(
        `${API_URL}/users/${userId}`,
        {
            method: 'GET',
            signal,
            cache: 'no-store',
            headers: {
                ...authHeaders(),
            },
        }
    );

    const contentType =
        response.headers.get('content-type') || '';

    const isJSON =
        contentType.includes('application/json');

    let data = null;

    try {
        data = isJSON
            ? await response.json()
            : await response.text();
    } catch (_) {
        data = null;
    }

    if (!response.ok) {
        const message =
            (isJSON &&
                data &&
                (data.message || data.error)) ||
            response.statusText ||
            `HTTP ${response.status}`;

        const error = new Error(
            message ||
            'No se pudo cargar el usuario'
        );

        error.status = response.status;
        error.data = data;

        throw error;
    }

    return normalizeSingleResponse(data);
}

// =====================================================
// SKELETON
// =====================================================

function CardSkeleton() {
    return (
        <div
            className="bg-white border rounded-xl shadow-sm overflow-hidden animate-pulse"
            style={{
                borderColor: UI.border,
            }}
        >
            <div className="h-44 bg-slate-200" />

            <div className="p-4 space-y-3">
                <div className="h-5 bg-slate-200 rounded w-2/3" />
                <div className="h-4 bg-slate-200 rounded w-1/2" />
                <div className="h-4 bg-slate-200 rounded w-3/4" />
                <div className="h-4 bg-slate-200 rounded w-1/3" />
                <div className="h-9 bg-slate-200 rounded mt-3" />
            </div>
        </div>
    );
}

// =====================================================
// COMPONENT
// =====================================================

export default function BusinessClaimReview() {
    const {
        user: currentUser,
    } = useUser();

    const {
        rows,
        loading,
        savingId,
        error,

        statusFilter,
        setStatusFilter,

        fetchByCurrentFilter,
        approveOne,
        rejectOne,
    } = useBusinessClaimRequests({
        autoLoad: false,
        initialStatus: 'pending',
    });

    const {
        categories,
        loadingList: loadingCategories,
    } = useCategories();

    const {
        fetchForBusinessIds,
    } = useMedia();

    const [query, setQuery] =
        useState('');

    const [viewing, setViewing] =
        useState(null);

    const [submitting, setSubmitting] =
        useState(false);

    const [loadingRelations, setLoadingRelations] =
        useState(false);

    const [businessById, setBusinessById] =
        useState({});

    const [userById, setUserById] =
        useState({});

    const [mediaByBusiness, setMediaByBusiness] =
        useState({});

    const senderId =
        currentUser?.id ??
        currentUser?.user_id ??
        currentUser?.uid ??
        null;

    // ===================================================
    // LOAD CLAIMS
    // ===================================================

    useEffect(() => {
        fetchByCurrentFilter().catch((loadError) => {
            console.error(
                '[BusinessClaimReview] Error cargando reclamaciones:',
                loadError
            );

            toast.error(
                loadError?.message ||
                'No se pudieron cargar las reclamaciones'
            );
        });
    }, [fetchByCurrentFilter]);

    // ===================================================
    // CATEGORY HELPERS
    // ===================================================

    const categoryOptions = useMemo(() => {
        return (categories || []).map(
            (category) => ({
                value: category.id,
                label: category.name,
            })
        );
    }, [categories]);

    const getCategoryName = useCallback(
        (business) => {
            if (business?.category?.name) {
                return business.category.name;
            }

            const category = categoryOptions.find(
                (option) =>
                    normalizeId(option.value) ===
                    normalizeId(business?.category_id)
            );

            return category?.label || '—';
        },
        [categoryOptions]
    );

    // ===================================================
    // IDS
    // ===================================================

    const businessIds = useMemo(() => {
        return [
            ...new Set(
                (rows || [])
                    .map(getBusinessId)
                    .filter((id) =>
                        Number.isFinite(id)
                    )
            ),
        ];
    }, [rows]);

    const claimantIds = useMemo(() => {
        return [
            ...new Set(
                (rows || [])
                    .map(getClaimantId)
                    .filter(Boolean)
                    .map(String)
            ),
        ];
    }, [rows]);

    // ===================================================
    // LOAD BUSINESSES AND CLAIMANTS
    // ===================================================

    useEffect(() => {
        if (
            businessIds.length === 0 &&
            claimantIds.length === 0
        ) {
            setBusinessById({});
            setUserById({});
            return;
        }

        const controller =
            new AbortController();

        let mounted = true;

        const loadRelations = async () => {
            setLoadingRelations(true);

            try {
                const businessEntries =
                    await Promise.all(
                        businessIds.map(async (businessId) => {
                            try {
                                const response =
                                    await BusinessService.get(
                                        businessId,
                                        {
                                            signal:
                                                controller.signal,
                                        }
                                    );

                                return [
                                    String(businessId),
                                    normalizeSingleResponse(
                                        response
                                    ),
                                ];
                            } catch (loadError) {
                                if (
                                    loadError?.name !==
                                    'AbortError'
                                ) {
                                    console.error(
                                        `No se pudo cargar negocio ${businessId}:`,
                                        loadError
                                    );
                                }

                                return [
                                    String(businessId),
                                    null,
                                ];
                            }
                        })
                    );

                const userEntries =
                    await Promise.all(
                        claimantIds.map(async (userId) => {
                            try {
                                const user =
                                    await fetchUserById(
                                        userId,
                                        controller.signal
                                    );

                                return [
                                    String(userId),
                                    user,
                                ];
                            } catch (loadError) {
                                if (
                                    loadError?.name !==
                                    'AbortError'
                                ) {
                                    console.error(
                                        `No se pudo cargar usuario ${userId}:`,
                                        loadError
                                    );
                                }

                                return [
                                    String(userId),
                                    null,
                                ];
                            }
                        })
                    );

                if (!mounted) return;

                setBusinessById(
                    Object.fromEntries(
                        businessEntries
                    )
                );

                setUserById(
                    Object.fromEntries(
                        userEntries
                    )
                );
            } finally {
                if (mounted) {
                    setLoadingRelations(false);
                }
            }
        };

        loadRelations();

        return () => {
            mounted = false;
            controller.abort();
        };
    }, [businessIds, claimantIds]);

    // ===================================================
    // LOAD BUSINESS MEDIA
    // ===================================================

    useEffect(() => {
        if (!businessIds.length) {
            setMediaByBusiness({});
            return;
        }

        let mounted = true;

        const loadMedia = async () => {
            try {
                const map =
                    await fetchForBusinessIds(
                        businessIds,
                        'business'
                    );

                if (!mounted) return;

                const mediaObject = {};

                map.forEach((mediaList, id) => {
                    const idString =
                        String(id);

                    const ownMedia = (
                        mediaList || []
                    ).filter(
                        (media) =>
                            String(
                                media?.entity_id ??
                                media?.target_id ??
                                media?.targetId
                            ) === idString
                    );

                    mediaObject[idString] =
                        ownMedia
                            .map(
                                (media) =>
                                    media?.url ||
                                    media?.image_url ||
                                    media?.media_url ||
                                    media?.path ||
                                    media?.fileUrl
                            )
                            .filter(Boolean);
                });

                setMediaByBusiness(
                    mediaObject
                );
            } catch (mediaError) {
                console.error(
                    '[BusinessClaimReview] Error cargando imágenes:',
                    mediaError
                );

                if (mounted) {
                    setMediaByBusiness({});
                }
            }
        };

        loadMedia();

        return () => {
            mounted = false;
        };
    }, [
        businessIds,
        fetchForBusinessIds,
    ]);

    // ===================================================
    // ENRICHED ROWS
    // ===================================================

    const enrichedRows = useMemo(() => {
        return (rows || []).map(
            (claim) => {
                const businessId =
                    getBusinessId(claim);

                const claimantId =
                    getClaimantId(claim);

                const business =
                    businessById[
                    String(businessId)
                    ] ||
                    claim?.business ||
                    null;

                const claimant =
                    userById[
                    String(claimantId)
                    ] ||
                    claim?.user ||
                    null;

                const images =
                    mediaByBusiness[
                    String(businessId)
                    ] || [];

                return {
                    claim,
                    business,
                    claimant,
                    images,
                    categoryName:
                        getCategoryName(
                            business
                        ),
                };
            }
        );
    }, [
        rows,
        businessById,
        userById,
        mediaByBusiness,
        getCategoryName,
    ]);

    // ===================================================
    // SEARCH
    // ===================================================

    const listForUI = useMemo(() => {
        const searchValue =
            String(query || '')
                .trim()
                .toLowerCase();

        if (!searchValue) {
            return enrichedRows;
        }

        return enrichedRows.filter(
            ({
                claim,
                business,
                claimant,
            }) => {
                const claimantName =
                    getUserDisplayName(
                        claimant
                    );

                const values = [
                    claim?.id,
                    claim?.business_id,
                    claim?.user_id,
                    claim?.status,
                    claim?.comment,

                    business?.name,
                    business?.email,
                    business?.phone,
                    business?.address,
                    business?.nit,

                    claimantName,
                    claimant?.username,
                    claimant?.email,
                    claimant?.phone,
                    claimant?.ci,
                ];

                return values
                    .filter(
                        (value) =>
                            value !== undefined &&
                            value !== null
                    )
                    .some((value) =>
                        String(value)
                            .toLowerCase()
                            .includes(searchValue)
                    );
            }
        );
    }, [enrichedRows, query]);

    // ===================================================
    // MODAL
    // ===================================================

    const closeModal = () => {
        if (
            submitting ||
            savingId != null
        ) {
            return;
        }

        setViewing(null);
    };

    const openReview = ({
        claim,
        business,
        user,
    }) => {
        const businessId =
            getBusinessId(claim);

        setViewing({
            claim,
            business,
            claimant: user,
            images:
                mediaByBusiness[
                String(businessId)
                ] || [],
            categoryName:
                getCategoryName(
                    business
                ),
        });
    };

    // ===================================================
    // RELOAD
    // ===================================================

    const handleReload = async () => {
        try {
            await fetchByCurrentFilter();

            toast.success(
                'Lista de reclamaciones actualizada'
            );
        } catch (reloadError) {
            console.error(reloadError);

            toast.error(
                reloadError?.message ||
                'No se pudo recargar la lista'
            );
        }
    };

    // ===================================================
    // APPROVE
    // ===================================================

    const handleApprove = async (
        comment = ''
    ) => {
        const claim =
            viewing?.claim;

        const claimId =
            getClaimId(claim);

        if (
            !claimId ||
            submitting
        ) {
            return;
        }

        setSubmitting(true);

        try {
            await approveOne(
                claimId,
                comment
            );

            const businessName =
                getBusinessName(
                    claim,
                    viewing?.business
                );

            const claimantId =
                getClaimantId(claim);

            if (
                claimantId &&
                senderId
            ) {
                try {
                    await NotificationsService.create({
                        user_id:
                            String(claimantId),

                        sender_id:
                            String(senderId),

                        message:
                            `Tu reclamación del negocio "${businessName}" fue aprobada. El negocio ya fue asociado a tu cuenta ✅`,
                    });
                } catch (notificationError) {
                    console.error(
                        'No se pudo enviar la notificación:',
                        notificationError
                    );
                }
            }

            toast.success(
                'Reclamación aprobada y negocio asociado correctamente'
            );

            setViewing(null);

            await fetchByCurrentFilter();
        } catch (approveError) {
            console.error(
                '[BusinessClaimReview] Error aprobando:',
                approveError
            );

            const message = String(
                approveError?.message || ''
            );

            if (
                message.includes(
                    'Request already reviewed'
                ) ||
                message.includes(
                    'Request not found or already reviewed'
                )
            ) {
                toast.error(
                    'Esta reclamación ya fue procesada'
                );

                setViewing(null);

                await fetchByCurrentFilter();

                return;
            }

            toast.error(
                approveError?.message ||
                'No se pudo aprobar la reclamación'
            );
        } finally {
            setSubmitting(false);
        }
    };

    // ===================================================
    // REJECT
    // ===================================================

    const handleReject = async (
        comment = ''
    ) => {
        const claim =
            viewing?.claim;

        const claimId =
            getClaimId(claim);

        if (
            !claimId ||
            submitting
        ) {
            return;
        }

        setSubmitting(true);

        try {
            await rejectOne(
                claimId,
                comment
            );

            const businessName =
                getBusinessName(
                    claim,
                    viewing?.business
                );

            const claimantId =
                getClaimantId(claim);

            if (
                claimantId &&
                senderId
            ) {
                try {
                    await NotificationsService.create({
                        user_id:
                            String(claimantId),

                        sender_id:
                            String(senderId),

                        message:
                            `Tu reclamación del negocio "${businessName}" fue rechazada ❌`,
                    });
                } catch (notificationError) {
                    console.error(
                        'No se pudo enviar la notificación:',
                        notificationError
                    );
                }
            }

            toast.success(
                'Reclamación rechazada'
            );

            setViewing(null);

            await fetchByCurrentFilter();
        } catch (rejectError) {
            console.error(
                '[BusinessClaimReview] Error rechazando:',
                rejectError
            );

            const message = String(
                rejectError?.message || ''
            );

            if (
                message.includes(
                    'Request already reviewed'
                ) ||
                message.includes(
                    'Request not found or already reviewed'
                )
            ) {
                toast.error(
                    'Esta reclamación ya fue procesada'
                );

                setViewing(null);

                await fetchByCurrentFilter();

                return;
            }

            toast.error(
                rejectError?.message ||
                'No se pudo rechazar la reclamación'
            );
        } finally {
            setSubmitting(false);
        }
    };

    // ===================================================
    // EMPTY TEXT
    // ===================================================

    const emptyText = useMemo(() => {
        switch (statusFilter) {
            case 'pending':
                return 'No hay reclamaciones pendientes de revisión.';

            case 'approved':
                return 'No hay reclamaciones aprobadas que coincidan con el filtro.';

            case 'rejected':
                return 'No hay reclamaciones rechazadas que coincidan con el filtro.';

            case 'all':
            default:
                return 'No hay reclamaciones que coincidan con el filtro.';
        }
    }, [statusFilter]);

    const isLoading =
        loading ||
        loadingRelations;

    // ===================================================
    // VIEW
    // ===================================================

    return (
        <section>
            <div className="mb-4">
                <h2 className="text-2xl font-semibold text-slate-900 mb-1">
                    Reclamaciones de negocios
                </h2>

                <p className="text-slate-600">
                    Revisa la documentación y aprueba o rechaza las solicitudes de propiedad de negocios.
                </p>
            </div>

            {/* FILTROS */}
            <div className="mb-3 flex flex-wrap gap-2">
                {STATUS_FILTERS.map(
                    (filter) => {
                        const active =
                            statusFilter ===
                            filter.id;

                        return (
                            <button
                                key={filter.id}
                                type="button"
                                onClick={() =>
                                    setStatusFilter(
                                        filter.id
                                    )
                                }
                                className={`text-xs sm:text-sm inline-flex items-center px-3 py-1.5 rounded-full border transition font-medium ${active
                                        ? 'bg-white text-[#0077B6]'
                                        : 'bg-slate-50 text-slate-600 hover:bg-slate-100'
                                    }`}
                                style={{
                                    borderColor:
                                        active
                                            ? UI.primary
                                            : UI.border,
                                }}
                            >
                                {filter.label}
                            </button>
                        );
                    }
                )}
            </div>

            {/* BÚSQUEDA Y RECARGA */}
            <div className="mb-4 flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
                <div className="relative flex-1 min-w-[260px]">
                    <FaSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />

                    <input
                        value={query}
                        onChange={(event) =>
                            setQuery(
                                event.target.value
                            )
                        }
                        className="w-full pl-10 pr-3 py-2 text-sm rounded-lg border bg-white outline-none text-slate-900 placeholder:text-slate-400/90 focus:ring-2 focus:ring-[#0077B6]/30 focus:border-[#0077B6]"
                        style={{
                            borderColor: UI.border,
                        }}
                        placeholder="Buscar por negocio, reclamante, correo, comentario o ID…"
                    />
                </div>

                <button
                    type="button"
                    onClick={handleReload}
                    className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-lg font-semibold border bg-[#EFF4FB] text-slate-800 hover:bg-[#E7EEF9] transition"
                    style={{
                        borderColor: UI.border,
                    }}
                    disabled={isLoading}
                >
                    <FaSyncAlt
                        className={`opacity-70 ${isLoading
                                ? 'animate-spin'
                                : ''
                            }`}
                    />

                    Recargar
                </button>
            </div>

            {/* ERROR */}
            {error && (
                <div className="mb-4 px-4 py-3 rounded-lg border border-rose-200 bg-rose-50 text-rose-700 text-sm">
                    {error}
                </div>
            )}

            {/* CARDS */}
            {isLoading &&
                (!rows || rows.length === 0) ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
                    {Array.from({
                        length: 6,
                    }).map((_, index) => (
                        <CardSkeleton
                            key={index}
                        />
                    ))}
                </div>
            ) : listForUI.length > 0 ? (
                <>
                    {loadingCategories && (
                        <p className="text-xs text-slate-500 mb-2">
                            Cargando categorías…
                        </p>
                    )}

                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
                        {listForUI.map(
                            ({
                                claim,
                                business,
                                claimant,
                                images,
                            }) => {
                                const claimId =
                                    getClaimId(claim);

                                return (
                                    <BusinessClaimCardReview
                                        key={claimId}
                                        claim={claim}
                                        business={business}
                                        user={claimant}
                                        imageUrl={
                                            images?.[0] ||
                                            null
                                        }
                                        onEvaluate={
                                            openReview
                                        }
                                    />
                                );
                            }
                        )}
                    </div>
                </>
            ) : (
                <div className="p-6 border rounded-lg bg-white text-slate-500 text-center">
                    {emptyText}
                </div>
            )}

            {/* MODAL */}
            {viewing && (
                <BusinessClaimViewReview
                    claim={viewing.claim}
                    business={
                        viewing.business
                    }
                    claimant={
                        viewing.claimant
                    }
                    images={
                        viewing.images
                    }
                    categoryName={
                        viewing.categoryName
                    }
                    submitting={
                        submitting ||
                        savingId != null
                    }
                    onClose={closeModal}
                    onApprove={
                        handleApprove
                    }
                    onReject={
                        handleReject
                    }
                />
            )}
        </section>
    );
}