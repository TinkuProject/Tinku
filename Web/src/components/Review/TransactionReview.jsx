// src/components/Review/TransactionReview.jsx
'use client';

import { useState, useMemo } from 'react';
import { FaSyncAlt, FaSearch, FaMoneyCheckAlt } from 'react-icons/fa';
import toast from 'react-hot-toast';

import useUsers from '@/hooks/useUsers';
import usePaymentRequests from '@/hooks/usePaymentRequests';
import useSubscriptionPlans from '@/hooks/useSubscriptionPlans';

import { updateUser as updateUserService } from '@/services/usersService';
import { useUser } from '@/context/UserContext';
import { NotificationsService } from '@/services/notificationsService';

import TransactionCardReview from './TransactionCardReview';
import TransactionViewReview from './TransactionViewReview';

const UI = {
    primary: '#0077B6',
    border: '#E2E8F0',
    soft: '#F8FAFC',
};

const STATUS_TABS = [
    { key: 'pending', label: 'Pendientes' },
    { key: 'approved', label: 'Aprobadas' },
    { key: 'rejected', label: 'Rechazadas' },
    { key: '', label: 'Todas' },
];
// helper saldo tinku seguro
function safeNumber(n, fallback = 0) {
    if (typeof n === 'number' && !Number.isNaN(n)) return n;
    if (n == null) return fallback;
    const parsed = Number(n);
    return Number.isNaN(parsed) ? fallback : parsed;
}

export default function TransactionReview() {
    const {
        rows: pageRows,
        loading,
        error: err,

        search,
        setSearch,

        statusFilter,
        setStatusFilter,

        reload,

        savingId: rowSavingId,

        approve,
        reject,
    } = usePaymentRequests();

    // Usuarios
    const { users, fetchAll: reloadUsers } = useUsers?.() || {};

    // User actual (admin/master → sender_id)
    const { user: currentUser } = useUser();
    const senderId =
        currentUser?.id ??
        currentUser?.idUser ??
        currentUser?.user_id ??
        currentUser?.uid ??
        null;


    // Planes de suscripción (para included_tinku)
    const { plans } = useSubscriptionPlans({ onlyActive: false });

    const [selectedTx, setSelectedTx] = useState(null);
    const [modalOpen, setModalOpen] = useState(false);

    // Usuario para el modal
    const selectedUser = useMemo(() => {
        if (!selectedTx || !users?.length) return null;

        const uid = String(
            selectedTx.userId ||
            selectedTx.user_id ||
            ''
        ).trim();
        if (!uid) return null;

        return (
            users.find(
                (u) =>
                    String(u.id ?? '').trim() === uid ||
                    String(u.auth_id ?? '').trim() === uid ||
                    String(u.user_id ?? '').trim() === uid
            ) || null
        );
    }, [selectedTx, users]);

    // Índice de usuarios (para cards y promoción a partner)
    const userIndex = useMemo(() => {
        const map = new Map();
        if (!users) return map;

        for (const u of users) {
            const keys = [u.id, u.auth_id, u.user_id];
            for (const k of keys) {
                if (k != null && k !== '') {
                    map.set(String(k).trim(), u);
                }
            }
        }
        return map;
    }, [users]);

    // Índice de planes por id (para included_tinku)
    const plansIndex = useMemo(() => {
        const map = new Map();
        if (!Array.isArray(plans)) return map;
        for (const p of plans) {
            if (p?.id != null) {
                map.set(Number(p.id), p);
            }
        }
        return map;
    }, [plans]);

    // Helper: ¿tx en BOB?
    const isTxBOB = (tx) =>
        String(tx?.currency ?? 'BOB').toUpperCase() === 'BOB';

    const handleEvaluate = async (tx) => {
        setSelectedTx(tx);
        setModalOpen(true);
    };

    const handleCloseModal = () => {
        setModalOpen(false);
        setSelectedTx(null);
    };

    const handleApprove = async (tx) => {
        if (!tx?.id) return;

        try {
            const ok = await approve(tx.id);

            if (!ok) {
                await reload();
                handleCloseModal();
                return;
            }

            toast.success('Solicitud aprobada');
            await reload();
            handleCloseModal();
        } catch (err) {
            if (String(err?.message || '').includes('Payment already processed')) {
                toast.error('Este pago ya fue procesado.');
                await reload();
                handleCloseModal();
                return;
            }

            toast.error(err?.message || 'No se pudo aprobar');
        }
    };

    const handleReject = async (tx) => {
        if (!tx?.id) return;

        try {
            const ok = await reject(tx.id);

            if (!ok) {
                await reload();
                handleCloseModal();
                return;
            }

            toast.success('Solicitud rechazada');
            await reload();
            handleCloseModal();
        } catch (err) {
            if (String(err?.message || '').includes('Payment already processed')) {
                toast.error('Este pago ya fue procesado.');
                await reload();
                handleCloseModal();
                return;
            }

            toast.error(err?.message || 'No se pudo rechazar');
        }
    };

    const handleChangeTab = (key) => {
        setStatusFilter(key);
    };

    return (
        <div className="w-full mx-auto px-4 md:px-6 py-4">
            {/* Título */}
            <div className="mb-4">
                <h1 className="text-2xl font-bold text-gray-800 flex items-center gap-2">
                    <FaMoneyCheckAlt className="text-gray-500" />
                    Centro de Revisiones
                </h1>
                <p className="text-sm text-gray-500 mt-1">
                    Revisión de <span className="font-semibold">Transacciones</span>:
                    aprueba o rechaza pagos pendientes{' '}
                    <span className="font-semibold">solo en moneda BOB</span>.
                </p>
            </div>

            {/* Tabs + búsqueda + recargar */}
            <div className="flex flex-col gap-3 mb-4">
                {/* Tabs */}
                <div className="flex flex-wrap items-center gap-2">
                    {STATUS_TABS.map((tab) => {
                        const active =
                            tab.key === 'all'
                                ? statusFilter === 'all'
                                : statusFilter === tab.key;

                        return (
                            <button
                                key={tab.key}
                                type="button"
                                onClick={() => handleChangeTab(tab.key)}
                                className={`px-3 py-1.5 text-xs font-semibold rounded-full border transition ${active
                                    ? 'bg-white shadow-sm'
                                    : 'bg-slate-50 hover:bg-white'
                                    }`}
                                style={{
                                    borderColor: active ? UI.primary : UI.border,
                                    color: active ? UI.primary : '#4B5563',
                                }}
                            >
                                {tab.label}
                            </button>
                        );
                    })}
                </div>

                {/* Search + Recargar */}
                <div className="flex flex-wrap items-center gap-2">
                    <div className="flex-1 min-w-[220px] relative">
                        <FaSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xs" />
                        <input
                            type="text"
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                            placeholder="Buscar por usuario, monto, tipo, comentario..."
                            className="w-full pl-8 pr-3 py-2 text-xs rounded-lg border focus:outline-none focus:ring-1"
                            style={{
                                borderColor: UI.border,
                            }}
                        />
                    </div>

                    <button
                        type="button"
                        onClick={() => reload()}
                        className="inline-flex items-center gap-2 text-xs font-semibold rounded-lg px-3 py-2 border bg-white hover:bg-slate-50"
                        style={{ borderColor: UI.border }}
                    >
                        <FaSyncAlt className={loading ? 'animate-spin' : ''} />
                        Recargar
                    </button>
                </div>
            </div>

            {/* Error / loading */}
            {err && <div className="mb-3 text-xs text-red-600">{err}</div>}

            {/* Grid de cards */}
            {loading ? (
                <p className="text-sm text-gray-500">Cargando transacciones...</p>
            ) : pageRows.length === 0 ? (
                <p className="text-sm text-gray-500">
                    No se encontraron transacciones con los filtros seleccionados.
                </p>
            ) : (
                <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                    {pageRows.map((tx) => {
                        const key = String(tx.user_id ?? '').trim();
                        const cardUser = key ? userIndex.get(key) ?? null : null;

                        return (
                            <TransactionCardReview
                                key={tx.id}
                                tx={tx}
                                user={cardUser}
                                savingId={rowSavingId}
                                onEvaluate={handleEvaluate}
                                onApprove={handleApprove}
                                onReject={handleReject}
                            />
                        );
                    })}
                </div>
            )}

            {/* Modal */}
            <TransactionViewReview
                tx={selectedTx}
                user={selectedUser}
                proofUrl={selectedTx?.proof_url}
                isOpen={modalOpen}
                onClose={handleCloseModal}
                onApprove={handleApprove}
                onReject={handleReject}
                savingId={rowSavingId}
            />
        </div>
    );
}
