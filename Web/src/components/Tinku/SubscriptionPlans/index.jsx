'use client';

import {
    useState,
    useMemo,
    useCallback,
} from 'react';

import useSubscriptionPlans from '@/hooks/useSubscriptionPlans';

import { uploadImages } from '@/services/storageService';
//import mediaService from '@/services/mediaService';

import Form from '@/components/Tinku/SubscriptionPlans/Form';
import Table from '@/components/Tinku/SubscriptionPlans/Table';

const UI = {
    primary: '#0077B6',
    primaryHover: '#005f92',
    danger: '#E11D48',
    border: '#E2E8F0',
};

export default function SubscriptionPlans() {
    const {
        plans,
        loadingList,
        isSubmitting,

        formData,

        handleChange,
        handleSubmit,

        handleEdit,
        handleDelete,
        handleToggleActive,

        editIndex,

        loadPlans,
        resetForm,
    } = useSubscriptionPlans({
        onlyActive: false,
    });

    // =====================================================
    // UI STATE
    // =====================================================

    const [uploading, setUploading] =
        useState(false);

    const [preview, setPreview] =
        useState('');

    const [modalImage, setModalImage] =
        useState(null);

    const [selectedFile, setSelectedFile] =
        useState(null);

    // =====================================================
    // SORT
    // =====================================================

    const sorted = useMemo(() => {
        return (plans || [])
            .slice()
            .sort(
                (a, b) =>
                    Number(b.id) -
                    Number(a.id)
            );
    }, [plans]);

    // =====================================================
    // HELPERS
    // =====================================================

    const indexById = useCallback(
        (id) => {
            return plans.findIndex(
                (x) =>
                    Number(x.id) ===
                    Number(id)
            );
        },
        [plans]
    );

    // =====================================================
    // EDIT
    // =====================================================

    const onEditById = useCallback(
        (id) => {
            const idx = indexById(id);

            if (idx < 0) return;

            handleEdit(idx);

            const row = plans[idx];

            const image =
                row?.image_url ||
                row?.media?.[0]?.url ||
                '';

            setPreview(image);

            if (
                typeof window !==
                'undefined'
            ) {
                window.scrollTo({
                    top: 0,
                    behavior: 'smooth',
                });
            }
        },
        [
            indexById,
            handleEdit,
            plans,
        ]
    );

    // =====================================================
    // DELETE
    // =====================================================

    const onSoftDeleteById =
        useCallback(
            (id) => {
                const idx =
                    indexById(id);

                if (idx >= 0) {
                    handleDelete(idx);
                }
            },
            [indexById, handleDelete]
        );

    // =====================================================
    // TOGGLE
    // =====================================================

    const onToggleActiveById =
        useCallback(
            (id) => {
                const idx =
                    indexById(id);

                if (idx >= 0) {
                    handleToggleActive(
                        idx
                    );
                }
            },
            [
                indexById,
                handleToggleActive,
            ]
        );

    // =====================================================
    // IMAGE
    // =====================================================

    const onFileChange = useCallback(
        (e) => {
            const file =
                e.target.files?.[0];

            if (!file) return;

            setSelectedFile(file);

            const localPreview =
                URL.createObjectURL(file);

            setPreview(localPreview);
        },
        []
    );

    // =====================================================
    // CLEAR IMAGE
    // =====================================================

    const onClearImage =
        useCallback(() => {
            setPreview('');
            setSelectedFile(null);

            handleChange({
                target: {
                    name: 'image_url',
                    value: '',
                },
            });
        }, [handleChange]);

    // =====================================================
    // AFTER SUBMIT
    // =====================================================

    const handleAfterSubmit =
        useCallback(
            async (savedPlan) => {
                try {
                    // =============================
                    // SUBIR IMAGEN DESPUÉS
                    // =============================

                    if (
                        selectedFile &&
                        savedPlan?.id
                    ) {
                        setUploading(true);

                        // =====================================
                        // ELIMINAR IMÁGENES ANTERIORES
                        // =====================================

               

                        // =====================================
                        // SUBIR NUEVA IMAGEN
                        // =====================================

                        const urls =
                            await uploadImages(
                                [selectedFile],
                                {
                                    entityType:
                                        'subscription',
                                    entityId:
                                        savedPlan.id,
                                    folder:
                                        'subscription-plans',
                                }
                            );

                        const imageUrl =
                            urls?.[0] || '';

                        if (imageUrl) {
                            handleChange({
                                target: {
                                    name: 'image_url',
                                    value:
                                        imageUrl,
                                },
                            });
                        }
                    }

                    await loadPlans();

                    resetForm();

                    setPreview('');

                    setSelectedFile(null);
                } catch (err) {
                    console.error(err);

                    alert(
                        err?.message ||
                        'Error al subir imagen'
                    );
                } finally {
                    setUploading(false);
                }
            },
            [
                selectedFile,
                loadPlans,
                resetForm,
                handleChange,
            ]
        );

    // =====================================================
    // CANCEL
    // =====================================================

    const handleCancel =
        useCallback(() => {
            resetForm();

            setPreview('');

            setSelectedFile(null);
        }, [resetForm]);

    // =====================================================
    // RENDER
    // =====================================================

    return (
        <div className="space-y-6">
            <Form
                UI={UI}
                formData={formData}
                isSubmitting={
                    isSubmitting
                }
                uploading={uploading}
                editIndex={editIndex}
                handleChange={
                    handleChange
                }
                handleSubmit={(e) =>
                    handleSubmit(
                        e,
                        handleAfterSubmit
                    )
                }
                preview={preview}
                onFileChange={
                    onFileChange
                }
                onClearImage={
                    onClearImage
                }
                onPreviewClick={() =>
                    setModalImage(
                        preview ||
                        formData.image_url
                    )
                }
                onCancel={handleCancel}
            />

            <Table
                UI={UI}
                rows={sorted}
                loading={loadingList}
                onRefresh={loadPlans}
                onEditById={
                    onEditById
                }
                onSoftDeleteById={
                    onSoftDeleteById
                }
                onToggleActiveById={
                    onToggleActiveById
                }
                onImageClick={(url) =>
                    setModalImage(url)
                }
            />

            {modalImage && (
                <div
                    className="fixed inset-0 flex items-center justify-center z-50 backdrop-blur-sm"
                    style={{
                        background:
                            'radial-gradient(circle at 50% 40%, rgba(0,0,0,0.45), rgba(0,0,0,0.65) 60%, rgba(0,0,0,0.75))',
                    }}
                    onClick={() =>
                        setModalImage(
                            null
                        )
                    }
                >
                    <div
                        className="relative bg-white/90 p-4 rounded-2xl shadow-2xl"
                        onClick={(e) =>
                            e.stopPropagation()
                        }
                    >
                        <img
                            src={modalImage}
                            alt="Ampliación"
                            className="max-h-[85vh] max-w-[85vw] rounded-lg shadow-lg border border-slate-200"
                        />

                        <button
                            onClick={() =>
                                setModalImage(
                                    null
                                )
                            }
                            className="absolute top-3 right-3 bg-black/60 text-white rounded-full px-2 py-1 hover:bg-black/80 transition"
                        >
                            ✕
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
} 