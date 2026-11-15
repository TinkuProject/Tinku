'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import toast from 'react-hot-toast';

import SystemConfigService, {
    buildSystemConfigPayload,
} from '@/services/systemConfigService';

export default function useSystemConfig() {
    const [allRows, setAllRows] = useState([]);

    const [loading, setLoading] = useState(true);
    const [err, setErr] = useState('');
    const [savingKey, setSavingKey] = useState(null);

    const [search, setSearch] = useState('');

    const normalizeList = (data) => {
        if (Array.isArray(data)) return data;

        if (Array.isArray(data?.data)) return data.data;

        if (Array.isArray(data?.items)) return data.items;

        return [];
    };

    const fetchAll = useCallback(async () => {
        setLoading(true);
        setErr('');

        try {
            const data = await SystemConfigService.list();

            setAllRows(normalizeList(data));
        } catch (e) {
            console.error('[useSystemConfig] list:', e);

            setErr(
                e?.message ||
                'Error al cargar las configuraciones del sistema'
            );

            toast.error(
                'Error al cargar las configuraciones del sistema'
            );

            setAllRows([]);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchAll();
    }, [fetchAll]);

    const rows = useMemo(() => {
        const term = search.trim().toLowerCase();

        if (!term) return allRows;

        return allRows.filter((row) =>
            [row.key, row.value, row.description]
                .map((item) => String(item ?? '').toLowerCase())
                .some((item) => item.includes(term))
        );
    }, [allRows, search]);

    const get = useCallback(async (key) => {
        if (!key) {
            throw new Error('La clave es obligatoria');
        }

        return SystemConfigService.get(key);
    }, []);

    const save = useCallback(
        async (key, values = {}) => {
            const cleanKey = String(key || '').trim();

            if (!cleanKey) {
                toast.error('La clave es obligatoria');
                return false;
            }

            const payload = buildSystemConfigPayload(values);

            if (
                payload.value === undefined &&
                payload.description === undefined
            ) {
                toast.error('Debes modificar el valor o la descripción');
                return false;
            }

            const exists = allRows.some(
                (row) => row.key === cleanKey
            );

            if (!exists && payload.value === undefined) {
                toast.error(
                    'El valor es obligatorio para crear una configuración'
                );
                return false;
            }

            setSavingKey(cleanKey);

            const toastId = toast.loading(
                exists
                    ? 'Guardando configuración…'
                    : 'Creando configuración…'
            );

            try {
                const updated = await SystemConfigService.update(
                    cleanKey,
                    payload
                );

                setAllRows((previous) =>
                    [...previous.filter((row) => row.key !== updated.key), updated]
                        .sort((a, b) => a.key.localeCompare(b.key))
                );

                toast.success(
                    exists
                        ? 'Configuración actualizada'
                        : 'Configuración creada',
                    { id: toastId }
                );

                return updated;
            } catch (e) {
                console.error('[useSystemConfig] save:', e);

                toast.error(
                    e?.message ||
                    'No se pudo guardar la configuración',
                    { id: toastId }
                );

                return false;
            } finally {
                setSavingKey(null);
            }
        },
        [allRows]
    );

    const getPublicNumber = useCallback(async (key) => {
        if (!key) {
            throw new Error('La clave es obligatoria');
        }

        const data =
            await SystemConfigService.getPublicNumber(key);

        return data?.value;
    }, []);

    return {
        rows,
        filteredRows: rows,
        allRows,

        loading,
        err,
        savingKey,

        search,
        setSearch,

        fetchAll,
        get,
        save,
        getPublicNumber,
    };
}