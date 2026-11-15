// File: src/services/paymentRequestsService.js

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
  const contentType = res.headers.get('content-type') || '';

  if (res.status === 204) {
    return null;
  }

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

function createRequestError(res, data) {
  const backendMessage =
    typeof data === 'string'
      ? data
      : data?.message ||
      data?.error ||
      data?.details ||
      null;

  const error = new Error(
    backendMessage || `Error HTTP ${res.status}`
  );

  error.name = 'PaymentRequestsError';
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
  const token = getToken();

  if (!token) {
    const error = new Error(
      'No se encontró una sesión activa.'
    );

    error.name = 'PaymentRequestsError';
    error.status = 401;
    error.code = 'TOKEN_NOT_FOUND';

    throw error;
  }

  let res;

  try {
    res = await fetch(`${API_URL}${path}`, {
      method,
      signal,
      cache: 'no-store',
      headers: {
        Accept: 'application/json',
        ...(body
          ? { 'Content-Type': 'application/json' }
          : {}),
        ...authHeaders(),
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

    networkError.name = 'PaymentRequestsError';
    networkError.status = 0;
    networkError.code = 'NETWORK_ERROR';
    networkError.originalError = error;

    throw networkError;
  }

  const data = await parseResponse(res);

  if (!res.ok) {
    throw createRequestError(res, data);
  }

  return data;
}

export const PaymentRequestsService = {
  create(payload, opts = {}) {
    if (!payload?.paymentId) {
      throw new Error('paymentId is required');
    }

    if (!payload?.type) {
      throw new Error('type is required');
    }

    return request('/payment-requests', {
      method: 'POST',
      body: {
        paymentId: Number(payload.paymentId),
        type: payload.type,
        ...(payload.targetId !== undefined &&
          payload.targetId !== null
          ? {
            targetId: Number(payload.targetId),
          }
          : {}),
      },
      ...opts,
    });
  },

  getMine(opts = {}) {
    return request('/payment-requests/me', {
      method: 'GET',
      ...opts,
    });
  },

  list(params = {}, opts = {}) {
    return request(
      `/payment-requests${qs(params)}`,
      {
        method: 'GET',
        ...opts,
      }
    );
  },

  get(id, opts = {}) {
    if (!id) {
      throw new Error('id is required');
    }

    return request(`/payment-requests/${id}`, {
      method: 'GET',
      ...opts,
    });
  },

  approve(id, comment = '', opts = {}) {
    if (!id) {
      throw new Error('id is required');
    }

    return request(
      `/payment-requests/${id}/approve`,
      {
        method: 'PATCH',
        body: {
          ...(comment?.trim()
            ? { comment: comment.trim() }
            : {}),
        },
        ...opts,
      }
    );
  },

  reject(id, comment = '', opts = {}) {
    if (!id) {
      throw new Error('id is required');
    }

    return request(
      `/payment-requests/${id}/reject`,
      {
        method: 'PATCH',
        body: {
          ...(comment?.trim()
            ? { comment: comment.trim() }
            : {}),
        },
        ...opts,
      }
    );
  },
};

export default PaymentRequestsService;