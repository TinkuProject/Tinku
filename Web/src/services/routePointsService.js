// File: src/services/routePointsService.js
// Service para /transport-routes

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

    return token ? { Authorization: `Bearer ${token}` } : {};
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
        const err = new Error(data?.error || data?.message || `HTTP ${res.status}`);
        err.status = res.status;
        err.data = data;
        throw err;
    }

    return data;
}

function normalizeDirection(direction) {
    const value = String(direction || '').toLowerCase();

    if (value === 'outbound' || value === 'ida' || value === 'out') {
        return 'outbound';
    }

    if (value === 'return' || value === 'vuelta' || value === 'back') {
        return 'return';
    }

    return value;
}

function normalizeLocation(input = {}) {
    if (input.location && typeof input.location === 'object') {
        if (Array.isArray(input.location.coordinates)) {
            const [lng, lat] = input.location.coordinates.map(Number);

            return {
                latitude: lat,
                longitude: lng,
            };
        }

        return {
            latitude: Number(input.location.latitude ?? input.location.lat),
            longitude: Number(input.location.longitude ?? input.location.lng),
        };
    }

    return {
        latitude: Number(input.latitude ?? input.lat),
        longitude: Number(input.longitude ?? input.lng),
    };
}

export function buildTransportRoutePayload(payload = {}) {
    const location = normalizeLocation(payload);

    return {
        transport_line_id: Number(payload.transport_line_id),
        direction: normalizeDirection(payload.direction),
        stop_order: Number(payload.stop_order ?? payload.route_order ?? 0),
        location,
    };
}

export const RoutePointsService = {
    getByLine(lineId, opts = {}) {
        if (!lineId) throw new Error('lineId is required');

        return request(`/transport-routes/line/${lineId}`, opts);
    },

    getByLineAndDirection(lineId, direction, opts = {}) {
        if (!lineId) throw new Error('lineId is required');
        if (!direction) throw new Error('direction is required');

        return request(
            `/transport-routes/line/${lineId}/${normalizeDirection(direction)}`,
            opts
        );
    },

    create(payload, opts = {}) {
        return request('/transport-routes', {
            method: 'POST',
            body: buildTransportRoutePayload(payload),
            ...opts,
        });
    },

    createBulk(items = [], opts = {}) {
        const body = items.map(buildTransportRoutePayload);

        return request('/transport-routes/bulk', {
            method: 'POST',
            body,
            ...opts,
        });
    },

    remove(id, opts = {}) {
        if (!id) throw new Error('id is required');

        return request(`/transport-routes/${id}`, {
            method: 'DELETE',
            ...opts,
        });
    },
};

export default RoutePointsService;