// src/services/tagTouristPlaceService.js

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';
const BASE = '/tourist-place-tags';

const jsonHeaders = {
  'Content-Type': 'application/json',
};

function getToken() {
  if (typeof window === 'undefined') return null;
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

async function request(path, { method = 'GET', body, headers, signal } = {}) {
  const res = await fetch(`${API_URL}${path}`, {
    method,
    signal,
    cache: 'no-store',
    headers: {
      ...(body ? jsonHeaders : {}),
      ...authHeaders(),
      ...(headers || {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const ctype = res.headers.get('content-type') || '';
  const isJSON = ctype.includes('application/json');
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

export const TagTouristPlaceService = {
  getByPlace(placeId, opts = {}) {
    if (!placeId) throw new Error('placeId es requerido');

    return request(`${BASE}/place/${placeId}`, opts);
  },

  getByTag(tagId, opts = {}) {
    if (!tagId) throw new Error('tagId es requerido');

    return request(`${BASE}/tag/${tagId}`, opts);
  },

  create(payload, opts = {}) {
    return request(BASE, {
      method: 'POST',
      body: payload,
      ...opts,
    });
  },

  replaceTags(placeId, tagIds = [], opts = {}) {
    if (!placeId) throw new Error('placeId es requerido');

    return request(`${BASE}/place/${placeId}`, {
      method: 'PUT',
      body: {
        tagIds,
      },
      ...opts,
    });
  },

  remove(placeId, tagId, opts = {}) {
    if (!placeId || !tagId) {
      throw new Error('placeId y tagId son requeridos');
    }

    return request(`${BASE}/${placeId}/${tagId}`, {
      method: 'DELETE',
      ...opts,
    });
  },
};

export default TagTouristPlaceService;