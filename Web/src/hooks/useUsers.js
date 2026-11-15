// File: src/hooks/useUsers.js

'use client';

import {
    useCallback,
    useEffect,
    useMemo,
    useState,
} from 'react';

import toast from 'react-hot-toast';

import { useUser } from '@/context/UserContext';

import {
    listUsers,
    updateUser,
    deleteUser,
    activatePartner,
} from '@/services/usersService';

export const PAGE_SIZE = 9;

const ROLE_VALUES = new Set([
    'user',
    'partner',
    'admin',
    'master',
]);

function sortUsersNewestFirst(rows) {
    const getCreated = (user) => {
        const raw =
            user?.created_at ??
            user?.createdAt ??
            user?.created ??
            null;

        if (!raw) return null;

        const time = new Date(raw).getTime();

        return Number.isNaN(time) ? null : time;
    };

    return [...rows].sort((a, b) => {
        const timeA = getCreated(a);
        const timeB = getCreated(b);

        if (
            timeB !== null &&
            timeA !== null &&
            timeB !== timeA
        ) {
            return timeB - timeA;
        }

        return String(b?.id || '').localeCompare(
            String(a?.id || '')
        );
    });
}

function isActiveStatus(status) {
    return (
        status === 'active' ||
        status === 1 ||
        status === true
    );
}

function getErrorMessage(error, fallback) {
    if (error?.status === 401) {
        return 'Tu sesión no es válida o ha expirado.';
    }

    if (error?.status === 403) {
        return 'No tienes permisos para administrar usuarios.';
    }

    if (error?.status === 404) {
        return 'El usuario solicitado no fue encontrado.';
    }

    return error?.message || fallback;
}

function logWarning(scope, error) {
    console.warn(`[useUsers] ${scope}:`, {
        message: error?.message || 'Error desconocido',
        status: error?.status || null,
        code: error?.code || null,
    });
}

export default function useUsers({
    autoLoad = true,
} = {}) {
    const { user: currentUser } = useUser();

    // =====================================================
    // ROLE
    // =====================================================

    const currentRole =
        currentUser?.role ||
        currentUser?.profile?.role ||
        null;

    const canManageUsers = currentRole === 'master';

    // =====================================================
    // STATE
    // =====================================================

    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(false);
    const [err, setErr] = useState('');
    const [rowSavingId, setRowSavingId] =
        useState(null);

    const [searchText, setSearchText] = useState('');
    const [roleFilter, setRoleFilter] =
        useState('all');
    const [statusFilter, setStatusFilter] =
        useState('all');

    const [currentPage, setCurrentPage] =
        useState(1);

    // =====================================================
    // LOAD USERS
    // =====================================================

    const fetchUsers = useCallback(
        async ({ notify = false } = {}) => {
            /*
             * Mientras todavía no se recuperó el usuario,
             * no hacemos ninguna petición.
             */
            if (!currentRole) {
                setUsers([]);
                setLoading(false);
                setErr('');
                return [];
            }

            /*
             * Solo master puede acceder a GET /users.
             */
            if (!canManageUsers) {
                setUsers([]);
                setLoading(false);
                setErr('');
                return [];
            }

            setLoading(true);
            setErr('');

            try {
                const data = await listUsers();

                const rows = Array.isArray(data)
                    ? data
                    : Array.isArray(data?.data)
                        ? data.data
                        : Array.isArray(data?.users)
                            ? data.users
                            : [];

                const sortedRows =
                    sortUsersNewestFirst(rows);

                setUsers(sortedRows);
                setCurrentPage(1);

                if (notify) {
                    toast.success(
                        'Lista de usuarios actualizada'
                    );
                }

                return sortedRows;
            } catch (error) {
                logWarning('fetchUsers', error);

                const message = getErrorMessage(
                    error,
                    'Error cargando usuarios.'
                );

                setErr(message);
                setUsers([]);

                /*
                 * No mostramos toast al cargar automáticamente,
                 * para evitar alertas innecesarias al entrar al panel.
                 */
                if (notify) {
                    toast.error(message);
                }

                return [];
            } finally {
                setLoading(false);
            }
        },
        [currentRole, canManageUsers]
    );

    useEffect(() => {
        if (!autoLoad) return;
        if (!currentRole) return;
        if (!canManageUsers) return;

        fetchUsers();
    }, [
        autoLoad,
        currentRole,
        canManageUsers,
        fetchUsers,
    ]);

    // =====================================================
    // FILTERS
    // =====================================================

    const filteredUsers = useMemo(() => {
        const term = searchText
            .trim()
            .toLowerCase();

        return users.filter((user) => {
            const matchesText =
                term.length === 0 ||
                [
                    user?.first_name,
                    user?.last_name,
                    user?.email,
                    user?.phone,
                    user?.username,
                    user?.ci,
                    user?.address,
                ]
                    .map((value) =>
                        String(value || '').toLowerCase()
                    )
                    .some((value) =>
                        value.includes(term)
                    );

            const userRole =
                user?.role ||
                user?.user_type ||
                '';

            const matchesRole =
                roleFilter === 'all'
                    ? true
                    : ROLE_VALUES.has(roleFilter) &&
                    userRole === roleFilter;

            const active = isActiveStatus(
                user?.status
            );

            const matchesStatus =
                statusFilter === 'all'
                    ? true
                    : statusFilter === 'active'
                        ? active
                        : !active;

            return (
                matchesText &&
                matchesRole &&
                matchesStatus
            );
        });
    }, [
        users,
        searchText,
        roleFilter,
        statusFilter,
    ]);

    useEffect(() => {
        setCurrentPage(1);
    }, [
        searchText,
        roleFilter,
        statusFilter,
    ]);

    // =====================================================
    // PAGINATION
    // =====================================================

    const totalPages = useMemo(
        () =>
            Math.max(
                1,
                Math.ceil(
                    filteredUsers.length / PAGE_SIZE
                )
            ),
        [filteredUsers.length]
    );

    const pageRows = useMemo(() => {
        const start =
            (currentPage - 1) * PAGE_SIZE;

        return filteredUsers.slice(
            start,
            start + PAGE_SIZE
        );
    }, [filteredUsers, currentPage]);

    const goToPage = useCallback(
        (page) => {
            setCurrentPage(
                Math.min(
                    Math.max(1, page),
                    totalPages
                )
            );
        },
        [totalPages]
    );

    const prevPage = useCallback(() => {
        goToPage(currentPage - 1);
    }, [currentPage, goToPage]);

    const nextPage = useCallback(() => {
        goToPage(currentPage + 1);
    }, [currentPage, goToPage]);

    // =====================================================
    // TOGGLE ACTIVE
    // =====================================================

    const handleToggleActiveById =
        useCallback(
            async (user) => {
                if (!canManageUsers) {
                    toast.error(
                        'No tienes permisos para modificar usuarios.'
                    );
                    return false;
                }

                if (!user?.id) return false;

                const currentlyActive =
                    isActiveStatus(user.status);

                const nextStatus =
                    currentlyActive
                        ? 'inactive'
                        : 'active';

                setRowSavingId(user.id);

                try {
                    const saved = await updateUser(
                        user.id,
                        {
                            status: nextStatus,
                        }
                    );

                    setUsers((previous) =>
                        previous.map((item) =>
                            String(item.id) ===
                                String(user.id)
                                ? {
                                    ...item,
                                    status:
                                        saved?.status ??
                                        nextStatus,
                                }
                                : item
                        )
                    );

                    toast.success(
                        nextStatus === 'active'
                            ? `Usuario "${user.first_name ||
                            user.email
                            }" activado`
                            : `Usuario "${user.first_name ||
                            user.email
                            }" desactivado`
                    );

                    return true;
                } catch (error) {
                    logWarning(
                        'handleToggleActiveById',
                        error
                    );

                    toast.error(
                        getErrorMessage(
                            error,
                            'No se pudo actualizar el estado.'
                        )
                    );

                    return false;
                } finally {
                    setRowSavingId(null);
                }
            },
            [canManageUsers]
        );

    // =====================================================
    // DELETE USER
    // =====================================================

    const handleDeleteById = useCallback(
        async (user) => {
            if (!canManageUsers) {
                toast.error(
                    'No tienes permisos para eliminar usuarios.'
                );
                return false;
            }

            if (!user?.id) return false;

            const name =
                [
                    user?.first_name,
                    user?.last_name,
                ]
                    .filter(Boolean)
                    .join(' ')
                    .trim() ||
                user?.email ||
                'Usuario';

            const confirmed = window.confirm(
                `¿Seguro que deseas eliminar al usuario "${name}"?`
            );

            if (!confirmed) return false;

            setRowSavingId(user.id);

            try {
                await deleteUser(user.id);

                setUsers((previous) => {
                    const next = previous.filter(
                        (item) =>
                            String(item.id) !==
                            String(user.id)
                    );

                    const newTotalPages = Math.max(
                        1,
                        Math.ceil(
                            next.length / PAGE_SIZE
                        )
                    );

                    setCurrentPage((page) =>
                        Math.min(
                            page,
                            newTotalPages
                        )
                    );

                    return next;
                });

                toast.success(
                    `Usuario "${name}" eliminado`
                );

                return true;
            } catch (error) {
                logWarning(
                    'handleDeleteById',
                    error
                );

                toast.error(
                    getErrorMessage(
                        error,
                        'Error al eliminar usuario.'
                    )
                );

                return false;
            } finally {
                setRowSavingId(null);
            }
        },
        [canManageUsers]
    );

    // =====================================================
    // ACTIVATE PARTNER
    // =====================================================

    const handleActivatePartnerById =
        useCallback(
            async (user) => {
                if (!canManageUsers) {
                    toast.error(
                        'No tienes permisos para activar socios.'
                    );
                    return false;
                }

                if (!user?.id) return false;

                setRowSavingId(user.id);

                try {
                    const saved =
                        await activatePartner(user.id);

                    setUsers((previous) =>
                        previous.map((item) =>
                            String(item.id) ===
                                String(user.id)
                                ? {
                                    ...item,
                                    role:
                                        saved?.role ??
                                        'partner',
                                }
                                : item
                        )
                    );

                    toast.success(
                        'Usuario activado como socio'
                    );

                    return true;
                } catch (error) {
                    logWarning(
                        'handleActivatePartnerById',
                        error
                    );

                    toast.error(
                        getErrorMessage(
                            error,
                            'No se pudo activar como socio.'
                        )
                    );

                    return false;
                } finally {
                    setRowSavingId(null);
                }
            },
            [canManageUsers]
        );

    // =====================================================
    // RETURN
    // =====================================================

    return {
        users,
        filteredUsers,
        pageRows,

        loading,
        err,
        rowSavingId,

        currentRole,
        canManageUsers,

        searchText,
        setSearchText,

        roleFilter,
        setRoleFilter,

        statusFilter,
        setStatusFilter,

        PAGE_SIZE,
        currentPage,
        totalPages,

        goToPage,
        prevPage,
        nextPage,

        fetchUsers,
        handleToggleActiveById,
        handleDeleteById,
        handleActivatePartnerById,
    };
}