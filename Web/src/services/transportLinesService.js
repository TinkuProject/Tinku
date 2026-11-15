// src/services/transportLinesService.js

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

function getToken() {
    if (typeof window === 'undefined') return null;

    return (
        localStorage.getItem('token') ||
        localStorage.getItem('accessToken') ||
        localStorage.getItem('access_token')
    );
}

function authHeaders() {
    const token = getToken();

    return token
        ? {
            Authorization: `Bearer ${token}`,
        }
        : {};
}

function qs(params = {}) {
    const query = new URLSearchParams(
        Object.fromEntries(
            Object.entries(params).filter(
                ([, v]) => v !== undefined && v !== null && v !== ''
            )
        )
    ).toString();

    return query ? `?${query}` : '';
}

async function request(path, { method = 'GET', body, headers, signal } = {}) {
    const res = await fetch(`${API_URL}${path}`, {
        method,
        signal,
        cache: 'no-store',
        headers: {
            ...(body ? { 'Content-Type': 'application/json' } : {}),
            ...authHeaders(),
            ...(headers || {}),
        },
        body: body ? JSON.stringify(body) : undefined,
    });

    let data = null;

    try {
        data = await res.json();
    } catch (_) { }

    if (!res.ok) {
        throw new Error(data?.error || data?.message || `HTTP ${res.status}`);
    }

    return data;
}

export const TransportLinesService = {
    list(params = {}, opts = {}) {
        return request(`/transport-lines${qs(params)}`, opts);
    },

    get(id, opts = {}) {
        if (!id) throw new Error('id is required');
        return request(`/transport-lines/${id}`, opts);
    },

    getByIds(ids = [], opts = {}) {
        const cleanIds = ids.map(Number).filter((n) => Number.isFinite(n));

        if (!cleanIds.length) return Promise.resolve([]);

        return request(
            `/transport-lines/batch${qs({ ids: cleanIds.join(',') })}`,
            opts
        );
    },

    getByVehicleType(vehicleTypeId, opts = {}) {
        if (!vehicleTypeId) throw new Error('vehicleTypeId is required');

        return request(`/transport-lines/vehicle/${vehicleTypeId}`, opts);
    },

    create(payload, opts = {}) {
        return request('/transport-lines', {
            method: 'POST',
            body: payload,
            ...opts,
        });
    },

    update(id, payload, opts = {}) {
        if (!id) throw new Error('id is required');

        return request(`/transport-lines/${id}`, {
            method: 'PUT',
            body: payload,
            ...opts,
        });
    },

    archive(id, opts = {}) {
        if (!id) throw new Error('id is required');

        return request(`/transport-lines/${id}/archive`, {
            method: 'PATCH',
            ...opts,
        });
    },

    setStatus(id, status, opts = {}) {
        if (!id) throw new Error('id is required');

        return this.update(id, { status }, opts);
    },
};

export function buildTransportLinePayload({
    vehicle_type_id,
    name,
    status = 'active',
}) {
    return {
        vehicle_type_id: Number(vehicle_type_id),
        name: String(name || '').trim(),
        status,
    };
}

export default TransportLinesService;