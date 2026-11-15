// File: src/hooks/useEvents.js

'use client';

import {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from 'react';

import { useUser } from '@/context/UserContext';
import EventService from '@/services/eventService';

function normalizeList(data) {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data?.data)) return data.data;
    if (Array.isArray(data?.items)) return data.items;
    if (Array.isArray(data?.events)) return data.events;

    return [];
}

function isAbortError(error) {
    return (
        error?.name === 'AbortError' ||
        error?.code === 'ABORT_ERR' ||
        error?.message === 'The operation was aborted.'
    );
}

function getErrorMessage(error, fallback) {
    if (error?.status === 401) {
        return 'Tu sesión no es válida o ha expirado.';
    }

    if (error?.status === 403) {
        return 'No tienes permisos para realizar esta acción.';
    }

    if (error?.status === 404) {
        return 'El evento solicitado no fue encontrado.';
    }

    return error?.message || fallback;
}

function logWarning(scope, error) {
    console.warn(`[useEvents] ${scope}:`, {
        message: error?.message || 'Error desconocido',
        status: error?.status ?? null,
        code: error?.code ?? null,
    });
}

export default function useEvents(options = {}) {
    const {
        autoLoad = true,
        businessId = null,
        categoryId = null,
        mine = false,
        adminMode = false,
    } = options;

    const { user: currentUser } = useUser();

    // =====================================================
    // ROLE
    // =====================================================

    const currentRole =
        currentUser?.role ||
        currentUser?.profile?.role ||
        null;

    const canManageEvents =
        currentRole === 'admin' ||
        currentRole === 'master';

    const canCreateEvents =
        currentRole === 'partner' ||
        currentRole === 'admin' ||
        currentRole === 'master';

    // =====================================================
    // STATE
    // =====================================================

    const [rows, setRows] = useState([]);
    const [current, setCurrent] = useState(null);

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [savingId, setSavingId] = useState(null);

    const [search, setSearch] = useState('');

    /*
     * En modo administrativo inicia en pending.
     * En modo público no usa filtro administrativo.
     */
    const [statusFilter, setStatusFilter] = useState(
        adminMode ? 'pending' : ''
    );

    const [categoryFilter, setCategoryFilter] = useState(
        categoryId ?? null
    );

    const reqRef = useRef(null);
    const mountedRef = useRef(true);

    // =====================================================
    // ABORT
    // =====================================================

    const abortActive = useCallback(() => {
        if (!reqRef.current) return;

        try {
            reqRef.current.abort();
        } catch {
            // Ignorar abortos ya ejecutados.
        }

        reqRef.current = null;
    }, []);

    // =====================================================
    // LOAD ALL
    // =====================================================

    const fetchAll = useCallback(async () => {
        /*
         * Si el hook está configurado como administrativo,
         * no debe ejecutar peticiones hasta tener un rol permitido.
         */
        if (adminMode && !currentRole) {
            setRows([]);
            setLoading(false);
            setError(null);

            return [];
        }

        if (adminMode && !canManageEvents) {
            setRows([]);
            setLoading(false);
            setError(null);

            return [];
        }

        abortActive();

        const controller = new AbortController();
        reqRef.current = controller;

        if (mountedRef.current) {
            setLoading(true);
            setError(null);
        }

        try {
            let data = [];

            if (mine) {
                /*
                 * /events/me para usuario autenticado que administra
                 * o consulta sus propios eventos.
                 */
                if (!currentRole) {
                    return [];
                }

                data = await EventService.getMine({
                    signal: controller.signal,
                });
            } else if (businessId) {
                data = await EventService.getByBusiness(
                    businessId,
                    {
                        signal: controller.signal,
                    }
                );
            } else if (categoryId) {
                data = await EventService.getByCategory(
                    categoryId,
                    {
                        signal: controller.signal,
                    }
                );
            } else if (
                adminMode &&
                canManageEvents &&
                [
                    'pending',
                    'active',
                    'finished',
                    'cancelled',
                ].includes(statusFilter)
            ) {
                /*
                 * getByStatus apunta al endpoint administrativo.
                 * Solo se ejecuta en adminMode para admin/master.
                 */
                data = await EventService.getByStatus(
                    statusFilter,
                    {
                        signal: controller.signal,
                    }
                );
            } else {
                /*
                 * Listado público.
                 */
                data = await EventService.list(
                    {},
                    {
                        signal: controller.signal,
                    }
                );
            }

            const list = normalizeList(data);

            if (mountedRef.current) {
                setRows(list);
            }

            return list;
        } catch (requestError) {
            if (
                isAbortError(requestError) ||
                controller.signal.aborted
            ) {
                return [];
            }

            logWarning('fetchAll', requestError);

            if (mountedRef.current) {
                setRows([]);
                setError(
                    getErrorMessage(
                        requestError,
                        'No se pudieron cargar los eventos.'
                    )
                );
            }

            return [];
        } finally {
            if (reqRef.current === controller) {
                reqRef.current = null;

                if (mountedRef.current) {
                    setLoading(false);
                }
            }
        }
    }, [
        abortActive,
        adminMode,
        businessId,
        canManageEvents,
        categoryId,
        currentRole,
        mine,
        statusFilter,
    ]);

    // =====================================================
    // FETCH ONE
    // =====================================================

    const fetchOne = useCallback(async (id) => {
        if (!id) {
            setError('El identificador es obligatorio.');
            return null;
        }

        setLoading(true);
        setError(null);

        try {
            const data = await EventService.get(id);

            setCurrent(data);

            return data;
        } catch (requestError) {
            logWarning('fetchOne', requestError);

            setError(
                getErrorMessage(
                    requestError,
                    'No se pudo cargar el evento.'
                )
            );

            return null;
        } finally {
            setLoading(false);
        }
    }, []);

    // =====================================================
    // CREATE
    // =====================================================

    const createOne = useCallback(
        async (payload) => {
            if (!canCreateEvents) {
                setError(
                    'No tienes permisos para crear eventos.'
                );

                return null;
            }

            setSavingId('create');
            setError(null);

            try {
                const created =
                    await EventService.create(payload);

                setRows((previous) => [
                    created,
                    ...previous,
                ]);

                return created;
            } catch (requestError) {
                logWarning('createOne', requestError);

                setError(
                    getErrorMessage(
                        requestError,
                        'No se pudo crear el evento.'
                    )
                );

                return null;
            } finally {
                setSavingId(null);
            }
        },
        [canCreateEvents]
    );

    // =====================================================
    // UPDATE
    // =====================================================

    const updateOne = useCallback(
        async (id, payload) => {
            if (!canManageEvents) {
                setError(
                    'No tienes permisos para actualizar eventos.'
                );

                return null;
            }

            if (!id) {
                setError('El identificador es obligatorio.');
                return null;
            }

            setSavingId(id);
            setError(null);

            try {
                const updated =
                    await EventService.update(id, payload);

                setRows((previous) =>
                    previous.map((row) =>
                        Number(row.id) === Number(id)
                            ? updated
                            : row
                    )
                );

                setCurrent((previous) =>
                    previous &&
                        Number(previous.id) === Number(id)
                        ? updated
                        : previous
                );

                return updated;
            } catch (requestError) {
                logWarning('updateOne', requestError);

                setError(
                    getErrorMessage(
                        requestError,
                        'No se pudo actualizar el evento.'
                    )
                );

                return null;
            } finally {
                setSavingId(null);
            }
        },
        [canManageEvents]
    );

    // =====================================================
    // REMOVE
    // =====================================================

    const removeOne = useCallback(
        async (id) => {
            if (!canManageEvents) {
                setError(
                    'No tienes permisos para eliminar eventos.'
                );

                return false;
            }

            if (!id) {
                setError('El identificador es obligatorio.');
                return false;
            }

            setSavingId(id);
            setError(null);

            try {
                await EventService.remove(id);

                setRows((previous) =>
                    previous.filter(
                        (row) =>
                            Number(row.id) !== Number(id)
                    )
                );

                setCurrent((previous) =>
                    previous &&
                        Number(previous.id) === Number(id)
                        ? null
                        : previous
                );

                return true;
            } catch (requestError) {
                logWarning('removeOne', requestError);

                setError(
                    getErrorMessage(
                        requestError,
                        'No se pudo eliminar el evento.'
                    )
                );

                return false;
            } finally {
                setSavingId(null);
            }
        },
        [canManageEvents]
    );

    // =====================================================
    // APPROVE
    // =====================================================

    const approveOne = useCallback(
        async (id) => {
            if (!canManageEvents) {
                setError(
                    'No tienes permisos para aprobar eventos.'
                );

                return null;
            }

            if (!id) return null;

            setSavingId(id);
            setError(null);

            try {
                const updated =
                    await EventService.approve(id);

                setRows((previous) =>
                    previous.map((row) =>
                        Number(row.id) === Number(id)
                            ? updated
                            : row
                    )
                );

                return updated;
            } catch (requestError) {
                logWarning('approveOne', requestError);

                setError(
                    getErrorMessage(
                        requestError,
                        'No se pudo aprobar el evento.'
                    )
                );

                return null;
            } finally {
                setSavingId(null);
            }
        },
        [canManageEvents]
    );

    // =====================================================
    // REJECT
    // =====================================================

    const rejectOne = useCallback(
        async (id) => {
            if (!canManageEvents) {
                setError(
                    'No tienes permisos para rechazar eventos.'
                );

                return null;
            }

            if (!id) return null;

            setSavingId(id);
            setError(null);

            try {
                const updated =
                    await EventService.reject(id);

                setRows((previous) =>
                    previous.map((row) =>
                        Number(row.id) === Number(id)
                            ? updated
                            : row
                    )
                );

                return updated;
            } catch (requestError) {
                logWarning('rejectOne', requestError);

                setError(
                    getErrorMessage(
                        requestError,
                        'No se pudo rechazar el evento.'
                    )
                );

                return null;
            } finally {
                setSavingId(null);
            }
        },
        [canManageEvents]
    );

    // =====================================================
    // AVAILABILITY
    // =====================================================

    const fetchAvailability = useCallback(async (id) => {
        if (!id) {
            return null;
        }

        try {
            return await EventService.getAvailability(id);
        } catch (requestError) {
            logWarning(
                'fetchAvailability',
                requestError
            );

            setError(
                getErrorMessage(
                    requestError,
                    'No se pudo consultar la disponibilidad.'
                )
            );

            return null;
        }
    }, []);

    // =====================================================
    // FILTERED ROWS
    // =====================================================

    const filteredRows = useMemo(() => {
        let data = [...rows];

        if (search.trim()) {
            const query = search
                .trim()
                .toLowerCase();

            data = data.filter((event) => {
                const name =
                    event?.name?.toLowerCase() || '';

                const description =
                    event?.description?.toLowerCase() || '';

                const address =
                    event?.address?.toLowerCase() || '';

                return (
                    name.includes(query) ||
                    description.includes(query) ||
                    address.includes(query)
                );
            });
        }

        if (categoryFilter) {
            data = data.filter(
                (event) =>
                    Number(event?.category_id) ===
                    Number(categoryFilter)
            );
        }

        data.sort((a, b) => {
            const dateA =
                a?.created_at ||
                a?.start_date ||
                '';

            const dateB =
                b?.created_at ||
                b?.start_date ||
                '';

            if (
                dateA &&
                dateB &&
                dateA !== dateB
            ) {
                return (
                    new Date(dateB).getTime() -
                    new Date(dateA).getTime()
                );
            }

            return (
                Number(b?.id || 0) -
                Number(a?.id || 0)
            );
        });

        return data;
    }, [rows, search, categoryFilter]);

    // =====================================================
    // AUTO LOAD
    // =====================================================

    useEffect(() => {
        mountedRef.current = true;

        if (!autoLoad) {
            return () => {
                mountedRef.current = false;
                abortActive();
            };
        }

        /*
         * En modo admin, esperamos el rol y validamos permisos.
         */
        if (adminMode) {
            if (!currentRole || !canManageEvents) {
                return () => {
                    mountedRef.current = false;
                    abortActive();
                };
            }
        }

        fetchAll();

        return () => {
            mountedRef.current = false;
            abortActive();
        };
    }, [
        autoLoad,
        adminMode,
        currentRole,
        canManageEvents,
        fetchAll,
        abortActive,
    ]);

    // =====================================================
    // RETURN
    // =====================================================

    return {
        rows,
        filteredRows,
        current,

        loading,
        error,
        savingId,

        currentRole,
        canManageEvents,
        canCreateEvents,

        search,
        setSearch,

        statusFilter,
        setStatusFilter,

        categoryFilter,
        setCategoryFilter,

        fetchAll,
        fetchOne,

        createOne,
        updateOne,
        removeOne,

        approveOne,
        rejectOne,

        fetchAvailability,

        clearError: () => setError(null),
    };
}