// src/services/transactionService.js
const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

const authHeader = () => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
    return token ? { Authorization: `Bearer ${token}` } : {};
};

// GET /transactions   (opcionalmente ?user_id=...)
export async function listTransactions({ userId } = {}) {
    const params = new URLSearchParams();
    if (userId) params.set('user_id', String(userId));

    const url =
        params.toString().length > 0
            ? `${API_URL}/transactions?${params.toString()}`
            : `${API_URL}/transactions`;

    const res = await fetch(url, {
        headers: {
            ...authHeader(),
        },
    });

    if (!res.ok) {
        let msg = 'No se pudo obtener la lista de transacciones';
        try {
            const body = await res.json();
            msg = body.message || body.error || msg;
        } catch {
            // ignore
        }
        throw new Error(msg);
    }

    return res.json();
}

// GET /transactions/by-user/:user_id
export async function listTransactionsByUser(userId) {
    if (!userId) throw new Error('userId requerido');
    const res = await fetch(`${API_URL}/transactions/by-user/${userId}`, {
        headers: {
            ...authHeader(),
        },
    });

    if (!res.ok) {
        let msg = 'No se pudieron obtener las transacciones del usuario';
        try {
            const body = await res.json();
            msg = body.message || body.error || msg;
        } catch {
            // ignore
        }
        throw new Error(msg);
    }

    return res.json();
}

// GET /transactions/:id
export async function getTransaction(id) {
    if (!id && id !== 0) throw new Error('id requerido');
    const res = await fetch(`${API_URL}/transactions/${id}`, {
        headers: {
            ...authHeader(),
        },
    });

    if (!res.ok) {
        let msg = 'No se pudo obtener la transacción';
        try {
            const body = await res.json();
            msg = body.message || body.error || msg;
        } catch {
            // ignore
        }
        throw new Error(msg);
    }

    return res.json();
}

// POST /transactions
export async function createTransaction(payload) {
    const res = await fetch(`${API_URL}/transactions`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            ...authHeader(),
        },
        body: JSON.stringify(payload),
    });

    if (!res.ok) {
        let msg = 'No se pudo crear la transacción';
        try {
            const body = await res.json();
            msg = body.message || body.error || msg;
        } catch {
            // ignore
        }
        throw new Error(msg);
    }

    return res.json();
}

// PUT /transactions/:id
export async function updateTransaction(id, payload) {
    if (!id && id !== 0) throw new Error('id requerido');
    const res = await fetch(`${API_URL}/transactions/${id}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            ...authHeader(),
        },
        body: JSON.stringify(payload),
    });

    if (!res.ok) {
        let msg = 'No se pudo actualizar la transacción';
        try {
            const body = await res.json();
            msg = body.message || body.error || msg;
        } catch {
            // ignore
        }
        throw new Error(msg);
    }

    return res.json();
}

// DELETE /transactions/:id
export async function deleteTransaction(id) {
    if (!id && id !== 0) throw new Error('id requerido');
    const res = await fetch(`${API_URL}/transactions/${id}`, {
        method: 'DELETE',
        headers: {
            ...authHeader(),
        },
    });

    if (!res.ok) {
        let msg = 'No se pudo eliminar la transacción';
        try {
            const body = await res.json();
            msg = body.message || body.error || msg;
        } catch {
            // ignore
        }
        throw new Error(msg);
    }

    // tu API devuelve { message: "Transaction deleted successfully" }
    return res.json();
}
