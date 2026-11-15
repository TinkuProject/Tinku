// File: src/components/CoinPackages/index.jsx
'use client';

import { useState, useMemo, useCallback } from 'react';

import useCoinPackages from '@/hooks/useCoinPackages';
import { uploadImages } from '@/services/storageService';

import Form from '@/components/Tinku/CoinPackages/Form';
import Table from '@/components/Tinku/CoinPackages/Table';

const UI = {
    primary: '#0077B6',
    primaryHover: '#005f92',
    danger: '#E11D48',
    border: '#E2E8F0',
};

export default function CoinPackages() {
    const {
        coinPackages,
        loadingList,
        isSubmitting,
        formData,
        handleChange,
        handleSubmit,
        handleEdit,
        handleDelete,
        handleToggleActive,
        editIndex,
        loadPackages,
        resetForm,
    } = useCoinPackages();

    const [uploading, setUploading] = useState(false);
    const [preview, setPreview] = useState('');
    const [modalImage, setModalImage] = useState(null);
    const [selectedFile, setSelectedFile] = useState(null);

    const sorted = useMemo(() => {
        return (coinPackages || [])
            .slice()
            .sort((a, b) => Number(b.id) - Number(a.id));
    }, [coinPackages]);

    const indexById = useCallback(
        (id) => {
            return coinPackages.findIndex(
                (x) => Number(x.id) === Number(id)
            );
        },
        [coinPackages]
    );

    const onEditById = useCallback(
        (id) => {
            const idx = indexById(id);
            if (idx < 0) return;

            handleEdit(idx);

            const row = coinPackages[idx];

            const image =
                row?.image_url ||
                row?.media?.[0]?.url ||
                row?.media?.[0]?.image_url ||
                row?.media?.[0]?.media_url ||
                row?.media?.[0]?.path ||
                '';

            setPreview(image);

            if (typeof window !== 'undefined') {
                window.scrollTo({
                    top: 0,
                    behavior: 'smooth',
                });
            }
        },
        [indexById, handleEdit, coinPackages]
    );

    const onSoftDeleteById = useCallback(
        (id) => {
            const idx = indexById(id);
            if (idx >= 0) handleDelete(idx);
        },
        [indexById, handleDelete]
    );

    const onToggleActiveById = useCallback(
        (id) => {
            const idx = indexById(id);
            if (idx >= 0) handleToggleActive(idx);
        },
        [indexById, handleToggleActive]
    );

    const onFileChange = useCallback((e) => {
        const file = e.target.files?.[0];
        if (!file) return;

        setSelectedFile(file);
        setPreview(URL.createObjectURL(file));
    }, []);

    const onClearImage = useCallback(() => {
        setPreview('');
        setSelectedFile(null);
    }, []);

    const handleAfterSubmit = useCallback(
        async (savedPackage) => {
            try {
                if (selectedFile && savedPackage?.id) {
                    setUploading(true);

                    await uploadImages([selectedFile], {
                        entityType: 'coin_package',
                        entityId: savedPackage.id,
                        folder: 'coin-packages',
                    });
                }

                await loadPackages();
                resetForm();

                setPreview('');
                setSelectedFile(null);
            } catch (err) {
                console.error(err);
                console.error('[CoinPackages] upload:', err);
            } finally {
                setUploading(false);
            }
        },
        [selectedFile, loadPackages, resetForm]
    );

    const handleCancel = useCallback(() => {
        resetForm();
        setPreview('');
        setSelectedFile(null);
    }, [resetForm]);

    return (
        <div className="space-y-6">
            <Form
                UI={UI}
                formData={formData}
                isSubmitting={isSubmitting}
                uploading={uploading}
                editIndex={editIndex}
                handleChange={handleChange}
                handleSubmit={(e) => handleSubmit(e, handleAfterSubmit)}
                preview={preview}
                onFileChange={onFileChange}
                onClearImage={onClearImage}
                onCancel={handleCancel}
            />

            <Table
                UI={UI}
                rows={sorted}
                loading={loadingList}
                onRefresh={loadPackages}
                onEditById={onEditById}
                onSoftDeleteById={onSoftDeleteById}
                onToggleActiveById={onToggleActiveById}
                onImageClick={(url) => setModalImage(url)}
            />

            {modalImage && (
                <div
                    className="fixed inset-0 flex items-center justify-center z-50 backdrop-blur-sm"
                    style={{
                        background:
                            'radial-gradient(circle at 50% 40%, rgba(0,0,0,0.45), rgba(0,0,0,0.65) 60%, rgba(0,0,0,0.75))',
                    }}
                    onClick={() => setModalImage(null)}
                >
                    <div
                        className="relative bg-white/90 p-4 rounded-2xl shadow-2xl"
                        onClick={(e) => e.stopPropagation()}
                    >
                        <img
                            src={modalImage}
                            alt="Ampliación"
                            className="max-h-[85vh] max-w-[85vw] rounded-lg shadow-lg border border-slate-200"
                        />

                        <button
                            onClick={() => setModalImage(null)}
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