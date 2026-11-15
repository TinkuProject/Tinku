// File: src/services/categoryService.js

const API_URL =
    process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

function getToken() {
    if (typeof window === 'undefined') return null;

    return (
        localStorage.getItem('token') ||
        localStorage.getItem('accessToken') ||
        localStorage.getItem('access_token')
    );
}

function authHeader() {
    const token = getToken();

    return token
        ? {
            Authorization: `Bearer ${token}`,
        }
        : {};
}

function qs(params = {}) {
    const filteredParams = Object.fromEntries(
        Object.entries(params).filter(
            ([, value]) =>
                value !== undefined &&
                value !== null &&
                value !== ''
        )
    );

    const query = new URLSearchParams(filteredParams).toString();

    return query ? `?${query}` : '';
}

async function parseResponse(res) {
    if (res.status === 204) {
        return null;
    }

    const contentType = res.headers.get('content-type') || '';

    if (contentType.includes('application/json')) {
        try {
            return await res.json();
        } catch {
            return null;
        }
    }

    try {
        const text = await res.text();

        return text || null;
    } catch {
        return null;
    }
}

function createCategoryError(res, data) {
    const backendMessage =
        typeof data === 'string'
            ? data
            : data?.error ||
            data?.message ||
            data?.details ||
            null;

    const error = new Error(
        backendMessage || `Error HTTP ${res.status}`
    );

    error.name = 'CategoryServiceError';
    error.status = res.status;
    error.data = data;
    error.code =
        data?.code ||
        data?.errorCode ||
        null;

    return error;
}

async function request(
    path,
    {
        method = 'GET',
        body,
        headers,
        signal,
    } = {}
) {
    let res;

    try {
        res = await fetch(`${API_URL}${path}`, {
            method,
            signal,
            cache: 'no-store',
            headers: {
                Accept: 'application/json',
                ...(body !== undefined
                    ? { 'Content-Type': 'application/json' }
                    : {}),
                ...authHeader(),
                ...(headers || {}),
            },
            body:
                body !== undefined
                    ? JSON.stringify(body)
                    : undefined,
        });
    } catch (error) {
        if (error?.name === 'AbortError') {
            throw error;
        }

        const networkError = new Error(
            'No se pudo conectar con el servidor.'
        );

        networkError.name = 'CategoryServiceError';
        networkError.status = 0;
        networkError.code = 'NETWORK_ERROR';
        networkError.originalError = error;

        throw networkError;
    }

    const data = await parseResponse(res);

    if (!res.ok) {
        throw createCategoryError(res, data);
    }

    return data;
}

export const CategoryService = {
    list(opts = {}) {
        return request('/categories', {
            method: 'GET',
            ...opts,
        });
    },

    listAdmin(opts = {}) {
        return request('/categories/admin', {
            method: 'GET',
            ...opts,
        });
    },

    get(id, opts = {}) {
        if (!id) {
            throw new Error('id is required');
        }

        return request(`/categories/${id}`, {
            method: 'GET',
            ...opts,
        });
    },

    getActiveById(id, opts = {}) {
        if (!id) {
            throw new Error('id is required');
        }

        return request(`/categories/active/${id}`, {
            method: 'GET',
            ...opts,
        });
    },

    getActiveByType(params = {}, opts = {}) {
        return request(
            `/categories/active${qs(params)}`,
            {
                method: 'GET',
                ...opts,
            }
        );
    },

    getByFilters(params = {}, opts = {}) {
        return request(
            `/categories/filters${qs(params)}`,
            {
                method: 'GET',
                ...opts,
            }
        );
    },

    getByIds(ids = [], opts = {}) {
        const cleanIds = ids
            .map(Number)
            .filter((number) => Number.isFinite(number));

        if (!cleanIds.length) {
            return Promise.resolve([]);
        }

        return request(
            `/categories/batch${qs({
                ids: cleanIds.join(','),
            })}`,
            {
                method: 'GET',
                ...opts,
            }
        );
    },

    create(payload, opts = {}) {
        return request('/categories', {
            method: 'POST',
            body: payload,
            ...opts,
        });
    },

    update(id, payload, opts = {}) {
        if (!id) {
            throw new Error('id is required');
        }

        return request(`/categories/${id}`, {
            method: 'PATCH',
            body: payload,
            ...opts,
        });
    },

    activate(id, opts = {}) {
        if (!id) {
            throw new Error('id is required');
        }

        return request(`/categories/${id}/activate`, {
            method: 'PATCH',
            ...opts,
        });
    },

    deactivate(id, opts = {}) {
        if (!id) {
            throw new Error('id is required');
        }

        return request(`/categories/${id}/deactivate`, {
            method: 'PATCH',
            ...opts,
        });
    },

    softDelete(id, opts = {}) {
        if (!id) {
            throw new Error('id is required');
        }

        return request(`/categories/${id}/softDelete`, {
            method: 'PATCH',
            ...opts,
        });
    },
};

export function buildCategoryPayload({
    name,
    entity_type,
    business_type,
}) {
    const payload = {
        name: String(name || '').trim(),
        entity_type,
    };

    if (entity_type === 'business') {
        payload.business_type = business_type || null;
    }

    return payload;
}

export default CategoryService;