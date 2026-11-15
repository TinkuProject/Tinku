// src/services/businessClaimRequestsService.js

const API_URL =
    process.env.NEXT_PUBLIC_API_URL ??
    'http://localhost:3000';

const jsonHeaders = {
    'Content-Type': 'application/json',
};

// =====================================================
// AUTH
// =====================================================

function getToken() {
    if (typeof window === 'undefined') return null;

    return localStorage.getItem('token');
}

function authHeaders() {
    const token = getToken();

    return token
        ? {
            Authorization: `Bearer ${token}`,
        }
        : {};
}

// =====================================================
// HTTP
// =====================================================

async function request(
    path,
    {
        method = 'GET',
        body,
        headers,
        signal,
    } = {}
) {
    const res = await fetch(`${API_URL}${path}`, {
        method,
        signal,
        cache: 'no-store',
        headers: {
            ...(body ? jsonHeaders : {}),
            ...authHeaders(),
            ...(headers || {}),
        },
        body:
            body !== undefined
                ? JSON.stringify(body)
                : undefined,
    });

    const contentType =
        res.headers.get('content-type') || '';

    const isJSON =
        contentType.includes('application/json');

    let data = null;

    try {
        data = isJSON
            ? await res.json()
            : await res.text();
    } catch (_) {
        data = null;
    }

    if (!res.ok) {
        const message =
            (isJSON &&
                data &&
                (data.message ||
                    data.error ||
                    data.details)) ||
            res.statusText ||
            `HTTP ${res.status}`;

        const err = new Error(
            message ||
            'No se pudo completar la solicitud'
        );

        err.status = res.status;
        err.data = data;

        throw err;
    }

    return data;
}

// =====================================================
// QUERY STRING
// =====================================================

function qs(params = {}) {
    const query = new URLSearchParams();

    Object.entries(params).forEach(
        ([key, value]) => {
            if (
                value === undefined ||
                value === null ||
                value === ''
            ) {
                return;
            }

            query.set(key, String(value));
        }
    );

    const value = query.toString();

    return value ? `?${value}` : '';
}

// =====================================================
// NORMALIZERS
// =====================================================

function toArray(response) {
    if (Array.isArray(response)) {
        return response;
    }

    if (Array.isArray(response?.data)) {
        return response.data;
    }

    if (Array.isArray(response?.items)) {
        return response.items;
    }

    if (Array.isArray(response?.results)) {
        return response.results;
    }

    return [];
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

function normalizeClaim(item) {
    if (!item || typeof item !== 'object') {
        return item;
    }

    return {
        ...item,

        id: Number(item.id),

        business_id: Number(
            item.business_id ??
            item.businessId
        ),

        user_id:
            item.user_id ??
            item.userId ??
            null,

        status: String(
            item.status || 'pending'
        ).toLowerCase(),

        comment:
            item.comment ??
            null,

        documents: normalizeDocuments(
            item.documents
        ),

        reviewed_by:
            item.reviewed_by ??
            item.reviewedBy ??
            null,

        created_at:
            item.created_at ??
            item.createdAt ??
            null,

        reviewed_at:
            item.reviewed_at ??
            item.reviewedAt ??
            null,
    };
}

function normalizeList(response) {
    return toArray(response)
        .map(normalizeClaim)
        .filter(Boolean);
}

// =====================================================
// SERVICE
// =====================================================

export const BusinessClaimRequestsService = {
    // ===================================================
    // PARTNER
    // ===================================================

    create(payload, opts = {}) {
        if (!payload?.business_id) {
            throw new Error(
                'business_id is required'
            );
        }

        const documents = Array.isArray(
            payload.documents
        )
            ? payload.documents.filter(Boolean)
            : [];

        if (documents.length === 0) {
            throw new Error(
                'Debe adjuntar al menos un documento'
            );
        }

        return request(
            '/business-claim-requests',
            {
                method: 'POST',
                body: {
                    business_id: Number(
                        payload.business_id
                    ),

                    comment:
                        String(
                            payload.comment || ''
                        ).trim() || undefined,

                    documents,
                },
                ...opts,
            }
        ).then(normalizeClaim);
    },

    getMine(
        params = {},
        opts = {}
    ) {
        return request(
            `/business-claim-requests/me${qs(
                {
                    limit: params.limit,
                    offset: params.offset,
                }
            )}`,
            opts
        ).then(normalizeList);
    },

    // ===================================================
    // ADMIN / MASTER
    // ===================================================

    getAll(
        params = {},
        opts = {}
    ) {
        return request(
            `/business-claim-requests${qs(
                {
                    limit: params.limit,
                    offset: params.offset,
                }
            )}`,
            opts
        ).then(normalizeList);
    },

    getPending(opts = {}) {
        return request(
            '/business-claim-requests/pending',
            opts
        ).then(normalizeList);
    },

    review(
        id,
        payload,
        opts = {}
    ) {
        if (!id) {
            throw new Error(
                'id is required'
            );
        }

        const status = String(
            payload?.status || ''
        )
            .trim()
            .toLowerCase();

        if (
            status !== 'approved' &&
            status !== 'rejected'
        ) {
            throw new Error(
                'status must be approved or rejected'
            );
        }

        const comment = String(
            payload?.comment || ''
        ).trim();

        return request(
            `/business-claim-requests/${id}/review`,
            {
                method: 'PATCH',
                body: {
                    status,
                    ...(comment
                        ? { comment }
                        : {}),
                },
                ...opts,
            }
        ).then(normalizeClaim);
    },

    approve(
        id,
        comment = '',
        opts = {}
    ) {
        return this.review(
            id,
            {
                status: 'approved',
                comment,
            },
            opts
        );
    },

    reject(
        id,
        comment = '',
        opts = {}
    ) {
        return this.review(
            id,
            {
                status: 'rejected',
                comment,
            },
            opts
        );
    },

    // ===================================================
    // BUSINESS
    // ===================================================

    getByBusiness(
        businessId,
        params = {},
        opts = {}
    ) {
        if (!businessId) {
            throw new Error(
                'businessId is required'
            );
        }

        return request(
            `/business-claim-requests/business/${businessId}${qs(
                {
                    limit: params.limit,
                    offset: params.offset,
                }
            )}`,
            opts
        ).then(normalizeList);
    },

    // ===================================================
    // GENERAL
    // ===================================================

    getById(id, opts = {}) {
        if (!id) {
            throw new Error(
                'id is required'
            );
        }

        return request(
            `/business-claim-requests/${id}`,
            opts
        ).then(normalizeClaim);
    },
};

export default BusinessClaimRequestsService;