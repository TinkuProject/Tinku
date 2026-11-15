// src/services/businessService.js

const API_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3000";

const jsonHeaders = {
  "Content-Type": "application/json",
};

// ========================================
// TOKEN
// ========================================

function getToken() {
  if (typeof window === "undefined") return null;

  return localStorage.getItem("token");
}

function authHeaders() {
  const token = getToken();

  return token
    ? {
      Authorization: `Bearer ${token}`,
    }
    : {};
}

// ========================================
// REQUEST GENERAL
// ========================================

async function request(
  path,
  {
    method = "GET",
    body,
    headers,
    signal,
    authenticated = true,
  } = {}
) {
  const response = await fetch(`${API_URL}${path}`, {
    method,
    signal,
    cache: "no-store",
    headers: {
      ...(body !== undefined ? jsonHeaders : {}),
      ...(authenticated ? authHeaders() : {}),
      ...(headers ?? {}),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  const contentType = response.headers.get("content-type") ?? "";

  let data = null;

  if (response.status !== 204) {
    if (contentType.includes("application/json")) {
      data = await response.json();
    } else {
      data = await response.text();
    }
  }

  if (!response.ok) {
    const message =
      data?.message ||
      data?.error ||
      (typeof data === "string" && data.trim()
        ? data
        : `HTTP ${response.status}`);

    const error = new Error(message);

    error.status = response.status;
    error.data = data;

    throw error;
  }

  return data;
}

// ========================================
// NORMALIZAR IDS
// ========================================

function normalizeIds(ids = []) {
  return [
    ...new Set(
      ids
        .map((id) => Number(id))
        .filter((id) => Number.isInteger(id) && id > 0)
    ),
  ];
}

// ========================================
// GET PÚBLICOS
// ========================================

/**
 * Obtiene todos los negocios.
 *
 * GET /businesses
 */
async function list(options = {}) {
  return request("/businesses", {
    signal: options.signal,
    authenticated: false,
  });
}

/**
 * Obtiene un negocio por ID.
 *
 * GET /businesses/:id
 */
async function getById(id, options = {}) {
  if (!id) {
    throw new Error("El ID del negocio es requerido");
  }

  return request(`/businesses/${id}`, {
    signal: options.signal,
    authenticated: false,
  });
}

/**
 * Obtiene negocios por categoría.
 *
 * GET /businesses/category/:categoryId
 */
async function getByCategory(categoryId, options = {}) {
  if (!categoryId) {
    throw new Error("El ID de la categoría es requerido");
  }

  return request(`/businesses/category/${categoryId}`, {
    signal: options.signal,
    authenticated: false,
  });
}

/**
 * Obtiene varios negocios mediante sus IDs.
 *
 * GET /businesses/batch?ids=1,2,3
 */
async function getByIds(ids, options = {}) {
  const normalizedIds = normalizeIds(ids);

  if (normalizedIds.length === 0) {
    return [];
  }

  const params = new URLSearchParams({
    ids: normalizedIds.join(","),
  });

  return request(`/businesses/batch?${params.toString()}`, {
    signal: options.signal,
    authenticated: false,
  });
}

// ========================================
// GET AUTENTICADOS
// ========================================

/**
 * Obtiene los negocios del usuario autenticado.
 *
 * GET /businesses/mine
 */
async function getMine(options = {}) {
  return request("/businesses/mine", {
    signal: options.signal,
  });
}

/**
 * Obtiene negocios filtrados por estado.
 *
 * Roles:
 * - admin
 * - master
 *
 * GET /businesses/status?status=active
 */
async function getByStatus(status, options = {}) {
  if (!status) {
    throw new Error("El estado del negocio es requerido");
  }

  const params = new URLSearchParams({
    status,
  });

  return request(`/businesses/status?${params.toString()}`, {
    signal: options.signal,
  });
}

// ========================================
// CREATE
// ========================================

/**
 * Crea un negocio directamente desde el sistema.
 *
 * Roles:
 * - admin
 * - master
 *
 * POST /businesses/system
 *
 * El backend asigna automáticamente:
 * - owner_id: null
 * - status: active
 * - validated: true
 */
async function createSystem(payload, options = {}) {
  if (!payload || typeof payload !== "object") {
    throw new Error("Los datos del negocio son requeridos");
  }

  return request("/businesses/system", {
    method: "POST",
    body: payload,
    signal: options.signal,
  });
}

/**
 * Crea un negocio asociado al usuario autenticado.
 *
 * Roles:
 * - partner
 * - admin
 * - master
 *
 * POST /businesses
 */
async function createOwned(payload, options = {}) {
  if (!payload || typeof payload !== "object") {
    throw new Error("Los datos del negocio son requeridos");
  }

  return request("/businesses", {
    method: "POST",
    body: payload,
    signal: options.signal,
  });
}

// Alias para mantener compatibilidad con componentes anteriores.
async function create(payload, options = {}) {
  return createOwned(payload, options);
}

// ========================================
// UPDATE
// ========================================

/**
 * Actualiza un negocio.
 *
 * Roles:
 * - admin
 * - master
 *
 * PUT /businesses/:id
 */
async function update(id, payload, options = {}) {
  if (!id) {
    throw new Error("El ID del negocio es requerido");
  }

  if (!payload || typeof payload !== "object") {
    throw new Error("Los datos del negocio son requeridos");
  }

  return request(`/businesses/${id}`, {
    method: "PUT",
    body: payload,
    signal: options.signal,
  });
}

// ========================================
// MODERACIÓN
// ========================================

/**
 * Aprueba un negocio pendiente.
 *
 * Roles:
 * - admin
 * - master
 *
 * PATCH /businesses/:id/validate
 */
async function validate(id, message = "", options = {}) {
  if (!id) {
    throw new Error("El ID del negocio es requerido");
  }

  return request(`/businesses/${id}/validate`, {
    method: "PATCH",
    body: {
      message: typeof message === "string" ? message.trim() : "",
    },
    signal: options.signal,
  });
}

/**
 * Rechaza un negocio pendiente.
 *
 * Roles:
 * - admin
 * - master
 *
 * PATCH /businesses/:id/reject
 */
async function reject(id, message = "", options = {}) {
  if (!id) {
    throw new Error("El ID del negocio es requerido");
  }

  return request(`/businesses/${id}/reject`, {
    method: "PATCH",
    body: {
      message: typeof message === "string" ? message.trim() : "",
    },
    signal: options.signal,
  });
}

// ========================================
// DELETE
// ========================================

/**
 * Realiza eliminación lógica del negocio.
 *
 * Roles:
 * - partner
 * - admin
 * - master
 *
 * DELETE /businesses/:id
 */
async function softDelete(id, options = {}) {
  if (!id) {
    throw new Error("El ID del negocio es requerido");
  }

  return request(`/businesses/${id}`, {
    method: "DELETE",
    signal: options.signal,
  });
}

// Alias para mantener compatibilidad.
async function remove(id, options = {}) {
  return softDelete(id, options);
}

// ========================================
// EXPORT
// ========================================

const BusinessService = {
  list,
  getAll: list,
  get: getById,
  getById,
  getByIds,
  getByCategory,
  getMine,
  getByStatus,

  create,
  createOwned,
  createSystem,

  update,

  validate,
  approve: validate,
  reject,

  softDelete,
  remove,
};

export {
  BusinessService,
  list,
  getById,
  getByIds,
  getByCategory,
  getMine,
  getByStatus,
  create,
  createOwned,
  createSystem,
  update,
  validate,
  reject,
  softDelete,
  remove,
};

export default BusinessService;