// File: src/services/entityUpdatesService.js

const API_URL =
    process.env.NEXT_PUBLIC_API_URL ??
    'http://localhost:3000';

const BASE = `${API_URL}/entity-updates`;

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
        ? { Authorization: `Bearer ${token}` }
        : {};
}

async function request(path, { method = 'GET', body, signal } = {}) {
    const res = await fetch(`${BASE}${path}`, {
        method,
        signal,
        cache: 'no-store',
        headers: {
            ...(body ? { 'Content-Type': 'application/json' } : {}),
            ...authHeaders(),
        },
        body: body ? JSON.stringify(body) : undefined,
    });

    let data = null;

    try {
        data = await res.json();
    } catch (_) { }

    if (!res.ok) {
        const message =
            data?.message ||
            data?.error ||
            `HTTP ${res.status}`;

        const err = new Error(message);
        err.status = res.status;
        err.data = data;

        throw err;
    }

    return data;
}

function parseUpdateData(row) {
    if (!row) return row;

    if (typeof row.data === 'string') {
        try {
            return {
                ...row,
                data: JSON.parse(row.data),
            };
        } catch {
            return {
                ...row,
                data: {},
            };
        }
    }

    return row;
}

export const EntityUpdatesService = {
    async list(opts = {}) {
        const data = await request('/', opts);

        return Array.isArray(data)
            ? data.map(parseUpdateData)
            : [];
    },

    async get(id, opts = {}) {
        if (!id) throw new Error('id is required');

        const data = await request(`/${id}`, opts);

        return parseUpdateData(data);
    },

    async approve(id, comment = '', opts = {}) {
        if (!id) throw new Error('id is required');

        return request(`/${id}/approve`, {
            method: 'PATCH',
            body: {
                comment: comment || undefined,
            },
            ...opts,
        });
    },

    async reject(id, comment = '', opts = {}) {
        if (!id) throw new Error('id is required');

        return request(`/${id}/reject`, {
            method: 'PATCH',
            body: {
                comment: comment || undefined,
            },
            ...opts,
        });
    },
};

export default EntityUpdatesService;