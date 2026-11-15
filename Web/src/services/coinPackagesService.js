// File: src/services/coinPackagesService.js

const API_URL =
    process.env.NEXT_PUBLIC_API_URL ??
    'http://localhost:3000';

const BASE = `${API_URL}/coin-packages`;

const authHeader = () => {
    const token =
        typeof window !== 'undefined'
            ? localStorage.getItem('token')
            : null;

    return token
        ? { Authorization: `Bearer ${token}` }
        : {};
};

async function request(url, options = {}) {
    const res = await fetch(url, {
        ...options,
        headers: {
            ...(options.body
                ? { 'Content-Type': 'application/json' }
                : {}),
            ...authHeader(),
            ...(options.headers || {}),
        },
        cache: 'no-store',
    });

    const contentType =
        res.headers.get('content-type') || '';

    const isJSON = contentType.includes('application/json');

    const data = isJSON
        ? await res.json()
        : await res.text();

    if (!res.ok) {
        const message =
            (isJSON && (data?.message || data?.error)) ||
            'Error en la petición';

        throw new Error(message);
    }

    return data;
}

// =====================================================
// PUBLIC
// =====================================================

export async function getCoinPackages() {
    return request(BASE);
}

export async function getCoinPackageById(id) {
    return request(`${BASE}/${id}`);
}

export async function getActiveCoinPackageById(id) {
    return request(`${BASE}/${id}/active`);
}

export async function getPartnerUpgradePackage() {
    return request(`${BASE}/basic`);
}

// =====================================================
// ADMIN
// =====================================================

export async function getCoinPackagesAdmin() {
    return request(`${BASE}/admin`);
}

export async function getCoinPackagesByFilters(params = {}) {
    const query = new URLSearchParams(
        Object.fromEntries(
            Object.entries(params).filter(
                ([, value]) =>
                    value !== undefined &&
                    value !== null &&
                    value !== ''
            )
        )
    ).toString();

    return request(`${BASE}/filters${query ? `?${query}` : ''}`);
}

export async function createCoinPackage(payload) {
    return request(BASE, {
        method: 'POST',
        body: JSON.stringify({
            name: payload.name,
            tinkus_amount: Number(payload.tinkus_amount),
            cash_amount: Number(payload.cash_amount),
        }),
    });
}

export async function updateCoinPackage(id, payload) {
    return request(`${BASE}/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({
            ...(payload.name !== undefined
                ? { name: payload.name }
                : {}),

            ...(payload.tinkus_amount !== undefined
                ? { tinkus_amount: Number(payload.tinkus_amount) }
                : {}),

            ...(payload.cash_amount !== undefined
                ? { cash_amount: Number(payload.cash_amount) }
                : {}),

            ...(payload.status !== undefined
                ? { status: payload.status }
                : {}),
        }),
    });
}

export async function archiveCoinPackage(id) {
    return request(`${BASE}/${id}/softDelete`, {
        method: 'PATCH',
    });
}

export async function activateCoinPackage(id) {
    return request(`${BASE}/${id}/activate`, {
        method: 'PATCH',
    });
}

export async function deactivateCoinPackage(id) {
    return request(`${BASE}/${id}/deactivate`, {
        method: 'PATCH',
    });
}