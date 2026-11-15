// src/services/tagService.js

const API_URL =
    process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

const jsonHeaders = {
    'Content-Type': 'application/json',
};

function getToken() {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem('token');
}

function authHeaders() {
    const token = getToken();

    if (!token) return {};

    return {
        Authorization: `Bearer ${token}`,
    };
}

async function request(
    path,
    { method = 'GET', body, headers, signal } = {}
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
        body: body ? JSON.stringify(body) : undefined,
    });

    const isJSON = (res.headers.get('content-type') || '').includes(
        'application/json'
    );

    const data = isJSON ? await res.json() : await res.text();

    if (!res.ok) {
        const msg =
            (isJSON && (data?.message || data?.error)) ||
            res.statusText ||
            'Request failed';

        const err = new Error(msg);

        err.status = res.status;
        err.data = data;

        throw err;
    }

    return data;
}

export const TagService = {
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
            ? `/tags?${qs}`
            : '/tags';

        return request(path, opts);
    },

    get(id, opts = {}) {
        if (!id) {
            throw new Error('id is required');
        }

        return request(`/tags/${id}`, opts);
    },

    create(payload, opts = {}) {
        return request('/tags', {
            method: 'POST',
            body: payload,
            ...opts,
        });
    },

    update(id, payload, opts = {}) {
        if (!id) {
            throw new Error('id is required');
        }

        return request(`/tags/${id}`, {
            method: 'PUT',
            body: payload,
            ...opts,
        });
    },

    softDelete(id, opts = {}) {
        if (!id) {
            throw new Error('id is required');
        }

        return request(`/tags/${id}/soft-delete`, {
            method: 'PUT',
            ...opts,
        });
    },
};

export default TagService;