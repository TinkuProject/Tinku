// File: src/hooks/usePaymentRequests.js

'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import toast from 'react-hot-toast';

import { useUser } from '@/context/UserContext';
import PaymentRequestsService from '@/services/paymentRequestsService';
import mediaService from '@/services/mediaService';

export default function usePaymentRequests() {
    const { user: currentUser } = useUser();

    // =====================================================
    // USER / ROLE
    // =====================================================

    const currentRole =
        currentUser?.role ||
        currentUser?.profile?.role ||
        null;

    const isAdmin =
        currentRole === 'admin' ||
        currentRole === 'master';

    const isOwner =
        currentRole === 'user' ||
        currentRole === 'partner';

    // =====================================================
    // STATE
    // =====================================================

    const [rows, setRows] = useState([]);
    const [loading, setLoading] = useState(false);
    const [savingId, setSavingId] = useState(null);

    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState('');

    const [error, setError] = useState('');

    // =====================================================
    // HELPERS
    // =====================================================

    const normalizeRequests = useCallback((data) => {
        if (Array.isArray(data)) {
            return data;
        }

        if (Array.isArray(data?.data)) {
            return data.data;
        }

        if (Array.isArray(data?.requests)) {
            return data.requests;
        }

        if (Array.isArray(data?.items)) {
            return data.items;
        }

        return [];
    }, []);

    const getPaymentId = useCallback((item) => {
        return (
            item?.paymentId ??
            item?.payment_id ??
            item?.payment?.id ??
            null
        );
    }, []);

    // =====================================================
    // LOAD
    // =====================================================

    const loadRequests = useCallback(async () => {
        if (!currentRole) {
            setRows([]);
            setError('');
            setLoading(false);
            return;
        }

        if (!isAdmin && !isOwner) {
            setRows([]);
            setError('');
            setLoading(false);
            return;
        }

        setLoading(true);
        setError('');

        try {
            let data;

            if (isAdmin) {
                data = await PaymentRequestsService.list(
                    statusFilter
                        ? { status: statusFilter }
                        : {}
                );
            } else {
                data = await PaymentRequestsService.getMine();
            }

            const requests = normalizeRequests(data);

            // =========================================
            // CARGAR MEDIA DE LOS PAYMENTS
            // =========================================

            const paymentIds = [
                ...new Set(
                    requests
                        .map((item) => Number(getPaymentId(item)))
                        .filter((id) => Number.isFinite(id))
                ),
            ];

            let mediaMap = {};

            if (paymentIds.length > 0) {
                try {
                    mediaMap = await mediaService.getByEntities(
                        'payment',
                        paymentIds
                    );
                } catch (mediaError) {
                    console.error(
                        '[usePaymentRequests] media:',
                        mediaError
                    );

                    mediaMap = {};
                }
            }

            const parsed = requests.map((item) => {
                const paymentId = getPaymentId(item);

                const media =
                    mediaMap?.[paymentId] ||
                    mediaMap?.[String(paymentId)] ||
                    [];

                const sortedMedia = Array.isArray(media)
                    ? [...media].sort((a, b) => {
                        const dateA = new Date(
                            a?.created_at ||
                            a?.createdAt ||
                            0
                        ).getTime();

                        const dateB = new Date(
                            b?.created_at ||
                            b?.createdAt ||
                            0
                        ).getTime();

                        return dateB - dateA;
                    })
                    : [];

                const proof =
                    sortedMedia?.[0]?.url ||
                    sortedMedia?.[0]?.image_url ||
                    sortedMedia?.[0]?.media_url ||
                    sortedMedia?.[0]?.path ||
                    '';

                return {
                    ...item,
                    paymentId,
                    media: sortedMedia,
                    proof_url: proof,
                };
            });

            setRows(parsed);
        } catch (err) {
            console.error(
                '[usePaymentRequests] load:',
                err
            );

            setRows([]);

            const message = String(
                err?.message || ''
            ).toLowerCase();

            const userNotFound =
                err?.status === 404 ||
                message.includes('user not found in db') ||
                message.includes('user not found');

            if (userNotFound) {
                setError(
                    isOwner
                        ? 'Tu usuario todavía no tiene solicitudes de pago registradas.'
                        : 'El usuario asociado a la sesión no fue encontrado en la base de datos.'
                );

                return;
            }

            if (err?.status === 401) {
                setError(
                    'Tu sesión no es válida o ha expirado.'
                );

                return;
            }

            if (err?.status === 403) {
                setError(
                    'No tienes permisos para consultar las solicitudes de pago.'
                );

                return;
            }

            setError(
                err?.message ||
                'No se pudieron cargar las solicitudes.'
            );
        } finally {
            setLoading(false);
        }
    }, [
        currentRole,
        isAdmin,
        isOwner,
        statusFilter,
        normalizeRequests,
        getPaymentId,
    ]);

    useEffect(() => {
        if (!currentRole) {
            return;
        }

        loadRequests();
    }, [currentRole, loadRequests]);

    // =====================================================
    // FILTERED
    // =====================================================

    const filteredRows = useMemo(() => {
        const term = search
            .trim()
            .toLowerCase();

        if (!term) {
            return rows;
        }

        return rows.filter((row) =>
            [
                row?.id,
                row?.userId,
                row?.user_id,
                row?.paymentId,
                row?.payment_id,
                row?.type,
                row?.status,
                row?.comment,
                row?.user?.email,
                row?.user?.username,
            ]
                .map((value) =>
                    String(value ?? '').toLowerCase()
                )
                .some((value) => value.includes(term))
        );
    }, [rows, search]);

    // =====================================================
    // APPROVE
    // =====================================================

    const approve = useCallback(
        async (id, comment = '') => {
            if (!id || !isAdmin) {
                return false;
            }

            setSavingId(id);

            const toastId = toast.loading(
                'Aprobando pago…'
            );

            try {
                const updated =
                    await PaymentRequestsService.approve(
                        id,
                        comment
                    );

                setRows((previous) =>
                    previous.map((row) =>
                        String(row.id) === String(id)
                            ? {
                                ...row,
                                ...updated,
                            }
                            : row
                    )
                );

                toast.success('Pago aprobado', {
                    id: toastId,
                });

                return true;
            } catch (err) {
                console.error(
                    '[usePaymentRequests] approve:',
                    err
                );

                toast.error(
                    err?.message ||
                    'No se pudo aprobar el pago.',
                    { id: toastId }
                );

                return false;
            } finally {
                setSavingId(null);
            }
        },
        [isAdmin]
    );

    // =====================================================
    // REJECT
    // =====================================================

    const reject = useCallback(
        async (id, comment = '') => {
            if (!id || !isAdmin) {
                return false;
            }

            setSavingId(id);

            const toastId = toast.loading(
                'Rechazando pago…'
            );

            try {
                const updated =
                    await PaymentRequestsService.reject(
                        id,
                        comment
                    );

                setRows((previous) =>
                    previous.map((row) =>
                        String(row.id) === String(id)
                            ? {
                                ...row,
                                ...updated,
                            }
                            : row
                    )
                );

                toast.success('Pago rechazado', {
                    id: toastId,
                });

                return true;
            } catch (err) {
                console.error(
                    '[usePaymentRequests] reject:',
                    err
                );

                toast.error(
                    err?.message ||
                    'No se pudo rechazar el pago.',
                    { id: toastId }
                );

                return false;
            } finally {
                setSavingId(null);
            }
        },
        [isAdmin]
    );

    // =====================================================
    // RETURN
    // =====================================================

    return {
        // data
        rows: filteredRows,
        rawRows: rows,

        // role
        currentRole,
        isAdmin,
        isOwner,

        // state
        loading,
        savingId,
        error,

        search,
        setSearch,

        statusFilter,
        setStatusFilter,

        // actions
        reload: loadRequests,
        approve,
        reject,
    };
}