// File: src/hooks/useSubscriptionPlans.js
'use client';

import {
    useCallback,
    useEffect,
    useState,
} from 'react';

import {
    getSubscriptionPlans,
    getSubscriptionPlanById,

    createSubscriptionPlan,
    updateSubscriptionPlan,

    archiveSubscriptionPlan,

    activateSubscriptionPlan,
    deactivateSubscriptionPlan,
} from '../services/subscriptionPlansService';
import mediaService from '../services/mediaService';

// =====================================================
// VALIDATIONS
// =====================================================

function validateRequired({
    name,
    price,
}) {
    if (!name?.trim()) {
        return 'El nombre es requerido';
    }

    if (
        price === '' ||
        price === null ||
        price === undefined
    ) {
        return 'El precio es requerido';
    }

    if (
        Number.isNaN(Number(price)) ||
        Number(price) < 0
    ) {
        return 'El precio no es válido';
    }

    return '';
}

function validateIncludedTinku(
    included_tinku
) {
    if (
        included_tinku === '' ||
        included_tinku == null
    ) {
        return '';
    }

    const n = Number(
        included_tinku
    );

    if (
        Number.isNaN(n) ||
        n < 0
    ) {
        return 'Las Tinku incluidas deben ser un número mayor o igual a 0';
    }

    return '';
}

// =====================================================
// HOOK
// =====================================================

export default function useSubscriptionPlans() {
    // =====================================================
    // FORM
    // =====================================================

    const [formData, setFormData] =
        useState({
            name: '',

            price: '',

            currency: 'BOB',

            duration_months: '',

            included_tinku: '',

            status: 'active',
        });

    // =====================================================
    // LIST
    // =====================================================

    const [plans, setPlans] =
        useState([]);

    const [loadingList, setLoadingList] =
        useState(true);

    const [editIndex, setEditIndex] =
        useState(null);

    // =====================================================
    // UI
    // =====================================================

    const [
        isSubmitting,
        setIsSubmitting,
    ] = useState(false);

    const [
        rowUpdatingId,
        setRowUpdatingId,
    ] = useState(null);

    const [errorMsg, setErrorMsg] =
        useState('');

    const [message, setMessage] =
        useState('');

    const [
        showMessage,
        setShowMessage,
    ] = useState(false);

    // =====================================================
    // TOAST
    // =====================================================

    const toast = useCallback(
        (msg) => {
            setMessage(msg);
            setShowMessage(true);
        },
        []
    );

    // =====================================================
    // RESET
    // =====================================================

    const resetForm = useCallback(() => {
        setFormData({
            name: '',

            price: '',

            currency: 'BOB',

            duration_months: '',

            included_tinku: '',

            status: 'active',
        });

        setEditIndex(null);

        setErrorMsg('');
    }, []);

    // =====================================================
    // LOAD
    // =====================================================

    const loadPlans = useCallback(
        async () => {
            setLoadingList(true);

            try {
                const data = await getSubscriptionPlans();

                const basePlans = Array.isArray(data) ? data : [];

                const ids = basePlans
                    .map((plan) => Number(plan.id))
                    .filter((id) => Number.isFinite(id));

                let mediaMap = {};

                if (ids.length > 0) {
                    mediaMap = await mediaService.getByEntities(
                        'subscription',
                        ids
                    );
                }

                const plansWithMedia = basePlans.map((plan) => {
                    const rawMedia =
                        mediaMap?.[plan.id] ||
                        mediaMap?.[String(plan.id)] ||
                        [];

                    const media = Array.isArray(rawMedia)
                        ? rawMedia
                        : [];

                    const sortedMedia = [...media].sort((a, b) => {
                        const dateA = new Date(a.created_at || 0).getTime();
                        const dateB = new Date(b.created_at || 0).getTime();

                        if (dateA !== dateB) {
                            return dateB - dateA;
                        }

                        return Number(b.id || 0) - Number(a.id || 0);
                    });

                    const newest = sortedMedia[0];

                    const imageUrl =
                        newest?.url ||
                        newest?.image_url ||
                        newest?.media_url ||
                        newest?.path ||
                        '';

                    return {
                        ...plan,
                        media: sortedMedia,
                        image_url: imageUrl,
                    };
                });

                setPlans(plansWithMedia);
            } catch (err) {
                console.warn('[useSubscriptionPlans] load:', err);
                setPlans([]);
            } finally {
                setLoadingList(false);
            }
        },
        []
    );

    useEffect(() => {
        loadPlans();
    }, [loadPlans]);

    // =====================================================
    // CHANGE
    // =====================================================

    const handleChange = useCallback(
        (e) => {
            const { name, value } =
                e.target;

            setErrorMsg('');

            if (
                [
                    'price',
                    'included_tinku',
                    'duration_months',
                ].includes(name)
            ) {
                setFormData((prev) => ({
                    ...prev,
                    [name]:
                        value === ''
                            ? ''
                            : Number(value),
                }));

                return;
            }

            setFormData((prev) => ({
                ...prev,
                [name]: value,
            }));
        },
        []
    );

    // =====================================================
    // SUBMIT
    // =====================================================

    const handleSubmit =
        useCallback(
            async (
                e,
                afterSubmit
            ) => {
                e?.preventDefault?.();

                if (isSubmitting)
                    return;

                setIsSubmitting(true);

                setErrorMsg('');

                try {
                    // VALIDATION
                    const reqErr =
                        validateRequired({
                            name: formData.name,
                            price:
                                formData.price,
                        });

                    if (reqErr) {
                        setErrorMsg(reqErr);

                        setIsSubmitting(false);

                        return;
                    }

                    const tinkuErr =
                        validateIncludedTinku(
                            formData.included_tinku
                        );

                    if (tinkuErr) {
                        setErrorMsg(
                            tinkuErr
                        );

                        setIsSubmitting(false);

                        return;
                    }

                    // PAYLOAD
                    const payload = {
                        name:
                            formData.name?.trim(),

                        price: Number(
                            formData.price
                        ),

                        currency:
                            formData.currency ||
                            'BOB',

                        duration_months:
                            formData.duration_months ===
                                '' ||
                                formData.duration_months ==
                                null
                                ? undefined
                                : Number(
                                    formData.duration_months
                                ),

                        included_tinku:
                            formData.included_tinku ===
                                '' ||
                                formData.included_tinku ==
                                null
                                ? 0
                                : Number(
                                    formData.included_tinku
                                ),

                        status:
                            formData.status ||
                            'active',
                    };

                    // =====================================================
                    // SAVE RESPONSE
                    // =====================================================

                    let response = null;

                    // =====================================================
                    // UPDATE
                    // =====================================================

                    if (
                        editIndex !== null
                    ) {
                        const id =
                            plans[editIndex]
                                ?.id;

                        if (!id) {
                            throw new Error(
                                'ID inválido'
                            );
                        }

                        response =
                            await updateSubscriptionPlan(
                                id,
                                payload
                            );

                        setPlans((prev) => {
                            const copy = [
                                ...prev,
                            ];

                            copy[
                                editIndex
                            ] = {
                                ...copy[
                                editIndex
                                ],
                                ...response,
                            };

                            return copy;
                        });

                        toast(
                            'Plan actualizado'
                        );
                    }

                    // =====================================================
                    // CREATE
                    // =====================================================

                    else {
                        response =
                            await createSubscriptionPlan(
                                payload
                            );

                        setPlans((prev) => [
                            response,
                            ...prev,
                        ]);

                        toast(
                            'Plan creado'
                        );
                    }

                    // =====================================================
                    // CALLBACK
                    // =====================================================

                    if (
                        typeof afterSubmit ===
                        'function'
                    ) {
                        await afterSubmit(response);
                    }

                    resetForm();

                } catch (err) {
                    console.error(
                        '[useSubscriptionPlans] submit:',
                        err
                    );

                    setErrorMsg(
                        err.message ||
                        'Error al guardar'
                    );
                } finally {
                    setIsSubmitting(false);
                }
            },
            [
                isSubmitting,
                formData,
                editIndex,
                plans,
                resetForm,
                toast,
            ]
        );

    // =====================================================
    // EDIT
    // =====================================================

    const handleEdit =
        useCallback(
            (index) => {
                const p =
                    plans[index];

                if (!p) return;

                setEditIndex(index);

                setFormData({
                    name:
                        p.name ?? '',

                    price:
                        p.price ?? '',

                    currency:
                        p.currency ??
                        'BOB',

                    included_tinku:
                        p.included_tinku ??
                        '',

                    duration_months:
                        p.duration_months ??
                        '',

                    status:
                        p.status ??
                        'active',
                });

                if (
                    typeof window !==
                    'undefined'
                ) {
                    window.scrollTo({
                        top: 0,
                        behavior:
                            'smooth',
                    });
                }
            },
            [plans]
        );

    // =====================================================
    // ARCHIVE
    // =====================================================

    const handleDelete =
        useCallback(
            async (index) => {
                const plan =
                    plans[index];

                if (!plan?.id)
                    return;

                setRowUpdatingId(
                    plan.id
                );

                try {
                    await archiveSubscriptionPlan(
                        plan.id
                    );

                    setPlans((prev) => {
                        const copy = [
                            ...prev,
                        ];

                        copy[index] = {
                            ...copy[index],
                            status:
                                'archived',
                        };

                        return copy;
                    });

                    toast(
                        'Plan archivado'
                    );
                } catch (err) {
                    console.error(
                        '[useSubscriptionPlans] archive:',
                        err
                    );

                    toast(
                        'No se pudo archivar'
                    );
                } finally {
                    setRowUpdatingId(
                        null
                    );
                }
            },
            [plans, toast]
        );

    // =====================================================
    // TOGGLE STATUS
    // =====================================================

    const handleToggleActive =
        useCallback(
            async (index) => {
                const plan =
                    plans[index];

                if (!plan?.id)
                    return;

                const current =
                    plan.status ===
                    'active';

                setRowUpdatingId(
                    plan.id
                );

                try {
                    let updated;

                    if (current) {
                        updated =
                            await deactivateSubscriptionPlan(
                                plan.id
                            );
                    } else {
                        updated =
                            await activateSubscriptionPlan(
                                plan.id
                            );
                    }

                    setPlans((prev) => {
                        const copy = [
                            ...prev,
                        ];

                        copy[index] = {
                            ...copy[index],
                            ...updated,
                        };

                        return copy;
                    });

                    toast(
                        current
                            ? 'Plan desactivado'
                            : 'Plan activado'
                    );
                } catch (err) {
                    console.error(
                        '[useSubscriptionPlans] toggle:',
                        err
                    );

                    toast(
                        'No se pudo cambiar el estado'
                    );
                } finally {
                    setRowUpdatingId(
                        null
                    );
                }
            },
            [plans, toast]
        );

    // =====================================================
    // RETURN
    // =====================================================

    return {
        // state
        formData,

        plans,

        loadingList,

        editIndex,

        isSubmitting,

        rowUpdatingId,

        errorMsg,

        message,

        showMessage,

        // actions
        setShowMessage,

        handleChange,

        handleSubmit,

        handleEdit,

        handleToggleActive,

        handleDelete,

        resetForm,

        loadPlans,

        // util
        getSubscriptionPlanById,
    };
}