// src/hooks/useVehicleTypes.js
'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import toast from 'react-hot-toast';
import VehicleTypesService from '@/services/vehicleTypesService';

export default function useVehicleTypes() {
    const [rows, setRows] = useState([]);
    const [loading, setLoading] = useState(true);
    const [err, setErr] = useState('');
    const [savingId, setSavingId] = useState(null);
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
            const data = await VehicleTypesService.list();
            setRows(normalizeList(data));
        } catch (e) {
            setErr(e?.message || 'Error al cargar tipos de vehículo');
            toast.error('No se pudo cargar la lista');
            setRows([]);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchAll();
    }, [fetchAll]);

    const filtered = useMemo(() => {
        const term = search.trim().toLowerCase();

        if (!term) return rows;

        return rows.filter((v) =>
            String(v.name || '').toLowerCase().includes(term)
        );
    }, [rows, search]);

    const create = useCallback(async (name) => {
        const cleanName = String(name || '').trim();

        if (!cleanName) {
            toast.error('El nombre es obligatorio');
            return;
        }

        const t = toast.loading('Creando…');

        try {
            const created = await VehicleTypesService.create({
                name: cleanName,
            });

            setRows((prev) => [created, ...prev]);

            toast.success('Tipo creado', { id: t });

            return created;
        } catch (e) {
            toast.error(e?.message || 'Error al crear', { id: t });
            throw e;
        }
    }, []);

    const update = useCallback(async (id, name) => {
        const cleanName = String(name || '').trim();

        if (!id) {
            toast.error('ID inválido');
            return;
        }

        if (!cleanName) {
            toast.error('El nombre es obligatorio');
            return;
        }

        setSavingId(id);

        const t = toast.loading('Guardando…');

        try {
            const updated = await VehicleTypesService.update(id, {
                name: cleanName,
            });

            setRows((prev) =>
                prev.map((row) =>
                    Number(row.id) === Number(id) ? updated : row
                )
            );

            toast.success('Cambios guardados', { id: t });

            return updated;
        } catch (e) {
            toast.error(e?.message || 'Error al actualizar', { id: t });
            throw e;
        } finally {
            setSavingId(null);
        }
    }, []);

    const remove = useCallback(async (id) => {
        if (!id) {
            toast.error('ID inválido');
            return;
        }

        const ok = window.confirm('¿Eliminar este tipo de vehículo?');

        if (!ok) return;

        setSavingId(id);

        const t = toast.loading('Eliminando…');

        try {
            await VehicleTypesService.remove(id);

            setRows((prev) =>
                prev.filter((row) => Number(row.id) !== Number(id))
            );

            toast.success('Eliminado', { id: t });
        } catch (e) {
            toast.error(e?.message || 'Error al eliminar', { id: t });
            throw e;
        } finally {
            setSavingId(null);
        }
    }, []);

    return {
        rows: filtered,
        rawRows: rows,

        loading,
        err,
        savingId,

        search,
        setSearch,

        fetchAll,
        create,
        update,
        remove,
    };
}