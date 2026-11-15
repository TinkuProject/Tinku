// File: src/services/notificationsService.js
// CRUD + helpers para /notifications

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';
const jsonHeaders = { 'Content-Type': 'application/json' };

async function request(path, { method = 'GET', body, headers, signal } = {}) {
    const res = await fetch(`${API_URL}${path}`, {
        method,
        headers: { ...(body ? jsonHeaders : {}), ...(headers || {}) },
        body: body ? JSON.stringify(body) : undefined,
        signal,
        cache: 'no-store',
    });

    const isJSON = (res.headers.get('content-type') || '').includes('application/json');
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

export const NotificationsService = {
    // 🔹 Listado genérico (por si quieres filtrar por algo luego)
    list(params = {}, opts = {}) {
        const qs = new URLSearchParams(
            Object.fromEntries(
                Object.entries(params).filter(
                    ([, v]) => v !== undefined && v !== null && v !== ''
                )
            )
        ).toString();
        const path = qs ? `/notifications?${qs}` : '/notifications';
        return request(path, { ...opts });
    },

    // 🔹 Obtener notificaciones de un usuario
    getByUser(userId, { limit = 50, ...opts } = {}) {
        if (!userId) throw new Error('userId es requerido');
        const qs = new URLSearchParams(
            Object.fromEntries(
                Object.entries({
                    user_id: userId,
                    limit,
                }).filter(([, v]) => v !== undefined && v !== null && v !== '')
            )
        ).toString();

        const path = `/notifications/by-user?${qs}`;
        return request(path, { ...opts });
    },

    // 🔹 Obtener una por id
    get(id, opts = {}) {
        if (!id) throw new Error('id es requerido');
        return request(`/notifications/${id}`, { ...opts });
    },

    // 🔹 Crear notificación
    create(payload, opts = {}) {
        return request('/notifications', {
            method: 'POST',
            body: payload,
            ...opts,
        });
    },

    // 🔹 Actualizar (message / read)
    update(id, payload, opts = {}) {
        if (!id) throw new Error('id es requerido');
        return request(`/notifications/${id}`, {
            method: 'PUT',
            body: payload,
            ...opts,
        });
    },

    // 🔹 Marcar como leída
    markAsRead(id, opts = {}) {
        if (!id) throw new Error('id es requerido');
        return request(`/notifications/${id}/read`, {
            method: 'PUT',
            ...opts,
        });
    },

    // 🔹 Broadcast a admins/master
    broadcast({ message, sender_id }, opts = {}) {
        if (!message) throw new Error('message es requerido');
        return request('/notifications/broadcast', {
            method: 'POST',
            body: { message, sender_id },
            ...opts,
        });
    },

    // 🔹 Eliminar
    remove(id, opts = {}) {
        if (!id) throw new Error('id es requerido');
        return request(`/notifications/${id}`, {
            method: 'DELETE',
            ...opts,
        });
    },
};
