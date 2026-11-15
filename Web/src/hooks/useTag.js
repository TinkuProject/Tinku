// File: src/hooks/useTag.js
'use client';

import {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from 'react';

import { TagService } from '@/services/tagService';

export default function useTag({
    autoLoad = false,
    filters: initialFilters = {},
} = {}) {
    const [tags, setTags] = useState([]);
    const [current, setCurrent] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [filters, setFilters] = useState(initialFilters);

    const abortRef = useRef(null);
    const mountedRef = useRef(false);

    /**
     * =========================
     * ABORT ACTIVE REQUEST
     * =========================
     */
    const abortActive = useCallback(() => {
        if (!abortRef.current) return;

        /*
         * No enviamos un motivo personalizado.
         * De esta forma fetch genera AbortError de manera estándar.
         */
        abortRef.current.abort();
        abortRef.current = null;
    }, []);

    /**
     * =========================
     * ABORT ERROR CHECK
     * =========================
     */
    const isAbortError = useCallback((err) => {
        return (
            err?.name === 'AbortError' ||
            err?.code === 20 ||
            err === 'cancelled-by-hook' ||
            err?.message === 'cancelled-by-hook' ||
            err?.message === 'The operation was aborted.' ||
            err?.message?.toLowerCase?.().includes('aborted')
        );
    }, []);

    const sameId = useCallback(
        (item, id) =>
            String(item?.id ?? item?._id) === String(id),
        []
    );

    /**
     * =========================
     * REQUEST WRAPPER
     * =========================
     */
    const wrap = useCallback(
        async (fn) => {
            abortActive();

            const controller = new AbortController();
            abortRef.current = controller;

            if (mountedRef.current) {
                setLoading(true);
                setError(null);
            }

            try {
                const result = await fn(controller.signal);

                /*
                 * La petición pudo finalizar después de haber sido
                 * sustituida por otra.
                 */
                if (
                    controller.signal.aborted ||
                    abortRef.current !== controller
                ) {
                    return undefined;
                }

                return result;
            } catch (err) {
                /*
                 * Una cancelación es parte normal del ciclo del hook.
                 * No se relanza y no se guarda como error.
                 */
                if (
                    controller.signal.aborted ||
                    isAbortError(err)
                ) {
                    return undefined;
                }

                if (mountedRef.current) {
                    setError(err);
                }

                throw err;
            } finally {
                /*
                 * Una petición anterior no debe quitar el loading
                 * de una petición más reciente.
                 */
                if (abortRef.current === controller) {
                    abortRef.current = null;

                    if (mountedRef.current) {
                        setLoading(false);
                    }
                }
            }
        },
        [abortActive, isAbortError]
    );

    /**
     * =========================
     * FETCH ALL
     * =========================
     */
    const fetchAll = useCallback(
        async (nextFilters) => {
            const appliedFilters = {
                ...filters,
                ...(nextFilters || {}),
            };

            const data = await wrap((signal) =>
                TagService.list(appliedFilters, {
                    signal,
                })
            );

            /*
             * Petición cancelada.
             */
            if (data === undefined) {
                return undefined;
            }

            const list = Array.isArray(data)
                ? data
                : data?.items ?? data?.data ?? [];

            if (mountedRef.current) {
                setTags(list);
            }

            return list;
        },
        [filters, wrap]
    );

    /**
     * =========================
     * FETCH ONE
     * =========================
     */
    const fetchOne = useCallback(
        async (id) => {
            if (!id) {
                return null;
            }

            const data = await wrap((signal) =>
                TagService.get(id, {
                    signal,
                })
            );

            if (data === undefined) {
                return undefined;
            }

            if (mountedRef.current) {
                setCurrent(data);
            }

            return data;
        },
        [wrap]
    );

    /**
     * =========================
     * CREATE
     * =========================
     */
    const createOne = useCallback(
        async (payload) => {
            const cleanPayload = {
                name: String(payload?.name || '').trim(),

                description:
                    String(
                        payload?.description || ''
                    ).trim() === ''
                        ? null
                        : String(
                            payload.description
                        ).trim(),

                status: payload?.status || 'active',
            };

            const created = await wrap((signal) =>
                TagService.create(cleanPayload, {
                    signal,
                })
            );

            if (created === undefined) {
                return undefined;
            }

            if (mountedRef.current) {
                setTags((previous) => [
                    created,
                    ...(previous || []),
                ]);
            }

            return created;
        },
        [wrap]
    );

    /**
     * =========================
     * UPDATE
     * =========================
     */
    const updateOne = useCallback(
        async (id, payload) => {
            if (!id) {
                return null;
            }

            const cleanPayload = {};

            if (payload?.name !== undefined) {
                cleanPayload.name = String(
                    payload.name || ''
                ).trim();
            }

            if (payload?.description !== undefined) {
                const description = String(
                    payload.description || ''
                ).trim();

                cleanPayload.description =
                    description === ''
                        ? null
                        : description;
            }

            if (payload?.status !== undefined) {
                cleanPayload.status = payload.status;
            }

            const updated = await wrap((signal) =>
                TagService.update(
                    id,
                    cleanPayload,
                    {
                        signal,
                    }
                )
            );

            if (updated === undefined) {
                return undefined;
            }

            if (mountedRef.current) {
                setTags((previous) =>
                    previous.map((tag) =>
                        sameId(tag, id)
                            ? updated
                            : tag
                    )
                );

                setCurrent((previous) =>
                    previous &&
                        sameId(previous, id)
                        ? updated
                        : previous
                );
            }

            return updated;
        },
        [sameId, wrap]
    );

    /**
     * =========================
     * SOFT DELETE
     * =========================
     */
    const softDeleteOne = useCallback(
        async (id) => {
            if (!id) {
                return null;
            }

            const updated = await wrap((signal) =>
                TagService.softDelete(id, {
                    signal,
                })
            );

            if (updated === undefined) {
                return undefined;
            }

            if (mountedRef.current) {
                setTags((previous) =>
                    previous.map((tag) =>
                        sameId(tag, id)
                            ? updated
                            : tag
                    )
                );

                setCurrent((previous) =>
                    previous &&
                        sameId(previous, id)
                        ? updated
                        : previous
                );
            }

            return updated;
        },
        [sameId, wrap]
    );

    /**
     * =========================
     * MOUNT / UNMOUNT
     * =========================
     */
    useEffect(() => {
        mountedRef.current = true;

        if (autoLoad) {
            /*
             * La cancelación ya se controla dentro del hook.
             * Los errores reales se capturan para evitar
             * Uncaught (in promise) desde el useEffect.
             */
            fetchAll().catch((err) => {
                if (!isAbortError(err)) {
                    console.warn(
                        '[useTag] No se pudieron cargar los tags:',
                        err?.message ||
                        'Error desconocido'
                    );
                }
            });
        }

        return () => {
            mountedRef.current = false;
            abortActive();
        };
    }, [
        autoLoad,
        abortActive,
        fetchAll,
        isAbortError,
    ]);

    return useMemo(
        () => ({
            tags,
            items: tags,
            current,
            loading,
            error,
            filters,

            fetchAll,
            fetchOne,
            createOne,
            updateOne,
            softDeleteOne,

            // Alias para componentes antiguos
            deleteOne: softDeleteOne,

            setFilters,
            clearError: () => setError(null),
        }),
        [
            tags,
            current,
            loading,
            error,
            filters,
            fetchAll,
            fetchOne,
            createOne,
            updateOne,
            softDeleteOne,
        ]
    );
}