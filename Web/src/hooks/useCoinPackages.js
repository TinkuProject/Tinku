// File: src/hooks/useCoinPackages.js

'use client';

import { useCallback, useEffect, useState } from 'react';

import { useUser } from '@/context/UserContext';

import {
    getCoinPackagesAdmin,
    createCoinPackage,
    updateCoinPackage,
    archiveCoinPackage,
    activateCoinPackage,
    deactivateCoinPackage,
    getCoinPackageById,
} from '@/services/coinPackagesService';

import mediaService from '@/services/mediaService';

// Cambia esto si en tu tabla media utilizas otro entity_type.
const MEDIA_ENTITY_TYPE = 'coin_package';

function validateRequired({
    name,
    tinkus_amount,
    cash_amount,
}) {
    if (!name?.trim()) {
        return 'El nombre es requerido';
    }

    if (
        tinkus_amount === '' ||
        tinkus_amount === null ||
        tinkus_amount === undefined
    ) {
        return 'La cantidad de Tinkus es requerida';
    }

    if (
        Number.isNaN(Number(tinkus_amount)) ||
        Number(tinkus_amount) <= 0
    ) {
        return 'La cantidad de Tinkus debe ser mayor a 0';
    }

    if (
        cash_amount === '' ||
        cash_amount === null ||
        cash_amount === undefined
    ) {
        return 'El monto en Bs es requerido';
    }

    if (
        Number.isNaN(Number(cash_amount)) ||
        Number(cash_amount) <= 0
    ) {
        return 'El monto en Bs debe ser mayor a 0';
    }

    return '';
}

function normalizeList(data) {
    if (Array.isArray(data)) {
        return data;
    }

    if (Array.isArray(data?.data)) {
        return data.data;
    }

    if (Array.isArray(data?.items)) {
        return data.items;
    }

    if (Array.isArray(data?.packages)) {
        return data.packages;
    }

    return [];
}

function getErrorMessage(
    error,
    fallback = 'Ocurrió un error inesperado'
) {
    if (error?.status === 401) {
        return 'Tu sesión no es válida o ha expirado.';
    }

    if (error?.status === 403) {
        return 'No tienes permisos para administrar paquetes de Tinkus.';
    }

    if (error?.status === 404) {
        return 'El paquete solicitado no fue encontrado.';
    }

    return error?.message || fallback;
}

function logWarning(scope, error) {
    console.warn(`[useCoinPackages] ${scope}:`, {
        message:
            error?.message ||
            String(error || 'Error desconocido'),
        status: error?.status ?? null,
        code: error?.code ?? null,
    });
}

export default function useCoinPackages({
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

    const canManagePackages =
        currentRole === 'master';

    // =====================================================
    // STATE
    // =====================================================

    const [formData, setFormData] = useState({
        name: '',
        tinkus_amount: '',
        cash_amount: '',
        status: 'active',
    });

    const [coinPackages, setCoinPackages] =
        useState([]);

    const [loadingList, setLoadingList] =
        useState(false);

    const [editIndex, setEditIndex] =
        useState(null);

    const [isSubmitting, setIsSubmitting] =
        useState(false);

    const [rowUpdatingId, setRowUpdatingId] =
        useState(null);

    const [errorMsg, setErrorMsg] =
        useState('');

    const [message, setMessage] =
        useState('');

    const [showMessage, setShowMessage] =
        useState(false);

    // =====================================================
    // HELPERS
    // =====================================================

    const toast = useCallback((msg) => {
        setMessage(msg);
        setShowMessage(true);
    }, []);

    const resetForm = useCallback(() => {
        setFormData({
            name: '',
            tinkus_amount: '',
            cash_amount: '',
            status: 'active',
        });

        setEditIndex(null);
        setErrorMsg('');
    }, []);

    // =====================================================
    // LOAD
    // =====================================================

    const loadPackages = useCallback(
        async ({ notify = false } = {}) => {
            /*
             * Mientras el contexto todavía no recuperó el usuario,
             * no realizamos ninguna petición.
             */
            if (!currentRole) {
                setCoinPackages([]);
                setLoadingList(false);
                setErrorMsg('');

                return [];
            }

            /*
             * El endpoint /payment-packages/admin solamente debe
             * ejecutarse para el rol master.
             */
            if (!canManagePackages) {
                setCoinPackages([]);
                setLoadingList(false);
                setErrorMsg('');

                return [];
            }

            setLoadingList(true);
            setErrorMsg('');

            try {
                const data =
                    await getCoinPackagesAdmin();

                const basePackages =
                    normalizeList(data);

                let mediaMap = {};

                try {
                    const ids = [
                        ...new Set(
                            basePackages
                                .map((pkg) => Number(pkg?.id))
                                .filter((id) =>
                                    Number.isFinite(id)
                                )
                        ),
                    ];

                    if (ids.length > 0) {
                        mediaMap =
                            await mediaService.getByEntities(
                                MEDIA_ENTITY_TYPE,
                                ids
                            );
                    }
                } catch (mediaError) {
                    logWarning(
                        'media load',
                        mediaError
                    );

                    mediaMap = {};
                }

                const packagesWithMedia =
                    basePackages.map((pkg) => {
                        const rawMedia =
                            mediaMap?.[pkg.id] ||
                            mediaMap?.[String(pkg.id)] ||
                            [];

                        const media = Array.isArray(
                            rawMedia
                        )
                            ? rawMedia
                            : [];

                        const sortedMedia = [
                            ...media,
                        ].sort((a, b) => {
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

                            if (dateA !== dateB) {
                                return dateB - dateA;
                            }

                            return (
                                Number(b?.id || 0) -
                                Number(a?.id || 0)
                            );
                        });

                        const newest =
                            sortedMedia[0];

                        const imageUrl =
                            newest?.url ||
                            newest?.image_url ||
                            newest?.media_url ||
                            newest?.path ||
                            newest?.fileUrl ||
                            '';

                        return {
                            ...pkg,
                            media: sortedMedia,
                            image_url: imageUrl,
                        };
                    });

                setCoinPackages(
                    packagesWithMedia
                );

                if (notify) {
                    toast(
                        'Lista de paquetes actualizada'
                    );
                }

                return packagesWithMedia;
            } catch (error) {
                logWarning('load', error);

                setCoinPackages([]);

                const errorMessage =
                    getErrorMessage(
                        error,
                        'No se pudieron cargar los paquetes.'
                    );

                setErrorMsg(errorMessage);

                if (notify) {
                    toast(errorMessage);
                }

                return [];
            } finally {
                setLoadingList(false);
            }
        },
        [
            currentRole,
            canManagePackages,
            toast,
        ]
    );

    useEffect(() => {
        if (!autoLoad) return;
        if (!currentRole) return;
        if (!canManagePackages) return;

        loadPackages();
    }, [
        autoLoad,
        currentRole,
        canManagePackages,
        loadPackages,
    ]);

    // =====================================================
    // CHANGE
    // =====================================================

    const handleChange = useCallback(
        (event) => {
            const { name, value } =
                event.target;

            setErrorMsg('');

            if (
                [
                    'tinkus_amount',
                    'cash_amount',
                ].includes(name)
            ) {
                setFormData((previous) => ({
                    ...previous,
                    [name]:
                        value === ''
                            ? ''
                            : Number(value),
                }));

                return;
            }

            setFormData((previous) => ({
                ...previous,
                [name]: value,
            }));
        },
        []
    );

    // =====================================================
    // SUBMIT
    // =====================================================

    const handleSubmit = useCallback(
        async (event, afterSubmit) => {
            event?.preventDefault?.();

            if (isSubmitting) {
                return false;
            }

            if (!canManagePackages) {
                setErrorMsg(
                    'No tienes permisos para administrar paquetes de Tinkus.'
                );

                return false;
            }

            setErrorMsg('');

            const validationError =
                validateRequired({
                    name: formData.name,
                    tinkus_amount:
                        formData.tinkus_amount,
                    cash_amount:
                        formData.cash_amount,
                });

            if (validationError) {
                setErrorMsg(validationError);
                return false;
            }

            setIsSubmitting(true);

            try {
                const payload = {
                    name: formData.name.trim(),
                    tinkus_amount: Number(
                        formData.tinkus_amount
                    ),
                    cash_amount: Number(
                        formData.cash_amount
                    ),
                    status:
                        formData.status || 'active',
                };

                let response = null;

                if (editIndex !== null) {
                    const id =
                        coinPackages[editIndex]?.id;

                    if (!id) {
                        throw new Error(
                            'ID inválido para editar el paquete.'
                        );
                    }

                    response =
                        await updateCoinPackage(
                            id,
                            payload
                        );

                    setCoinPackages(
                        (previous) => {
                            const copy = [...previous];

                            copy[editIndex] = {
                                ...copy[editIndex],
                                ...response,
                                media:
                                    copy[editIndex]?.media ||
                                    [],
                                image_url:
                                    response?.image_url ||
                                    copy[editIndex]
                                        ?.image_url ||
                                    '',
                            };

                            return copy;
                        }
                    );

                    toast('Paquete actualizado');
                } else {
                    response =
                        await createCoinPackage(
                            payload
                        );

                    setCoinPackages(
                        (previous) => [
                            {
                                ...response,
                                media: [],
                                image_url: '',
                            },
                            ...previous,
                        ]
                    );

                    toast('Paquete creado');
                }

                if (
                    typeof afterSubmit ===
                    'function'
                ) {
                    await afterSubmit(response);
                }

                resetForm();

                return true;
            } catch (error) {
                logWarning('submit', error);

                setErrorMsg(
                    getErrorMessage(
                        error,
                        'Error al guardar el paquete.'
                    )
                );

                return false;
            } finally {
                setIsSubmitting(false);
            }
        },
        [
            canManagePackages,
            isSubmitting,
            formData,
            editIndex,
            coinPackages,
            resetForm,
            toast,
        ]
    );

    // =====================================================
    // EDIT
    // =====================================================

    const handleEdit = useCallback(
        (index) => {
            if (!canManagePackages) {
                setErrorMsg(
                    'No tienes permisos para editar paquetes de Tinkus.'
                );

                return;
            }

            const pkg =
                coinPackages[index];

            if (!pkg) return;

            setEditIndex(index);

            setFormData({
                name: pkg.name ?? '',
                tinkus_amount:
                    pkg.tinkus_amount ?? '',
                cash_amount:
                    pkg.cash_amount ?? '',
                status:
                    pkg.status ?? 'active',
            });

            setErrorMsg('');

            if (
                typeof window !== 'undefined'
            ) {
                window.scrollTo({
                    top: 0,
                    behavior: 'smooth',
                });
            }
        },
        [
            canManagePackages,
            coinPackages,
        ]
    );

    // =====================================================
    // ARCHIVE
    // =====================================================

    const handleDelete = useCallback(
        async (index) => {
            if (!canManagePackages) {
                toast(
                    'No tienes permisos para archivar paquetes.'
                );

                return false;
            }

            const pkg =
                coinPackages[index];

            if (!pkg?.id) {
                return false;
            }

            const confirmed =
                window.confirm(
                    `¿Archivar el paquete "${pkg.name}"?`
                );

            if (!confirmed) {
                return false;
            }

            setRowUpdatingId(pkg.id);

            try {
                const archived =
                    await archiveCoinPackage(
                        pkg.id
                    );

                setCoinPackages(
                    (previous) => {
                        const copy = [...previous];

                        copy[index] = {
                            ...copy[index],
                            ...archived,
                            status:
                                archived?.status ||
                                'archived',
                        };

                        return copy;
                    }
                );

                toast('Paquete archivado');

                return true;
            } catch (error) {
                logWarning('archive', error);

                toast(
                    getErrorMessage(
                        error,
                        'No se pudo archivar el paquete.'
                    )
                );

                return false;
            } finally {
                setRowUpdatingId(null);
            }
        },
        [
            canManagePackages,
            coinPackages,
            toast,
        ]
    );

    // =====================================================
    // ACTIVATE / DEACTIVATE
    // =====================================================

    const handleToggleActive =
        useCallback(
            async (index) => {
                if (!canManagePackages) {
                    toast(
                        'No tienes permisos para cambiar el estado.'
                    );

                    return false;
                }

                const pkg =
                    coinPackages[index];

                if (!pkg?.id) {
                    return false;
                }

                const isCurrentlyActive =
                    pkg.status === 'active';

                setRowUpdatingId(pkg.id);

                try {
                    const updated =
                        isCurrentlyActive
                            ? await deactivateCoinPackage(
                                pkg.id
                            )
                            : await activateCoinPackage(
                                pkg.id
                            );

                    setCoinPackages(
                        (previous) => {
                            const copy = [...previous];

                            copy[index] = {
                                ...copy[index],
                                ...updated,
                            };

                            return copy;
                        }
                    );

                    toast(
                        isCurrentlyActive
                            ? 'Paquete desactivado'
                            : 'Paquete activado'
                    );

                    return true;
                } catch (error) {
                    logWarning('toggle', error);

                    toast(
                        getErrorMessage(
                            error,
                            'No se pudo cambiar el estado.'
                        )
                    );

                    return false;
                } finally {
                    setRowUpdatingId(null);
                }
            },
            [
                canManagePackages,
                coinPackages,
                toast,
            ]
        );

    // =====================================================
    // GET ONE
    // =====================================================

    const fetchPackageById =
        useCallback(
            async (id) => {
                if (!canManagePackages) {
                    setErrorMsg(
                        'No tienes permisos para consultar este paquete.'
                    );

                    return null;
                }

                if (!id) {
                    setErrorMsg(
                        'El identificador es obligatorio.'
                    );

                    return null;
                }

                try {
                    return await getCoinPackageById(
                        id
                    );
                } catch (error) {
                    logWarning(
                        'get package by id',
                        error
                    );

                    setErrorMsg(
                        getErrorMessage(
                            error,
                            'No se pudo cargar el paquete.'
                        )
                    );

                    return null;
                }
            },
            [canManagePackages]
        );

    // =====================================================
    // RETURN
    // =====================================================

    return {
        formData,
        coinPackages,

        loadingList,
        editIndex,
        isSubmitting,
        rowUpdatingId,

        errorMsg,
        message,
        showMessage,

        currentRole,
        canManagePackages,

        setShowMessage,

        handleChange,
        handleSubmit,
        handleEdit,
        handleToggleActive,
        handleDelete,

        resetForm,
        loadPackages,

        getCoinPackageById:
            fetchPackageById,
    };
}