// File: src/services/authService.js

const API_URL =
    process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

/**
 * =========================
 * FORMAT API ERROR
 * =========================
 */
function getErrorMessage(errorBody, fallbackMessage) {
    const zodDetails = Array.isArray(errorBody?.details)
        ? errorBody.details
            .map((error) => {
                const field =
                    error?.path?.join('.') || 'campo';

                return `${field}: ${error?.message || 'Error de validación'}`;
            })
            .join(', ')
        : null;

    return (
        zodDetails ||
        errorBody?.message ||
        errorBody?.error ||
        (Array.isArray(errorBody?.errors)
            ? errorBody.errors.join(', ')
            : null) ||
        fallbackMessage
    );
}

/**
 * =========================
 * PARSE RESPONSE
 * =========================
 */
async function parseResponse(response) {
    if (response.status === 204) {
        return null;
    }

    const contentType =
        response.headers.get('content-type') || '';

    if (contentType.includes('application/json')) {
        return response.json().catch(() => null);
    }

    return response
        .text()
        .then((text) => text || null)
        .catch(() => null);
}

/**
 * =========================
 * REGISTER
 * =========================
 */
export async function registerUser(payload) {
    try {
        const response = await fetch(
            `${API_URL}/auth/register`,
            {
                method: 'POST',
                headers: {
                    Accept: 'application/json',
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(payload),
            }
        );

        const data = await parseResponse(response);

        if (!response.ok) {
            return {
                success: false,
                message: getErrorMessage(
                    data,
                    `Error en el registro (HTTP ${response.status})`
                ),
                status: response.status,
                details: data,
            };
        }

        return {
            success: true,
            data,
        };
    } catch (error) {
        console.warn('[authService] registerUser:', {
            message: error?.message,
        });

        return {
            success: false,
            message: 'Error de conexión al servidor',
            status: 0,
        };
    }
}

/**
 * =========================
 * LOGIN
 * =========================
 */
export async function loginUser(payload) {
    try {
        const response = await fetch(
            `${API_URL}/auth/login`,
            {
                method: 'POST',
                headers: {
                    Accept: 'application/json',
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(payload),
            }
        );

        const data = await parseResponse(response);

        if (!response.ok) {
            return {
                success: false,
                message: getErrorMessage(
                    data,
                    'Correo, usuario o contraseña incorrectos.'
                ),
                status: response.status,
                details: data,
            };
        }

        const accessToken =
            data?.session?.access_token;

        const refreshToken =
            data?.session?.refresh_token;

        if (!accessToken) {
            return {
                success: false,
                message:
                    'El servidor no devolvió un token de acceso.',
                status: 500,
                details: data,
            };
        }

        return {
            success: true,
            token: accessToken,
            refreshToken: refreshToken || null,
            user: data?.user || null,
            profile: data?.profile || null,
        };
    } catch (error) {
        console.warn('[authService] loginUser:', {
            message: error?.message,
        });

        return {
            success: false,
            message: 'Error de conexión al servidor',
            status: 0,
        };
    }
}

/**
 * =========================
 * GET CURRENT USER
 * =========================
 */
export async function getCurrentUser(token) {
    if (!token) {
        return {
            success: false,
            message: 'No se encontró un token de acceso.',
            status: 401,
            code: 'ACCESS_TOKEN_MISSING',
        };
    }

    try {
        const response = await fetch(
            `${API_URL}/auth/me`,
            {
                method: 'GET',
                cache: 'no-store',
                headers: {
                    Accept: 'application/json',
                    Authorization: `Bearer ${token}`,
                },
            }
        );

        const data = await parseResponse(response);

        if (!response.ok) {
            return {
                success: false,
                message: getErrorMessage(
                    data,
                    'No se pudo obtener el usuario.'
                ),
                status: response.status,
                details: data,
            };
        }

        return {
            success: true,
            user: data,
        };
    } catch (error) {
        console.warn('[authService] getCurrentUser:', {
            message: error?.message,
        });

        return {
            success: false,
            message: 'Error de conexión al servidor',
            status: 0,
        };
    }
}

/**
 * =========================
 * REFRESH TOKEN
 * =========================
 */
export async function refreshAccessToken(
    refreshToken
) {
    if (!refreshToken) {
        return {
            success: false,
            message:
                'No se encontró un token de renovación.',
            status: 401,
            code: 'REFRESH_TOKEN_MISSING',
        };
    }

    try {
        const response = await fetch(
            `${API_URL}/auth/refresh`,
            {
                method: 'POST',
                cache: 'no-store',
                headers: {
                    Accept: 'application/json',
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    refresh_token: refreshToken,
                }),
            }
        );

        const data = await parseResponse(response);

        if (!response.ok) {
            return {
                success: false,
                message: getErrorMessage(
                    data,
                    'No se pudo renovar la sesión.'
                ),
                status: response.status,
                details: data,
                sessionExpired: [
                    400,
                    401,
                    403,
                    404,
                    500,
                ].includes(response.status),
            };
        }

        const nextAccessToken =
            data?.session?.access_token;

        const nextRefreshToken =
            data?.session?.refresh_token;

        if (!nextAccessToken) {
            return {
                success: false,
                message:
                    'El servidor no devolvió un nuevo token de acceso.',
                status: 500,
                details: data,
                sessionExpired: true,
            };
        }

        return {
            success: true,
            token: nextAccessToken,
            refreshToken:
                nextRefreshToken || refreshToken,
            user: data?.user || null,
            profile: data?.profile || null,
        };
    } catch (error) {
        console.warn(
            '[authService] refreshAccessToken:',
            {
                message: error?.message,
            }
        );

        return {
            success: false,
            message:
                'Error de conexión al renovar la sesión.',
            status: 0,
            sessionExpired: false,
        };
    }
}

/**
 * =========================
 * CHANGE PASSWORD
 * =========================
 */
export async function changePassword(payload) {
    const token =
        typeof window !== 'undefined'
            ? localStorage.getItem('token')
            : null;

    if (!token) {
        return {
            success: false,
            message: 'No hay sesión activa',
            status: 401,
        };
    }

    try {
        const response = await fetch(
            `${API_URL}/auth/change-password`,
            {
                method: 'POST',
                headers: {
                    Accept: 'application/json',
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify(payload),
            }
        );

        const data = await parseResponse(response);

        if (!response.ok) {
            return {
                success: false,
                message: getErrorMessage(
                    data,
                    'No se pudo cambiar la contraseña.'
                ),
                status: response.status,
                details: data,
            };
        }

        return {
            success: true,
            data,
        };
    } catch (error) {
        console.warn(
            '[authService] changePassword:',
            {
                message: error?.message,
            }
        );

        return {
            success: false,
            message:
                'Error de conexión al cambiar contraseña.',
            status: 0,
        };
    }
}

/**
 * =========================
 * ADMIN CHANGE USER PASSWORD
 * =========================
 */
export async function adminChangeUserPassword(
    userId,
    password
) {
    const token =
        typeof window !== 'undefined'
            ? localStorage.getItem('token')
            : null;

    if (!token) {
        return {
            success: false,
            message: 'No hay sesión activa',
            status: 401,
        };
    }

    try {
        const response = await fetch(
            `${API_URL}/auth/users/${userId}/password`,
            {
                method: 'PATCH',
                headers: {
                    Accept: 'application/json',
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify({
                    password,
                }),
            }
        );

        const data = await parseResponse(response);

        if (!response.ok) {
            return {
                success: false,
                message: getErrorMessage(
                    data,
                    'No se pudo cambiar la contraseña.'
                ),
                status: response.status,
                details: data,
            };
        }

        return {
            success: true,
            data,
        };
    } catch (error) {
        console.warn(
            '[authService] adminChangeUserPassword:',
            {
                message: error?.message,
            }
        );

        return {
            success: false,
            message: 'Error de conexión.',
            status: 0,
        };
    }
}

/**
 * =========================
 * CHANGE USER EMAIL
 * =========================
 */
export async function changeUserEmail(
    userId,
    email
) {
    const token =
        typeof window !== 'undefined'
            ? localStorage.getItem('token')
            : null;

    if (!token) {
        return {
            success: false,
            message: 'No hay sesión activa',
            status: 401,
        };
    }

    try {
        const response = await fetch(
            `${API_URL}/auth/users/${userId}/email`,
            {
                method: 'PATCH',
                headers: {
                    Accept: 'application/json',
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify({
                    email,
                }),
            }
        );

        const data = await parseResponse(response);

        if (!response.ok) {
            return {
                success: false,
                message: getErrorMessage(
                    data,
                    'No se pudo cambiar el correo.'
                ),
                status: response.status,
                details: data,
            };
        }

        return {
            success: true,
            data,
        };
    } catch (error) {
        console.warn(
            '[authService] changeUserEmail:',
            {
                message: error?.message,
            }
        );

        return {
            success: false,
            message: 'Error de conexión.',
            status: 0,
        };
    }
}