// src/services/eventService.js

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

export const EventService = {
    // =====================================================
    // BASIC CRUD
    // =====================================================

    list(params = {}, opts = {}) {
        return request(`/events${qs(params)}`, opts);
    },

    get(id, opts = {}) {
        if (!id) throw new Error('id is required');

        return request(`/events/${id}`, opts);
    },

    create(payload, opts = {}) {
        return request('/events', {
            method: 'POST',
            body: payload,
            ...opts,
        });
    },

    update(id, payload, opts = {}) {
        if (!id) throw new Error('id is required');

        return request(`/events/${id}`, {
            method: 'PUT',
            body: payload,
            ...opts,
        });
    },

    remove(id, opts = {}) {
        if (!id) throw new Error('id is required');

        return request(`/events/${id}`, {
            method: 'DELETE',
            ...opts,
        });
    },

    // =====================================================
    // FILTERS
    // =====================================================

    getByCategory(categoryId, opts = {}) {
        if (!categoryId) {
            throw new Error('categoryId is required');
        }

        return request(`/events/category/${categoryId}`, opts);
    },

    getByBusiness(businessId, opts = {}) {
        if (!businessId) {
            throw new Error('businessId is required');
        }

        return request(`/events/business/${businessId}`, opts);
    },

    getMine(opts = {}) {
        return request('/events/me', opts);
    },

    // =====================================================
    // ADMIN STATUS ROUTES
    // =====================================================

    getByStatus(status, opts = {}) {
        if (!status) {
            throw new Error('status is required');
        }

        return request(`/events/admin${qs({ status })}`, opts);
    },

    async getAdminByStatuses(statuses = [], opts = {}) {
        const clean = statuses.filter(Boolean);

        if (clean.length === 0) return [];

        const responses = await Promise.all(
            clean.map((status) => this.getByStatus(status, opts))
        );

        return responses.flatMap((resp) => {
            if (Array.isArray(resp)) return resp;
            if (Array.isArray(resp?.data)) return resp.data;
            if (Array.isArray(resp?.items)) return resp.items;
            return [];
        });
    },

    getPending(opts = {}) {
        return this.getByStatus('pending', opts);
    },

    getFinished(opts = {}) {
        return this.getByStatus('finished', opts);
    },

    getCancelled(opts = {}) {
        return this.getByStatus('cancelled', opts);
    },

    // =====================================================
    // ADMIN ACTIONS
    // =====================================================

    approve(id, opts = {}) {
        if (!id) throw new Error('id is required');

        return request(`/events/${id}/approve`, {
            method: 'PATCH',
            body: {
                message: opts.message ?? '',
            },
            ...opts,
        });
    },

    reject(id, opts = {}) {
        if (!id) throw new Error('id is required');

        return request(`/events/${id}/reject`, {
            method: 'PATCH',
            body: {
                message: opts.message ?? '',
            },
            ...opts,
        });
    },
};

// =====================================================
// PAYLOAD BUILDER
// =====================================================

export function buildEventPayload({
    business_id,
    category_id,
    name,
    description,
    start_date,
    end_date,
    capacity,
    tinku_price,
    address,
    lat,
    lng,
    latitude,
    longitude,
}) {
    const finalLatitude = Number(latitude ?? lat);
    const finalLongitude = Number(longitude ?? lng);

    const cleanText = (value) => {
        const v = String(value || '').trim();
        return v === '' ? null : v;
    };

    return {
        business_id: business_id ? Number(business_id) : null,

        category_id: Number(category_id),

        name: String(name || '').trim(),

        description: cleanText(description),

        start_date: new Date(start_date).toISOString(),

        end_date: new Date(end_date).toISOString(),

        capacity:
            capacity === undefined ||
                capacity === null ||
                capacity === ''
                ? null
                : Number(capacity),

        tinku_price:
            tinku_price === undefined ||
                tinku_price === null ||
                tinku_price === ''
                ? 0
                : Number(tinku_price),

        address: String(address || '').trim(),

        location: {
            latitude: finalLatitude,
            longitude: finalLongitude,
        },
    };
}

export default EventService;