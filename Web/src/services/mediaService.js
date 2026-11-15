// src/services/mediaService.js

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

function authHeader() {
  if (typeof window === 'undefined') return {};

  const token = localStorage.getItem('token');

  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function http(path, { method = 'GET', body, signal, headers } = {}) {
  const isFormData = body instanceof FormData;

  const res = await fetch(`${API_URL}${path}`, {
    method,
    signal,
    cache: 'no-store',
    headers: isFormData
      ? { ...authHeader(), ...(headers || {}) }
      : {
        'Content-Type': 'application/json',
        ...authHeader(),
        ...(headers || {}),
      },
    body: body ? (isFormData ? body : JSON.stringify(body)) : undefined,
  });

  let json = null;

  try {
    json = await res.json();
  } catch (_) { }

  if (!res.ok) {
    console.error('MEDIA SERVICE ERROR:', {
      status: res.status,
      path,
      json,
    });

    const e = new Error(json?.error || json?.message || `HTTP ${res.status}`);
    e.status = res.status;
    e.details = json;
    e.data = json;
    throw e;
  }

  return res.status === 204 ? null : json ?? {};
}

function qs(params = {}) {
  const q = new URLSearchParams();

  Object.entries(params).forEach(([key, value]) => {
    if (value === undefined || value === null || value === '') return;
    q.set(key, String(value));
  });

  const s = q.toString();

  return s ? `?${s}` : '';
}

function toArray(resp) {
  if (Array.isArray(resp)) return resp;
  if (Array.isArray(resp?.data)) return resp.data;
  if (Array.isArray(resp?.items)) return resp.items;
  return [];
}

export const mediaService = {
  getAll({ signal } = {}) {
    return http('/media', { signal });
  },

  list(params = {}, { signal } = {}) {
    return http(`/media${qs(params)}`, { signal }).then(toArray);
  },

  get(id, { signal } = {}) {
    return http(`/media/${id}`, { signal });
  },

  getById(id, { signal } = {}) {
    return this.get(id, { signal });
  },

  listByEntity(entity_type, entity_id, { signal } = {}) {
    return http(
      `/media/entity${qs({
        entity_type,
        entity_id,
      })}`,
      { signal }
    ).then(toArray);
  },

  listByTarget(target_type, target_id, { signal } = {}) {
    return this.listByEntity(target_type, target_id, { signal });
  },

  getPrimaryByEntity(entity_type, entity_id, { signal } = {}) {
    return http(
      `/media/entity/primary${qs({
        entity_type,
        entity_id,
      })}`,
      { signal }
    );
  },

  getByEntities(entity_type, entity_ids = [], { signal } = {}) {
    const ids = Array.isArray(entity_ids) ? entity_ids.join(',') : entity_ids;

    return http(
      `/media/entities${qs({
        entity_type,
        entity_ids: ids,
      })}`,
      { signal }
    );
  },

  create(payload, { signal } = {}) {
    return http('/media', {
      method: 'POST',
      body: payload,
      signal,
    });
  },

  update(id, payload, { signal } = {}) {
    return http(`/media/${id}`, {
      method: 'PUT',
      body: payload,
      signal,
    });
  },

  remove(id, { signal } = {}) {
    return http(`/media/${id}`, {
      method: 'DELETE',
      signal,
    });
  },

  delete(id, { signal } = {}) {
    return this.remove(id, { signal });
  },

  deleteAllByEntity(entity_type, entity_id, { signal } = {}) {
    return http(
      `/media/entity${qs({
        entity_type,
        entity_id,
      })}`,
      {
        method: 'DELETE',
        signal,
      }
    );
  },

  deleteByUrl(url, { signal } = {}) {
    return http('/media/url', {
      method: 'DELETE',
      body: { url },
      signal,
    });
  },
};

export default mediaService;