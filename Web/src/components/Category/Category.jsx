// File: src/components/Category/Category.jsx
'use client';

import useCategories from '../../hooks/useCategories';

import CategoryForm from './CategoryForm';
import CategoryTable from './CategoryTable';
import Toast from './Toast';

export default function Category() {
  const {
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
  } = useCategories();

  return (
    <div className="p-10 bg-white rounded-2xl shadow-sm border border-slate-200">
      <h1 className="text-3xl font-semibold mb-8 text-[#0077B6]">
        Gestión de Categorías
      </h1>

      <CategoryForm
        formData={formData}
        preview={preview}
        hasImage={hasImage}
        entityTypes={ENTITY_TYPES}
        businessTypes={BUSINESS_TYPES}
        isSubmitting={isSubmitting}
        isUploading={isUploading}
        errorMsg={errorMsg}
        editIndex={editIndex}
        onChange={handleChange}
        onFileChange={handleFileChange}
        onSubmit={handleSubmit}
        onCancel={resetForm}
      />

      <Toast
        open={showMessage}
        onClose={() => setShowMessage(false)}
      >
        {message}
      </Toast>

      <hr className="my-6 border-slate-200" />

      <CategoryTable
        categories={categories}
        loading={loadingList}
        rowUpdatingId={rowUpdatingId}
        onEdit={handleEdit}
        onToggleActive={handleToggleActive}
        onDelete={handleSoftDelete}
        isSubmitting={isSubmitting}
        entityTypes={ENTITY_TYPES}
      />
    </div>
  );
}