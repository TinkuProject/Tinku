// src/services/coinPackageService.js
const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

const authHeader = () => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
    return token ? { Authorization: `Bearer ${token}` } : {};
};

/* ============================================================
   📌 LISTAR TODOS LOS PAQUETES
   GET /coin-packages
============================================================ */
export async function listCoinPackages() {
    const res = await fetch(`${API_URL}/coin-packages`, {
        headers: { ...authHeader() },
    });

    if (!res.ok) {
        let msg = 'No se pudo obtener los coin packages';
        try { msg = (await res.json()).error || msg; } catch { }
        throw new Error(msg);
    }

    return res.json();
}

/* ============================================================
   📌 OBTENER POR ID
   GET /coin-packages/:id
============================================================ */
export async function getCoinPackage(id) {
    if (!id) throw new Error('ID requerido');

    const res = await fetch(`${API_URL}/coin-packages/${id}`, {
        headers: { ...authHeader() },
    });

    if (!res.ok) {
        let msg = 'No se pudo obtener el paquete';
        try { msg = (await res.json()).error || msg; } catch { }
        throw new Error(msg);
    }

    return res.json();
}

/* ============================================================
   📌 OBTENER EL PAQUETE "basic"
   GET /coin-packages/basic
============================================================ */
export async function getBasicCoinPackage() {
    const res = await fetch(`${API_URL}/coin-packages/basic`, {
        headers: { ...authHeader() },
    });

    if (!res.ok) {
        let msg = 'No se pudo obtener el paquete básico';
        try { msg = (await res.json()).error || msg; } catch { }
        throw new Error(msg);
    }

    return res.json();
}

/* ============================================================
   📌 CREAR PAQUETE
   POST /coin-packages
============================================================ */
export async function createCoinPackage(payload) {
    const res = await fetch(`${API_URL}/coin-packages`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...authHeader() },
        body: JSON.stringify(payload),
    });

    if (!res.ok) {
        let msg = 'No se pudo crear el coin package';
        try { msg = (await res.json()).error || msg; } catch { }
        throw new Error(msg);
    }

    return res.json();
}

/* ============================================================
   📌 ACTUALIZAR PAQUETE
   PUT /coin-packages/:id
============================================================ */
export async function updateCoinPackage(id, payload) {
    if (!id) throw new Error('ID requerido');

    const res = await fetch(`${API_URL}/coin-packages/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', ...authHeader() },
        body: JSON.stringify(payload),
    });

    if (!res.ok) {
        let msg = 'No se pudo actualizar el paquete';
        try { msg = (await res.json()).error || msg; } catch { }
        throw new Error(msg);
    }

    return res.json();
}

/* ============================================================
   📌 ELIMINAR PAQUETE
   DELETE /coin-packages/:id
============================================================ */
export async function deleteCoinPackage(id) {
    if (!id) throw new Error('ID requerido');

    const res = await fetch(`${API_URL}/coin-packages/${id}`, {
        method: 'DELETE',
        headers: { ...authHeader() },
    });

    if (!res.ok) {
        let msg = 'No se pudo eliminar el paquete';
        try { msg = (await res.json()).error || msg; } catch { }
        throw new Error(msg);
    }

    return res.json();
}
