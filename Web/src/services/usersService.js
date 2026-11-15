// src/services/usersService.js

const API_URL =
    process.env.NEXT_PUBLIC_API_URL ??
    'http://localhost:3000';

const authHeader = () => {
    const token =
        typeof window !== 'undefined'
            ? localStorage.getItem('token')
            : null;

    return token
        ? { Authorization: `Bearer ${token}` }
        : {};
};

async function getErrorMessage(res, fallback) {
    try {
        const data = await res.json();

        return (
            data?.message ||
            data?.error ||
            (Array.isArray(data?.details)
                ? data.details
                    .map(
                        (e) =>
                            `${e.path?.join('.') || 'campo'}: ${e.message}`
                    )
                    .join(', ')
                : null) ||
            fallback
        );
    } catch {
        return fallback;
    }
}

/**
 * =========================
 * LIST USERS
 * =========================
 */
export async function listUsers() {
    const res = await fetch(`${API_URL}/users`, {
        method: 'GET',
        headers: {
            ...authHeader(),
        },
    });

    if (!res.ok) {
        throw new Error(
            await getErrorMessage(
                res,
                'No se pudo obtener la lista de usuarios'
            )
        );
    }

    return res.json();
}

/**
 * =========================
 * GET USER
 * =========================
 */
export async function getUser(id) {
    if (!id) {
        throw new Error('id requerido');
    }

    const res = await fetch(
        `${API_URL}/users/${id}`,
        {
            method: 'GET',
            headers: {
                ...authHeader(),
            },
        }
    );

    if (!res.ok) {
        throw new Error(
            await getErrorMessage(
                res,
                'No se pudo obtener el usuario'
            )
        );
    }

    return res.json();
}

/**
 * =========================
 * UPDATE USER
 * =========================
 */
// PUT /users/:id
export async function updateUser(id, payload) {
    if (!id) throw new Error('id requerido');

    const res = await fetch(`${API_URL}/users/${id}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            ...authHeader(),
        },
        body: JSON.stringify(payload),
    });

    if (!res.ok) {
        const message = await getErrorMessage(
            res,
            'No se pudo actualizar el usuario'
        );

        // Workaround para el error del backend con .single()
        if (
            message.includes('Cannot coerce') ||
            message.includes('single JSON object')
        ) {
            return getUser(id);
        }

        throw new Error(message);
    }

    return res.json();
}

/**
 * =========================
 * DELETE USER
 * =========================
 */
export async function deleteUser(id) {
    if (!id) {
        throw new Error('id requerido');
    }

    const res = await fetch(
        `${API_URL}/users/${id}`,
        {
            method: 'DELETE',
            headers: {
                ...authHeader(),
            },
        }
    );

    if (!res.ok) {
        throw new Error(
            await getErrorMessage(
                res,
                'No se pudo eliminar el usuario'
            )
        );
    }

    return true;
}

/**
 * =========================
 * ACTIVATE PARTNER
 * =========================
 */
export async function activatePartner(id) {
    if (!id) {
        throw new Error('id requerido');
    }

    const res = await fetch(
        `${API_URL}/users/${id}/role/partner`,
        {
            method: 'PATCH',
            headers: {
                ...authHeader(),
            },
        }
    );

    if (!res.ok) {
        throw new Error(
            await getErrorMessage(
                res,
                'No se pudo activar partner'
            )
        );
    }

    return res.json();
}

/**
 * =========================
 * PROFILE PICTURE
 * =========================
 */
export async function getProfilePicture() {
    const res = await fetch(
        `${API_URL}/users/me/profile-picture`,
        {
            method: 'GET',
            headers: {
                ...authHeader(),
            },
        }
    );

    if (!res.ok) {
        throw new Error(
            await getErrorMessage(
                res,
                'No se pudo obtener la foto'
            )
        );
    }

    return res.json();
}

/**
 * =========================
 * UPDATE PROFILE PICTURE
 * =========================
 */
export async function updateProfilePicture(file) {
    if (!file) {
        throw new Error('Archivo requerido');
    }

    const formData = new FormData();
    formData.append('file', file);

    const res = await fetch(
        `${API_URL}/users/me/profile-picture`,
        {
            method: 'POST',
            headers: {
                ...authHeader(),
            },
            body: formData,
        }
    );

    if (!res.ok) {
        throw new Error(
            await getErrorMessage(
                res,
                'No se pudo actualizar la foto'
            )
        );
    }

    return res.json();
}