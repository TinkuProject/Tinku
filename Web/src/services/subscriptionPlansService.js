// File: src/services/subscriptionPlansService.js

const API_URL =
    process.env.NEXT_PUBLIC_API_URL ??
    'http://localhost:3000';

const BASE =
    `${API_URL}/subscription-plans`;

const authHeader = () => {
    const token =
        typeof window !== 'undefined'
            ? localStorage.getItem('token')
            : null;

    return token
        ? {
            Authorization: `Bearer ${token}`,
        }
        : {};
};

async function request(
    url,
    options = {}
) {
    const res = await fetch(url, {
        ...options,
        headers: {
            ...(options.body
                ? {
                    'Content-Type':
                        'application/json',
                }
                : {}),
            ...authHeader(),
            ...(options.headers || {}),
        },
        cache: 'no-store',
    });

    const contentType =
        res.headers.get('content-type') ||
        '';

    const isJSON =
        contentType.includes(
            'application/json'
        );

    const data = isJSON
        ? await res.json()
        : await res.text();

    if (!res.ok) {
        const message =
            (isJSON &&
                (data?.message ||
                    data?.error)) ||
            'Error en la petición';

        throw new Error(message);
    }

    return data;
}

// =====================================================
// GET ALL
// =====================================================

export async function getSubscriptionPlans() {
    return request(BASE);
}

// =====================================================
// GET BY ID
// =====================================================

export async function getSubscriptionPlanById(
    id
) {
    return request(`${BASE}/${id}`);
}

// =====================================================
// CREATE
// =====================================================

export async function createSubscriptionPlan(
    payload
) {
    return request(BASE, {
        method: 'POST',
        body: JSON.stringify({
            name: payload.name,
            price: Number(payload.price),
            currency:
                payload.currency || 'BOB',
            duration_months:
                payload.duration_months
                    ? Number(
                        payload.duration_months
                    )
                    : undefined,
            included_tinku: Number(
                payload.included_tinku || 0
            ),
            status:
                payload.status || 'active',
        }),
    });
}

// =====================================================
// UPDATE
// =====================================================

export async function updateSubscriptionPlan(
    id,
    payload
) {
    return request(`${BASE}/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({
            ...(payload.name !==
                undefined
                ? { name: payload.name }
                : {}),

            ...(payload.price !==
                undefined
                ? {
                    price: Number(
                        payload.price
                    ),
                }
                : {}),

            ...(payload.currency !==
                undefined
                ? {
                    currency:
                        payload.currency,
                }
                : {}),

            ...(payload.duration_months !==
                undefined
                ? {
                    duration_months:
                        Number(
                            payload.duration_months
                        ),
                }
                : {}),

            ...(payload.included_tinku !==
                undefined
                ? {
                    included_tinku:
                        Number(
                            payload.included_tinku
                        ),
                }
                : {}),

            ...(payload.status !==
                undefined
                ? {
                    status:
                        payload.status,
                }
                : {}),
        }),
    });
}

// =====================================================
// ARCHIVE / SOFT DELETE
// =====================================================

export async function archiveSubscriptionPlan(
    id
) {
    return request(
        `${BASE}/${id}/archive`,
        {
            method: 'PATCH',
        }
    );
}

// =====================================================
// ACTIVATE
// =====================================================

export async function activateSubscriptionPlan(
    id
) {
    return updateSubscriptionPlan(
        id,
        {
            status: 'active',
        }
    );
}

// =====================================================
// DEACTIVATE
// =====================================================

export async function deactivateSubscriptionPlan(
    id
) {
    return updateSubscriptionPlan(
        id,
        {
            status: 'inactive',
        }
    );
}