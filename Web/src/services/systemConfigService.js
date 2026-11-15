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

function authHeaders() {
    const token = getToken();

    return token
        ? { Authorization: `Bearer ${token}` }
        : {};
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
        throw new Error(
            data?.error || data?.message || `HTTP ${res.status}`
        );
    }

    return data;
}

export const SystemConfigService = {
    list(opts = {}) {
        return request('/system-config', opts);
    },

    get(key, opts = {}) {
        if (!key) throw new Error('key is required');

        return request(
            `/system-config/${encodeURIComponent(key)}`,
            opts
        );
    },

    getPublicNumber(key, opts = {}) {
        if (!key) throw new Error('key is required');

        return request(
            `/system-config/public/${encodeURIComponent(key)}`,
            opts
        );
    },

    update(key, payload, opts = {}) {
        if (!key) throw new Error('key is required');

        return request(
            `/system-config/${encodeURIComponent(key)}`,
            {
                method: 'PUT',
                body: payload,
                ...opts,
            }
        );
    },
};

export function buildSystemConfigPayload({
    value,
    description,
} = {}) {
    const payload = {};

    if (value !== undefined) {
        payload.value = String(value);
    }

    if (description !== undefined) {
        payload.description =
            description === null ? null : String(description);
    }

    return payload;
}

export default SystemConfigService;