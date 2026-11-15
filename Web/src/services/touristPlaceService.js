// src/services/touristPlaceService.js

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

const jsonHeaders = {
    'Content-Type': 'application/json',
};

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

async function request(path, { method = 'GET', body, headers, signal } = {}) {
    const res = await fetch(`${API_URL}${path}`, {
        method,
        signal,
        cache: 'no-store',
        headers: {
            ...(body ? jsonHeaders : {}),
            ...authHeaders(),
            ...(headers || {}),
        },
        body: body ? JSON.stringify(body) : undefined,
    });

    const isJSON = (res.headers.get('content-type') || '').includes(
        'application/json'
    );

    const data = isJSON ? await res.json() : await res.text();

    if (!res.ok) {
        const message =
            (isJSON && data && (data.message || data.error)) ||
            res.statusText;

        const err = new Error(message || 'Request failed');

        err.status = res.status;
        err.data = data;

        throw err;
    }

    return data;
}

export const TouristPlaceService = {
    list(params = {}, opts = {}) {
        const qs = new URLSearchParams(
            Object.fromEntries(
                Object.entries(params).filter(
                    ([, v]) =>
                        v !== undefined &&
                        v !== null &&
                        v !== ''
                )
            )
        ).toString();

        const path = qs
            ? `/tourist-places?${qs}`
            : '/tourist-places';

        return request(path, opts);
    },

    get(id, opts = {}) {
        if (!id) {
            throw new Error('id is required');
        }

        return request(`/tourist-places/${id}`, opts);
    },

    getByCategory(categoryId, opts = {}) {
        if (!categoryId) {
            throw new Error('categoryId is required');
        }

        return request(`/tourist-places/category/${categoryId}`, opts);
    },

    create(payload, opts = {}) {
        return request('/tourist-places', {
            method: 'POST',
            body: payload,
            ...opts,
        });
    },

    update(id, payload, opts = {}) {
        if (!id) {
            throw new Error('id is required');
        }

        return request(`/tourist-places/${id}`, {
            method: 'PUT',
            body: payload,
            ...opts,
        });
    },

    archive(id, opts = {}) {
        if (!id) {
            throw new Error('id is required');
        }

        return request(`/tourist-places/${id}/archive`, {
            method: 'PATCH',
            ...opts,
        });
    },
};

export function buildTouristPlacePayload({
    category_id,
    name,
    description,
    address,
    lat,
    lng,
    latitude,
    longitude,
    status,
}) {
    const finalLatitude = Number(latitude ?? lat);
    const finalLongitude = Number(longitude ?? lng);

    const payload = {
        name: String(name || '').trim(),
        location: {
            latitude: finalLatitude,
            longitude: finalLongitude,
        },
    };

    const optionalText = (value) => {
        const v = String(value || '').trim();
        return v === '' ? undefined : v;
    };

    const optionalFields = {
        category_id: category_id ? Number(category_id) : undefined,
        description: optionalText(description),
        address: optionalText(address),
        status: optionalText(status),
    };

    Object.entries(optionalFields).forEach(([key, value]) => {
        if (value !== undefined) {
            payload[key] = value;
        }
    });

    return payload;
}

export default TouristPlaceService;