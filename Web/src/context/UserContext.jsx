// File: src/context/UserContext.jsx

'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import { useRouter } from 'next/router';
import { refreshAccessToken } from '@/services/authService';

const UserContext = createContext(null);

const API_URL =
  process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

/**
 * Guarda una única promesa de renovación.
 *
 * Si varios componentes reciben 401 al mismo tiempo,
 * todos esperarán el mismo refresh en lugar de enviar
 * varias solicitudes a /auth/refresh.
 */
let refreshPromise = null;

function isBrowser() {
  return typeof window !== 'undefined';
}

function buildUser(user, profile) {
  if (!user && !profile) {
    return null;
  }

  return {
    id: user?.id || profile?.id || null,
    email: user?.email || profile?.email || null,
    role:
      profile?.role ||
      user?.role ||
      user?.app_metadata?.role ||
      user?.user_metadata?.role ||
      null,
    profile: profile || user?.profile || null,
  };
}

function buildUserFromCurrentUserResponse(data) {
  if (!data) {
    return null;
  }

  const profile = data?.profile || null;

  return {
    id: data?.id || profile?.id || null,
    email: data?.email || profile?.email || null,
    role:
      profile?.role ||
      data?.role ||
      data?.app_metadata?.role ||
      null,
    profile,
  };
}

function clearSession() {
  if (!isBrowser()) {
    return;
  }

  localStorage.removeItem('user');
  localStorage.removeItem('token');
  localStorage.removeItem('refresh_token');
}

function saveTokens(accessToken, refreshToken) {
  if (!isBrowser()) {
    return;
  }

  if (accessToken) {
    localStorage.setItem('token', accessToken);
  }

  if (refreshToken) {
    localStorage.setItem(
      'refresh_token',
      refreshToken
    );
  }
}

function getStoredSession() {
  if (!isBrowser()) {
    return {
      user: null,
      token: null,
      refreshToken: null,
    };
  }

  let savedUser = null;

  try {
    const rawUser = localStorage.getItem('user');

    savedUser = rawUser
      ? JSON.parse(rawUser)
      : null;
  } catch {
    localStorage.removeItem('user');
  }

  return {
    user: savedUser,
    token: localStorage.getItem('token'),
    refreshToken:
      localStorage.getItem('refresh_token'),
  };
}

/**
 * Ejecuta una única renovación de sesión.
 */
async function refreshSession() {
  if (!isBrowser()) {
    return {
      success: false,
      message: 'El navegador no está disponible',
    };
  }

  if (refreshPromise) {
    return refreshPromise;
  }

  const storedRefreshToken =
    localStorage.getItem('refresh_token');

  if (!storedRefreshToken) {
    clearSession();

    return {
      success: false,
      message: 'No existe refresh token',
      sessionExpired: true,
    };
  }

  refreshPromise = refreshAccessToken(
    storedRefreshToken
  )
    .then((result) => {
      if (!result?.success || !result?.token) {
        clearSession();

        return {
          ...result,
          success: false,
          sessionExpired: true,
        };
      }

      saveTokens(
        result.token,
        result.refreshToken || storedRefreshToken
      );

      return result;
    })
    .catch(() => {
      clearSession();

      return {
        success: false,
        message: 'No se pudo renovar la sesión',
        sessionExpired: true,
      };
    })
    .finally(() => {
      refreshPromise = null;
    });

  return refreshPromise;
}

/**
 * =========================
 * API FETCH CON REFRESH TOKEN
 * =========================
 *
 * Solo intenta refresh cuando recibe 401.
 * Un 403 se devuelve normalmente al componente.
 */
async function apiFetch(path, options = {}) {
  if (!isBrowser()) {
    throw new Error(
      'apiFetch solo puede ejecutarse en el navegador'
    );
  }

  const makeRequest = async (accessToken) => {
    const requestHeaders = new Headers(
      options.headers || {}
    );

    if (
      options.body &&
      !(options.body instanceof FormData) &&
      !requestHeaders.has('Content-Type')
    ) {
      requestHeaders.set(
        'Content-Type',
        'application/json'
      );
    }

    if (!requestHeaders.has('Accept')) {
      requestHeaders.set(
        'Accept',
        'application/json'
      );
    }

    if (accessToken) {
      requestHeaders.set(
        'Authorization',
        `Bearer ${accessToken}`
      );
    } else {
      requestHeaders.delete('Authorization');
    }

    return fetch(`${API_URL}${path}`, {
      ...options,
      cache: options.cache ?? 'no-store',
      headers: requestHeaders,
    });
  };

  const currentToken =
    localStorage.getItem('token');

  let response = await makeRequest(currentToken);

  /*
   * 403 significa falta de permisos.
   * No se renueva la sesión.
   */
  if (response.status !== 401) {
    return response;
  }

  const refreshResult = await refreshSession();

  if (!refreshResult?.success) {
    /*
     * No lanzamos una excepción aquí.
     * Devolvemos la respuesta 401 original para que
     * el hook o componente pueda manejarla.
     */
    return response;
  }

  response = await makeRequest(
    refreshResult.token
  );

  /*
   * Si el token recién renovado también falla,
   * la sesión ya no es recuperable.
   */
  if (response.status === 401) {
    clearSession();
  }

  return response;
}

/**
 * =========================
 * PROVIDER
 * =========================
 */
export const UserProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  const router = useRouter();

  /**
   * =========================
   * LOGOUT
   * =========================
   */
  const logout = useCallback(
    ({ redirect = true } = {}) => {
      setUser(null);
      clearSession();

      if (redirect) {
        router.replace('/login');
      }
    },
    [router]
  );

  /**
   * =========================
   * REHIDRATACIÓN + VALIDACIÓN
   * =========================
   */
  useEffect(() => {
    let active = true;

    const initSession = async () => {
      const stored = getStoredSession();

      if (stored.user && active) {
        setUser(stored.user);
      }

      if (!stored.token && !stored.refreshToken) {
        if (active) {
          setUser(null);
          setLoading(false);
        }

        return;
      }

      try {
        const response = await apiFetch('/auth/me', {
          method: 'GET',
        });

        if (!active) {
          return;
        }

        if (!response.ok) {
          /*
           * Un 401 después del intento de refresh
           * significa que la sesión ya expiró.
           */
          if (response.status === 401) {
            setUser(null);
            clearSession();
          }

          /*
           * No lanzamos Error para evitar overlays
           * y Uncaught (in promise).
           */
          return;
        }

        const data = await response.json();

        const fullUser =
          buildUserFromCurrentUserResponse(data);

        if (!fullUser?.id) {
          setUser(null);
          clearSession();
          return;
        }

        setUser(fullUser);

        localStorage.setItem(
          'user',
          JSON.stringify(fullUser)
        );
      } catch (error) {
        if (!active) {
          return;
        }

        console.warn(
          '[UserContext] No se pudo validar la sesión:',
          error?.message || 'Error desconocido'
        );

        /*
         * Un error de red no necesariamente significa
         * que el token sea inválido. Conservamos la
         * sesión local para no desconectar al usuario
         * por una caída temporal del servidor.
         */
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    };

    initSession();

    return () => {
      active = false;
    };
  }, []);

  /**
   * =========================
   * SYNC ENTRE PESTAÑAS
   * =========================
   */
  useEffect(() => {
    const onStorage = (event) => {
      if (
        event.key === 'token' &&
        !event.newValue
      ) {
        setUser(null);
        router.replace('/login');
        return;
      }

      if (event.key === 'user') {
        if (!event.newValue) {
          setUser(null);
          return;
        }

        try {
          setUser(JSON.parse(event.newValue));
        } catch {
          setUser(null);
        }
      }
    };

    window.addEventListener('storage', onStorage);

    return () => {
      window.removeEventListener(
        'storage',
        onStorage
      );
    };
  }, [router]);

  /**
   * =========================
   * LOGIN
   * =========================
   */
  const login = useCallback(
    async ({
      token,
      refreshToken,
      user: authUser,
      profile,
    }) => {
      if (!token) {
        return {
          success: false,
          message: 'Token no proporcionado',
        };
      }

      const fullUser = buildUser(
        authUser,
        profile
      );

      if (!fullUser?.id) {
        return {
          success: false,
          message:
            'No se pudo construir la información del usuario',
        };
      }

      saveTokens(token, refreshToken);

      localStorage.setItem(
        'user',
        JSON.stringify(fullUser)
      );

      setUser(fullUser);

      return {
        success: true,
        user: fullUser,
      };
    },
    []
  );

  /**
   * =========================
   * REQUIRE AUTH
   * =========================
   */
  const requireAuth = useCallback(() => {
    if (!loading && !user) {
      router.replace('/login');
      return false;
    }

    return Boolean(user);
  }, [user, loading, router]);

  /**
   * =========================
   * UPDATE USER
   * =========================
   */
  const updateUser = useCallback(async () => {
    try {
      const response = await apiFetch(
        '/auth/me',
        {
          method: 'GET',
        }
      );

      if (!response.ok) {
        if (response.status === 401) {
          setUser(null);
          clearSession();

          return {
            success: false,
            message: 'La sesión expiró',
            status: 401,
            sessionExpired: true,
          };
        }

        const errorData = await response
          .json()
          .catch(() => ({}));

        return {
          success: false,
          message:
            errorData?.message ||
            'Error al obtener el usuario actualizado',
          status: response.status,
          details: errorData,
        };
      }

      const data = await response.json();

      const updatedUser =
        buildUserFromCurrentUserResponse(data);

      if (!updatedUser?.id) {
        return {
          success: false,
          message:
            'La respuesta del servidor no contiene un usuario válido',
        };
      }

      setUser(updatedUser);

      localStorage.setItem(
        'user',
        JSON.stringify(updatedUser)
      );

      return {
        success: true,
        user: updatedUser,
      };
    } catch (error) {
      console.warn(
        '[UserContext] updateUser:',
        error?.message || 'Error desconocido'
      );

      return {
        success: false,
        message:
          'No se pudo conectar con el servidor',
        status: 0,
      };
    }
  }, []);

  const value = useMemo(
    () => ({
      user,
      loading,
      login,
      logout,
      requireAuth,
      updateUser,
      apiFetch,
      isAuthenticated: Boolean(user),
      role: user?.role || null,
    }),
    [
      user,
      loading,
      login,
      logout,
      requireAuth,
      updateUser,
    ]
  );

  return (
    <UserContext.Provider value={value}>
      {children}
    </UserContext.Provider>
  );
};

export function useUser() {
  const context = useContext(UserContext);

  if (!context) {
    throw new Error(
      'useUser debe utilizarse dentro de UserProvider'
    );
  }

  return context;
}