import { apiFetch } from '@/services/apiClient';

function getToken() {
  return typeof window === 'undefined' ? null : localStorage.getItem('token');
}

async function request(path, { method = 'GET', body, signal } = {}) {
  const token = getToken();
  const response = await apiFetch(path, {
    method,
    signal,
    cache: 'no-store',
    headers: {
      ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  const contentType = response.headers.get('content-type') ?? '';
  const data = contentType.includes('application/json')
    ? await response.json()
    : await response.text();

  if (!response.ok) {
    const error = new Error(data?.message || data?.error || response.statusText);
    error.status = response.status;
    error.data = data;
    throw error;
  }

  return data;
}

const WarehousesService = {
  listAdmin({ status, signal } = {}) {
    const query = status && status !== 'all'
      ? `?status=${encodeURIComponent(status)}`
      : '';

    return request(`/warehouses/admin/all${query}`, { signal });
  },

  get(id, { signal } = {}) {
    if (!id) throw new Error('El ID del almacén es requerido.');
    return request(`/warehouses/${id}`, { signal });
  },

  approve(id, message = '') {
    if (!id) throw new Error('El ID del almacén es requerido.');
    return request(`/warehouses/${id}/approve`, {
      method: 'PATCH',
      body: { message },
    });
  },

  reject(id, message) {
    if (!id) throw new Error('El ID del almacén es requerido.');
    return request(`/warehouses/${id}/reject`, {
      method: 'PATCH',
      body: { message },
    });
  },

  updateStatus(id, payload) {
    if (!id) throw new Error('El ID del almacén es requerido.');
    return request(`/warehouses/${id}/status`, {
      method: 'PATCH',
      body: payload,
    });
  },
};

export default WarehousesService;
