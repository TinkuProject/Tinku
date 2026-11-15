// src/services/chargingPointsService.js

const API_URL =
    process.env.NEXT_PUBLIC_API_URL ||
    'http://localhost:3000';

function authHeader() {
    if (typeof window === 'undefined')
        return {};

    const token =
        localStorage.getItem('token');

    return token
        ? {
            Authorization: `Bearer ${token}`,
        }
        : {};
}

async function ensureOk(res) {
    let data = {};

    try {
        data = await res.json();
    } catch (_) { }

    if (!res.ok) {
        const msg =
            data?.error ||
            data?.message ||
            `HTTP ${res.status}`;

        const err = new Error(msg);

        err.status = res.status;
        err.payload = data;

        throw err;
    }

    return data;
}

async function request(
    path,
    {
        method = 'GET',
        body,
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
                'Content-Type':
                    'application/json',
                ...authHeader(),
            },
            body: body
                ? JSON.stringify(body)
                : undefined,
        }
    );

    return ensureOk(res);
}

/* =========================
   LIST
========================= */

export async function listChargingPoints(
    signal
) {
    return request('/charging-points', {
        signal,
    });
}

/* =========================
   ACTIVE
========================= */

export async function listActiveChargingPoints(
    signal
) {
    return request(
        '/charging-points/active',
        {
            signal,
        }
    );
}

/* =========================
   GET
========================= */

export async function getChargingPoint(
    id,
    signal
) {
    return request(
        `/charging-points/${id}`,
        {
            signal,
        }
    );
}

/* =========================
   CREATE
========================= */

export async function createChargingPoint(
    payload
) {
    return request('/charging-points', {
        method: 'POST',
        body: payload,
    });
}

/* =========================
   UPDATE
========================= */

export async function updateChargingPoint(
    id,
    payload
) {
    return request(
        `/charging-points/${id}`,
        {
            method: 'PATCH',
            body: payload,
        }
    );
}

/* =========================
   SOFT DELETE
========================= */

export async function softDeleteChargingPoint(
    id
) {
    return request(
        `/charging-points/${id}/softDelete`,
        {
            method: 'PATCH',
        }
    );
}

/* =========================
   STATUS
========================= */

export async function activateChargingPoint(
    id
) {
    return updateChargingPoint(id, {
        status: 'active',
    });
}

export async function deactivateChargingPoint(
    id
) {
    return updateChargingPoint(id, {
        status: 'inactive',
    });
}

export async function maintenanceChargingPoint(
    id
) {
    return updateChargingPoint(id, {
        status: 'maintenance',
    });
}

/* =========================
   FACADE
========================= */

export const ChargingPointsService = {
    list: listChargingPoints,

    listActive:
        listActiveChargingPoints,

    getById: getChargingPoint,

    create: createChargingPoint,

    update: updateChargingPoint,

    softDelete:
        softDeleteChargingPoint,

    activate:
        activateChargingPoint,

    deactivate:
        deactivateChargingPoint,

    maintenance:
        maintenanceChargingPoint,
};

export default ChargingPointsService;