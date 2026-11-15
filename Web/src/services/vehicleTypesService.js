// src/services/vehicleTypesService.js

const API_URL =
    process.env.NEXT_PUBLIC_API_URL ??
    'http://localhost:3000';

function getToken() {
    if (typeof window === 'undefined') {
        return null;
    }

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

async function request(
    path,
    {
        method = 'GET',
        body,
        headers,
        signal,
    } = {}
) {
    const res = await fetch(
        `${API_URL}${path}`,
        {
            method,
            signal,
            cache: 'no-store',

            headers: {
                ...(body
                    ? {
                        'Content-Type':
                            'application/json',
                    }
                    : {}),

                ...authHeaders(),
                ...(headers || {}),
            },

            body: body
                ? JSON.stringify(body)
                : undefined,
        }
    );

    const isJSON = (
        res.headers.get(
            'content-type'
        ) || ''
    ).includes('application/json');

    const data = isJSON
        ? await res.json()
        : await res.text();

    if (!res.ok) {
        const message =
            (isJSON &&
                data &&
                (data.message ||
                    data.error)) ||
            `HTTP ${res.status}`;

        const error = new Error(
            message
        );

        error.status = res.status;
        error.data = data;

        throw error;
    }

    return data;
}

export const VehicleTypesService =
{
    list(opts = {}) {
        return request(
            '/vehicle-types',
            opts
        );
    },

    get(id, opts = {}) {
        if (!id) {
            throw new Error(
                'id is required'
            );
        }

        return request(
            `/vehicle-types/${id}`,
            opts
        );
    },

    create(payload, opts = {}) {
        return request(
            '/vehicle-types',
            {
                method: 'POST',
                body: payload,
                ...opts,
            }
        );
    },

    update(
        id,
        payload,
        opts = {}
    ) {
        if (!id) {
            throw new Error(
                'id is required'
            );
        }

        return request(
            `/vehicle-types/${id}`,
            {
                method: 'PUT',
                body: payload,
                ...opts,
            }
        );
    },

    remove(id, opts = {}) {
        if (!id) {
            throw new Error(
                'id is required'
            );
        }

        return request(
            `/vehicle-types/${id}`,
            {
                method: 'DELETE',
                ...opts,
            }
        );
    },
};

export default VehicleTypesService;