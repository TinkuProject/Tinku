import { refreshAccessToken } from '@/services/authService';

const API_URL =
  process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

let refreshPromise = null;

function isBrowser() {
  return typeof window !== 'undefined';
}

function clearSession() {
  localStorage.removeItem('user');
  localStorage.removeItem('token');
  localStorage.removeItem('refresh_token');
}

async function refreshSession() {
  if (refreshPromise) return refreshPromise;

  const refreshToken = localStorage.getItem('refresh_token');

  if (!refreshToken) {
    clearSession();
    return null;
  }

  refreshPromise = refreshAccessToken(refreshToken)
    .then((result) => {
      if (!result?.success || !result?.token) {
        clearSession();
        return null;
      }

      localStorage.setItem('token', result.token);
      localStorage.setItem(
        'refresh_token',
        result.refreshToken || refreshToken
      );

      return result.token;
    })
    .catch(() => {
      clearSession();
      return null;
    })
    .finally(() => {
      refreshPromise = null;
    });

  return refreshPromise;
}

/**
 * Fetch autenticado que renueva una vez el token cuando la API responde 401.
 */
export async function apiFetch(path, options = {}) {
  if (!isBrowser()) {
    throw new Error('apiFetch solo puede ejecutarse en el navegador');
  }

  const makeRequest = (token) => {
    const headers = new Headers(options.headers || {});

    if (!headers.has('Accept')) {
      headers.set('Accept', 'application/json');
    }

    if (token) {
      headers.set('Authorization', `Bearer ${token}`);
    } else {
      headers.delete('Authorization');
    }

    return fetch(`${API_URL}${path}`, {
      ...options,
      cache: options.cache ?? 'no-store',
      headers,
    });
  };

  let response = await makeRequest(localStorage.getItem('token'));

  if (response.status !== 401) return response;

  const token = await refreshSession();
  if (!token) return response;

  response = await makeRequest(token);

  if (response.status === 401) clearSession();

  return response;
}
