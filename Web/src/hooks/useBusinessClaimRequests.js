// src/hooks/useBusinessClaimRequests.js
'use client';

import {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from 'react';

import BusinessClaimRequestsService from '@/services/businessClaimRequestsService';

export default function useBusinessClaimRequests({
    autoLoad = false,
    initialStatus = 'pending',
} = {}) {
    const [rows, setRows] = useState([]);
    const [loading, setLoading] = useState(false);
    const [savingId, setSavingId] = useState(null);
    const [error, setError] = useState('');

    const [statusFilter, setStatusFilter] = useState(initialStatus);
    const [search, setSearch] = useState('');

    const abortRef = useRef(null);

    const abortPrevious = useCallback(() => {
        if (abortRef.current) {
            abortRef.current.abort();
            abortRef.current = null;
        }
    }, []);

    const normalizeResponse = useCallback((response) => {
        if (Array.isArray(response)) return response;
        if (Array.isArray(response?.data)) return response.data;
        if (Array.isArray(response?.items)) return response.items;
        if (Array.isArray(response?.results)) return response.results;
        return [];
    }, []);

    // =====================================================
    // LOAD PENDING
    // =====================================================

    const fetchPending = useCallback(async () => {
        abortPrevious();

        const controller = new AbortController();
        abortRef.current = controller;

        setLoading(true);
        setError('');

        try {
            const response =
                await BusinessClaimRequestsService.getPending({
                    signal: controller.signal,
                });

            setRows(normalizeResponse(response));
        } catch (err) {
            if (err?.name !== 'AbortError') {
                setError(
                    err?.message ||
                    'No se pudieron cargar las reclamaciones pendientes'
                );
            }
        } finally {
            setLoading(false);
            abortRef.current = null;
        }
    }, [abortPrevious, normalizeResponse]);

    // =====================================================
    // LOAD ALL
    // =====================================================

    const fetchAll = useCallback(
        async ({ limit = 100, offset = 0 } = {}) => {
            abortPrevious();

            const controller = new AbortController();
            abortRef.current = controller;

            setLoading(true);
            setError('');

            try {
                const response =
                    await BusinessClaimRequestsService.getAll(
                        {
                            limit,
                            offset,
                        },
                        {
                            signal: controller.signal,
                        }
                    );

                setRows(normalizeResponse(response));
            } catch (err) {
                if (err?.name !== 'AbortError') {
                    setError(
                        err?.message ||
                        'No se pudieron cargar las reclamaciones'
                    );
                }
            } finally {
                setLoading(false);
                abortRef.current = null;
            }
        },
        [abortPrevious, normalizeResponse]
    );

    // =====================================================
    // LOAD BY STATUS
    // =====================================================

    const fetchByCurrentFilter = useCallback(async () => {
        if (statusFilter === 'pending') {
            await fetchPending();
            return;
        }

        await fetchAll();
    }, [statusFilter, fetchPending, fetchAll]);

    // =====================================================
    // GET BY ID
    // =====================================================

    const getById = useCallback(async (id) => {
        if (!id) {
            throw new Error('id is required');
        }

        setError('');

        try {
            return await BusinessClaimRequestsService.getById(id);
        } catch (err) {
            setError(
                err?.message ||
                'No se pudo obtener la reclamación'
            );

            throw err;
        }
    }, []);

    // =====================================================
    // REVIEW
    // =====================================================

    const reviewOne = useCallback(async (id, payload) => {
        if (!id) {
            throw new Error('id is required');
        }

        setSavingId(id);
        setError('');

        try {
            const reviewed =
                await BusinessClaimRequestsService.review(
                    id,
                    payload
                );

            setRows((previous) =>
                (previous || []).map((row) =>
                    Number(row.id) === Number(id)
                        ? {
                            ...row,
                            ...reviewed,
                        }
                        : row
                )
            );

            return reviewed;
        } catch (err) {
            setError(
                err?.message ||
                'No se pudo revisar la reclamación'
            );

            throw err;
        } finally {
            setSavingId(null);
        }
    }, []);

    // =====================================================
    // APPROVE
    // =====================================================

    const approveOne = useCallback(
        async (id, comment = '') => {
            const reviewed = await reviewOne(id, {
                status: 'approved',
                comment,
            });

            if (statusFilter === 'pending') {
                setRows((previous) =>
                    (previous || []).filter(
                        (row) => Number(row.id) !== Number(id)
                    )
                );
            }

            return reviewed;
        },
        [reviewOne, statusFilter]
    );

    // =====================================================
    // REJECT
    // =====================================================

    const rejectOne = useCallback(
        async (id, comment = '') => {
            const reviewed = await reviewOne(id, {
                status: 'rejected',
                comment,
            });

            if (statusFilter === 'pending') {
                setRows((previous) =>
                    (previous || []).filter(
                        (row) => Number(row.id) !== Number(id)
                    )
                );
            }

            return reviewed;
        },
        [reviewOne, statusFilter]
    );

    // =====================================================
    // FILTERED ROWS
    // =====================================================

    const filteredRows = useMemo(() => {
        const query = String(search || '')
            .trim()
            .toLowerCase();

        return (rows || []).filter((row) => {
            const status = String(
                row?.status || ''
            ).toLowerCase();

            const matchesStatus =
                statusFilter === 'all' ||
                status === statusFilter;

            if (!matchesStatus) return false;

            if (!query) return true;

            const haystack = [
                row?.id,
                row?.business_id,
                row?.user_id,
                row?.comment,
                row?.status,
                ...(Array.isArray(row?.documents)
                    ? row.documents
                    : []),
            ]
                .filter(
                    (value) =>
                        value !== undefined &&
                        value !== null
                )
                .join(' ')
                .toLowerCase();

            return haystack.includes(query);
        });
    }, [rows, search, statusFilter]);

    // =====================================================
    // AUTO LOAD
    // =====================================================

    useEffect(() => {
        if (!autoLoad) return;

        fetchByCurrentFilter();

        return abortPrevious;
    }, [
        autoLoad,
        fetchByCurrentFilter,
        abortPrevious,
    ]);

    return {
        rows,
        filteredRows,

        loading,
        savingId,
        error,

        search,
        setSearch,

        statusFilter,
        setStatusFilter,

        fetchPending,
        fetchAll,
        fetchByCurrentFilter,

        getById,
        reviewOne,
        approveOne,
        rejectOne,
    };
}