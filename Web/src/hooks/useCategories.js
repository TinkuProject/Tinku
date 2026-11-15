// File: src/hooks/useCategories.js

'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';

import { useUser } from '../context/UserContext';

import CategoryService, {
    buildCategoryPayload,
} from '../services/categoriesService';

import { uploadImages } from '../services/storageService';
import mediaService from '../services/mediaService';

export default function useCategories() {
    const { user: currentUser } = useUser();

    // =====================================================
    // ROLE
    // =====================================================

    const currentRole =
        currentUser?.role ||
        currentUser?.profile?.role ||
        null;

    const canManageCategories = currentRole === 'master';

    // =====================================================
    // STATE
    // =====================================================

    const [formData, setFormData] = useState({
        name: '',
        entity_type: '',
        business_type: '',
        file: null,
    });

    const [preview, setPreview] = useState('');
    const [hasImage, setHasImage] = useState(false);

    const [categories, setCategories] = useState([]);
    const [loadingList, setLoadingList] = useState(false);
    const [editIndex, setEditIndex] = useState(null);

    const [isSubmitting, setIsSubmitting] = useState(false);
    const [isUploading, setIsUploading] = useState(false);
    const [rowUpdatingId, setRowUpdatingId] = useState(null);

    const [errorMsg, setErrorMsg] = useState('');
    const [message, setMessage] = useState('');
    const [showMessage, setShowMessage] = useState(false);

    // =====================================================
    // OPTIONS
    // =====================================================

    const ENTITY_TYPES = useMemo(
        () => [
            { value: 'business', label: 'Negocio' },
            { value: 'event', label: 'Evento' },
            {
                value: 'tourist_place',
                label: 'Lugar turístico',
            },
            { value: 'product', label: 'Producto' },
        ],
        []
    );

    const BUSINESS_TYPES = useMemo(
        () => [
            { value: 'business', label: 'Negocio' },
            { value: 'service', label: 'Servicio' },
        ],
        []
    );

    // =====================================================
    // HELPERS
    // =====================================================

    const toast = useCallback((msg) => {
        setMessage(msg);
        setShowMessage(true);
    }, []);

    const getErrorMessage = useCallback(
        (error, fallback) => {
            if (error?.status === 401) {
                return 'Tu sesión no es válida o ha expirado.';
            }

            if (error?.status === 403) {
                return 'No tienes permisos para administrar categorías.';
            }

            if (error?.status === 404) {
                return 'El recurso solicitado no fue encontrado.';
            }

            return error?.message || fallback;
        },
        []
    );

    const logWarning = useCallback((scope, error) => {
        /*
         * No enviamos el objeto Error completo mediante console.error,
         * porque Next.js puede mostrarlo como overlay en desarrollo.
         */
        console.warn(`[useCategories] ${scope}:`, {
            message: error?.message || 'Error desconocido',
            status: error?.status || null,
            code: error?.code || null,
        });
    }, []);

    const resetForm = useCallback(() => {
        setFormData({
            name: '',
            entity_type: '',
            business_type: '',
            file: null,
        });

        setPreview('');
        setHasImage(false);
        setEditIndex(null);
        setErrorMsg('');
    }, []);

    // =====================================================
    // LOAD CATEGORIES
    // =====================================================

    const loadCategories = useCallback(async () => {
        /*
         * No ejecutar el endpoint administrativo mientras
         * el contexto todavía está cargando el usuario.
         */
        if (!currentRole) {
            setCategories([]);
            setLoadingList(false);
            setErrorMsg('');
            return;
        }

        /*
         * Category solamente está disponible para master.
         * Un user, partner o admin no debe llamar /categories/admin.
         */
        if (!canManageCategories) {
            setCategories([]);
            setLoadingList(false);
            setErrorMsg('');
            return;
        }

        setLoadingList(true);
        setErrorMsg('');

        try {
            const data = await CategoryService.listAdmin();

            const finalData = Array.isArray(data)
                ? data
                : Array.isArray(data?.data)
                    ? data.data
                    : Array.isArray(data?.categories)
                        ? data.categories
                        : [];

            const ids = [
                ...new Set(
                    finalData
                        .map((category) => Number(category?.id))
                        .filter((id) => Number.isFinite(id))
                ),
            ];

            let mediaMap = {};

            if (ids.length > 0) {
                try {
                    mediaMap = await mediaService.getByEntities(
                        'category',
                        ids
                    );
                } catch (mediaError) {
                    logWarning('load media', mediaError);
                    mediaMap = {};
                }
            }

            const categoriesWithMedia = finalData.map(
                (category) => {
                    const categoryMedia =
                        mediaMap?.[category.id] ||
                        mediaMap?.[String(category.id)] ||
                        [];

                    return {
                        ...category,
                        media: Array.isArray(categoryMedia)
                            ? categoryMedia
                            : [],
                    };
                }
            );

            setCategories(categoriesWithMedia);
        } catch (error) {
            logWarning('loadCategories', error);

            setCategories([]);
            setErrorMsg(
                getErrorMessage(
                    error,
                    'No se pudieron cargar las categorías.'
                )
            );
        } finally {
            setLoadingList(false);
        }
    }, [
        currentRole,
        canManageCategories,
        getErrorMessage,
        logWarning,
    ]);

    useEffect(() => {
        if (!currentRole) return;
        if (!canManageCategories) return;

        loadCategories();
    }, [
        currentRole,
        canManageCategories,
        loadCategories,
    ]);

    // =====================================================
    // FORM CHANGE
    // =====================================================

    const handleChange = useCallback((event) => {
        const { name, value } = event.target;

        setErrorMsg('');

        setFormData((previous) => {
            const next = {
                ...previous,
                [name]: value,
            };

            if (
                name === 'entity_type' &&
                value !== 'business'
            ) {
                next.business_type = '';
            }

            return next;
        });
    }, []);

    // =====================================================
    // FILE CHANGE
    // =====================================================

    const handleFileChange = useCallback((event) => {
        const file = event.target.files?.[0];

        if (!file) return;

        if (!file.type?.startsWith('image/')) {
            setErrorMsg(
                'El archivo seleccionado debe ser una imagen.'
            );
            return;
        }

        setFormData((previous) => ({
            ...previous,
            file,
        }));

        const objectUrl = URL.createObjectURL(file);

        setPreview((previousPreview) => {
            if (
                previousPreview &&
                previousPreview.startsWith('blob:')
            ) {
                URL.revokeObjectURL(previousPreview);
            }

            return objectUrl;
        });

        setHasImage(true);
        setErrorMsg('');
    }, []);

    // =====================================================
    // UPLOAD IMAGE
    // =====================================================

    const uploadCategoryImageIfNeeded = useCallback(
        async (categoryId) => {
            if (!formData.file || !categoryId) {
                return;
            }

            if (!canManageCategories) {
                throw new Error(
                    'No tienes permisos para subir imágenes de categorías.'
                );
            }

            setIsUploading(true);

            try {
                await uploadImages([formData.file], {
                    entityType: 'category',
                    entityId: categoryId,
                });
            } finally {
                setIsUploading(false);
            }
        },
        [formData.file, canManageCategories]
    );

    // =====================================================
    // SUBMIT
    // =====================================================

    const handleSubmit = useCallback(
        async (event) => {
            event.preventDefault();

            if (isSubmitting) return;

            if (!canManageCategories) {
                setErrorMsg(
                    'No tienes permisos para administrar categorías.'
                );
                return;
            }

            setErrorMsg('');

            if (!formData.name.trim()) {
                setErrorMsg('El nombre es obligatorio.');
                return;
            }

            if (!formData.entity_type) {
                setErrorMsg('Selecciona un tipo.');
                return;
            }

            if (
                formData.entity_type === 'business' &&
                !formData.business_type
            ) {
                setErrorMsg(
                    'Selecciona un tipo de negocio.'
                );
                return;
            }

            setIsSubmitting(true);

            try {
                const payload =
                    buildCategoryPayload(formData);

                if (editIndex !== null) {
                    const categoryId =
                        categories[editIndex]?.id;

                    if (!categoryId) {
                        throw new Error(
                            'ID inválido para edición.'
                        );
                    }

                    await CategoryService.update(
                        categoryId,
                        payload
                    );

                    await uploadCategoryImageIfNeeded(
                        categoryId
                    );

                    await loadCategories();

                    toast('Categoría actualizada');
                } else {
                    const created =
                        await CategoryService.create(payload);

                    const categoryId =
                        created?.id ||
                        created?.data?.id ||
                        created?.category?.id;

                    if (!categoryId) {
                        throw new Error(
                            'La categoría fue creada, pero la API no devolvió su identificador.'
                        );
                    }

                    await uploadCategoryImageIfNeeded(
                        categoryId
                    );

                    await loadCategories();

                    toast('Categoría creada');
                }

                resetForm();
            } catch (error) {
                logWarning('submit', error);

                setErrorMsg(
                    getErrorMessage(
                        error,
                        'Error al guardar la categoría.'
                    )
                );
            } finally {
                setIsSubmitting(false);
            }
        },
        [
            canManageCategories,
            categories,
            editIndex,
            formData,
            isSubmitting,
            getErrorMessage,
            loadCategories,
            logWarning,
            resetForm,
            toast,
            uploadCategoryImageIfNeeded,
        ]
    );

    // =====================================================
    // EDIT
    // =====================================================

    const handleEdit = useCallback(
        (index) => {
            if (!canManageCategories) {
                setErrorMsg(
                    'No tienes permisos para editar categorías.'
                );
                return;
            }

            const category = categories[index];

            if (!category) return;

            const image =
                category.media?.[0]?.url ||
                category.media?.[0]?.image_url ||
                category.media?.[0]?.media_url ||
                category.media?.[0]?.path ||
                '';

            setEditIndex(index);

            setFormData({
                name: category.name || '',
                entity_type: category.entity_type || '',
                business_type:
                    category.business_type || '',
                file: null,
            });

            setPreview(image);
            setHasImage(Boolean(image));
            setErrorMsg('');

            if (typeof window !== 'undefined') {
                window.scrollTo({
                    top: 0,
                    behavior: 'smooth',
                });
            }
        },
        [categories, canManageCategories]
    );

    // =====================================================
    // ACTIVATE / DEACTIVATE
    // =====================================================

    const handleToggleActive = useCallback(
        async (index) => {
            if (!canManageCategories) {
                toast(
                    'No tienes permisos para cambiar el estado.'
                );
                return;
            }

            const category = categories[index];

            if (!category?.id) return;

            setRowUpdatingId(category.id);

            try {
                let updated;

                if (category.status === 'active') {
                    updated =
                        await CategoryService.deactivate(
                            category.id
                        );
                } else {
                    updated =
                        await CategoryService.activate(
                            category.id
                        );
                }

                await loadCategories();

                toast(
                    updated?.status === 'active'
                        ? 'Categoría activada'
                        : 'Categoría desactivada'
                );
            } catch (error) {
                logWarning('toggle', error);

                toast(
                    getErrorMessage(
                        error,
                        'No se pudo cambiar el estado.'
                    )
                );
            } finally {
                setRowUpdatingId(null);
            }
        },
        [
            canManageCategories,
            categories,
            getErrorMessage,
            loadCategories,
            logWarning,
            toast,
        ]
    );

    // =====================================================
    // SOFT DELETE
    // =====================================================

    const handleSoftDelete = useCallback(
        async (index) => {
            if (!canManageCategories) {
                toast(
                    'No tienes permisos para eliminar categorías.'
                );
                return;
            }

            const category = categories[index];

            if (!category?.id) return;

            const confirmed = window.confirm(
                `¿Eliminar la categoría "${category.name}"?`
            );

            if (!confirmed) return;

            setRowUpdatingId(category.id);

            try {
                await CategoryService.softDelete(
                    category.id
                );

                await loadCategories();

                toast('Categoría eliminada');
            } catch (error) {
                logWarning('delete', error);

                toast(
                    getErrorMessage(
                        error,
                        'No se pudo eliminar la categoría.'
                    )
                );
            } finally {
                setRowUpdatingId(null);
            }
        },
        [
            canManageCategories,
            categories,
            getErrorMessage,
            loadCategories,
            logWarning,
            toast,
        ]
    );

    // =====================================================
    // RETURN
    // =====================================================

    return {
        formData,
        preview,
        hasImage,
        categories,

        loadingList,
        editIndex,

        isSubmitting,
        isUploading,
        rowUpdatingId,

        errorMsg,
        message,
        showMessage,

        currentRole,
        canManageCategories,

        ENTITY_TYPES,
        BUSINESS_TYPES,

        setShowMessage,

        handleChange,
        handleFileChange,
        handleSubmit,
        handleEdit,
        handleToggleActive,
        handleSoftDelete,
        resetForm,
        reload: loadCategories,
    };
}