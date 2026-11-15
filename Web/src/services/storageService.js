// src/services/storageService.js

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

async function httpUpload(formData) {
    const token =
        typeof window !== 'undefined' ? localStorage.getItem('token') : null;

    const res = await fetch(`${API_URL}/storage/upload`, {
        method: 'POST',
        headers: token ? { Authorization: `Bearer ${token}` } : undefined,
        body: formData,
    });

    let data = null;

    try {
        data = await res.json();
    } catch (_) { }

    if (!res.ok) {
        throw new Error(data?.error || data?.message || `HTTP ${res.status}`);
    }

    return data;
}

export async function uploadImages(files, { entityType, entityId, folder, itemId } = {}) {
    if (!files) return [];

    const list = Array.isArray(files) ? files : [files];

    if (list.length === 0) return [];

    const finalEntityType = entityType || folder;
    const finalEntityId = entityId || itemId;

    if (!finalEntityType) {
        throw new Error('entityType is required');
    }

    if (!finalEntityId) {
        throw new Error('entityId is required');
    }

    const fd = new FormData();

    fd.append('entityType', finalEntityType);
    fd.append('entityId', String(finalEntityId));

    list.forEach((file) => {
        fd.append('files', file);
    });

    const data = await httpUpload(fd);

    if (Array.isArray(data?.urls)) return data.urls;

    if (Array.isArray(data?.data)) {
        return data.data.map((item) => item.url).filter(Boolean);
    }

    if (Array.isArray(data?.media)) {
        return data.media.map((item) => item.url).filter(Boolean);
    }

    if (Array.isArray(data?.files)) {
        return data.files.map((item) => item.url).filter(Boolean);
    }

    if (Array.isArray(data)) {
        return data.map((item) => item.url || item).filter(Boolean);
    }

    return [];
}