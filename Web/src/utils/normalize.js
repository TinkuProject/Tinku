// Normaliza item desde la API a lo que espera el front (cover para preview)
export function normalizeCategoryFromApi(item) {
    if (!item || typeof item !== 'object') return { cover: '', status: 1 };
    return {
        ...item,
        cover: item.media || item.cover || '', // preferimos media
        status: typeof item.status === 'number' ? item.status : 1,
    };
}

// Arma payload para la API desde los datos del formulario
export function categoryPayloadFromForm(formData) {
    return {
        name: (formData?.name || '').trim(),
        type: (formData?.type || '').trim(),
        subtype: (formData?.subtype || '').trim() || null,
        media: (formData?.cover || '').trim() || null, // la API espera "media"
    };
}

// Sanea ediciones (cuando abres modal/edición)
export function formFromCategory(item) {
    return {
        name: item?.name || '',
        type: item?.type === 'product' ? '' : (item?.type || ''), // por si viene legacy no permitido
        subtype: item?.subtype || '',
        cover: item?.media || item?.cover || '',
    };
}
