// src/hooks/useChargingPoints.js
'use client';

import {
    useCallback,
    useEffect,
    useRef,
    useState,
} from 'react';

import {
    ChargingPointsService,
} from '@/services/chargingPointsService';

export default function useChargingPoints({
    autoLoad = false,
} = {}) {
    const [rows, setRows] =
        useState([]);

    const [loading, setLoading] =
        useState(false);

    const [savingId, setSavingId] =
        useState(null);

    const [error, setError] =
        useState('');

    const abortRef = useRef(null);

    const abortPrev = () => {
        if (abortRef.current) {
            abortRef.current.abort();
        }

        abortRef.current = null;
    };

    /* =========================
       LOAD ALL
    ========================= */

    const fetchAll = useCallback(
        async () => {
            abortPrev();

            setLoading(true);
            setError('');

            const controller =
                new AbortController();

            abortRef.current =
                controller;

            try {
                const data =
                    await ChargingPointsService.list(
                        controller.signal
                    );

                setRows(
                    Array.isArray(data)
                        ? data
                        : []
                );
            } catch (e) {
                if (
                    e?.name !==
                    'AbortError'
                ) {
                    setError(
                        e?.message ||
                        'No se pudo cargar los puntos de carga'
                    );
                }
            } finally {
                setLoading(false);
            }
        },
        []
    );

    /* =========================
       LOAD ACTIVE
    ========================= */

    const fetchActive =
        useCallback(async () => {
            abortPrev();

            setLoading(true);
            setError('');

            const controller =
                new AbortController();

            abortRef.current =
                controller;

            try {
                const data =
                    await ChargingPointsService.listActive(
                        controller.signal
                    );

                setRows(
                    Array.isArray(data)
                        ? data
                        : []
                );
            } catch (e) {
                if (
                    e?.name !==
                    'AbortError'
                ) {
                    setError(
                        e?.message ||
                        'No se pudo cargar los puntos activos'
                    );
                }
            } finally {
                setLoading(false);
            }
        }, []);

    /* =========================
       CREATE
    ========================= */

    const createOne =
        useCallback(
            async (payload) => {
                setSavingId('new');
                setError('');

                try {
                    const created =
                        await ChargingPointsService.create(
                            payload
                        );

                    setRows((prev) => [
                        created,
                        ...(prev || []),
                    ]);

                    return created;
                } catch (e) {
                    setError(
                        e?.message ||
                        'No se pudo crear el punto de carga'
                    );

                    throw e;
                } finally {
                    setSavingId(null);
                }
            },
            []
        );

    /* =========================
       UPDATE
    ========================= */

    const updateOne =
        useCallback(
            async (
                id,
                payload
            ) => {
                if (!id) {
                    throw new Error(
                        'id is required'
                    );
                }

                setSavingId(id);
                setError('');

                try {
                    const updated =
                        await ChargingPointsService.update(
                            id,
                            payload
                        );

                    setRows((prev) =>
                        (prev || []).map(
                            (r) =>
                                Number(r.id) ===
                                    Number(id)
                                    ? {
                                        ...r,
                                        ...updated,
                                    }
                                    : r
                        )
                    );

                    return updated;
                } catch (e) {
                    setError(
                        e?.message ||
                        'No se pudo actualizar el punto de carga'
                    );

                    throw e;
                } finally {
                    setSavingId(null);
                }
            },
            []
        );

    /* =========================
       SOFT DELETE
    ========================= */

    const removeOne =
        useCallback(
            async (id) => {
                if (!id) {
                    throw new Error(
                        'id is required'
                    );
                }

                setSavingId(id);
                setError('');

                try {
                    const updated =
                        await ChargingPointsService.softDelete(
                            id
                        );

                    setRows((prev) =>
                        (prev || []).map(
                            (r) =>
                                Number(r.id) ===
                                    Number(id)
                                    ? {
                                        ...r,
                                        ...updated,
                                    }
                                    : r
                        )
                    );

                    return updated;
                } catch (e) {
                    setError(
                        e?.message ||
                        'No se pudo eliminar el punto de carga'
                    );

                    throw e;
                } finally {
                    setSavingId(null);
                }
            },
            []
        );

    /* =========================
       ACTIVATE
    ========================= */

    const activateOne =
        useCallback(
            async (id) => {
                if (!id) {
                    throw new Error(
                        'id is required'
                    );
                }

                setSavingId(id);
                setError('');

                try {
                    const updated =
                        await ChargingPointsService.activate(
                            id
                        );

                    setRows((prev) =>
                        (prev || []).map(
                            (r) =>
                                Number(r.id) ===
                                    Number(id)
                                    ? {
                                        ...r,
                                        ...updated,
                                    }
                                    : r
                        )
                    );

                    return updated;
                } catch (e) {
                    setError(
                        e?.message ||
                        'No se pudo activar el punto de carga'
                    );

                    throw e;
                } finally {
                    setSavingId(null);
                }
            },
            []
        );

    /* =========================
       MAINTENANCE
    ========================= */

    const maintenanceOne =
        useCallback(
            async (id) => {
                if (!id) {
                    throw new Error(
                        'id is required'
                    );
                }

                setSavingId(id);
                setError('');

                try {
                    const updated =
                        await ChargingPointsService.maintenance(
                            id
                        );

                    setRows((prev) =>
                        (prev || []).map(
                            (r) =>
                                Number(r.id) ===
                                    Number(id)
                                    ? {
                                        ...r,
                                        ...updated,
                                    }
                                    : r
                        )
                    );

                    return updated;
                } catch (e) {
                    setError(
                        e?.message ||
                        'No se pudo poner en mantenimiento'
                    );

                    throw e;
                } finally {
                    setSavingId(null);
                }
            },
            []
        );

    /* =========================
       AUTO LOAD
    ========================= */

    useEffect(() => {
        if (autoLoad) {
            fetchAll();
        }

        return () => {
            abortPrev();
        };
    }, [autoLoad, fetchAll]);

    return {
        rows,

        loading,

        savingId,

        error,

        fetchAll,

        fetchActive,

        createOne,

        updateOne,

        removeOne,

        activateOne,

        maintenanceOne,
    };
}