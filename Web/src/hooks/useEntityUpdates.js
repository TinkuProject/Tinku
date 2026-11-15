// File: src/hooks/useEntityUpdates.js
'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';

import EntityUpdatesService from '@/services/entityUpdatesService';
import EventService from '@/services/eventService';
import { BusinessService } from '@/services/businessService';

function getEntityId(row) {
    return Number(row?.entity_id ?? row?.entityId);
}

function getUpdateId(row) {
    return Number(row?.id ?? row?.update_id ?? row?.updateId);
}

async function fetchCurrentEntity(row) {
    const type = row?.entity_type;
    const id = getEntityId(row);

    if (!type || !id) return null;

    if (type === 'event') {
        return EventService.get(id);
    }

    if (type === 'business') {
        return BusinessService.get(id);
    }

    return null;
}

export default function useEntityUpdates({ autoLoad = true } = {}) {
    const [updates, setUpdates] = useState([]);
    const [currentEntities, setCurrentEntities] = useState({});
    const [loading, setLoading] = useState(false);
    const [savingId, setSavingId] = useState(null);
    const [error, setError] = useState(null);

    const fetchAll = useCallback(async () => {
        setLoading(true);
        setError(null);

        try {
            const rows = await EntityUpdatesService.list();

            setUpdates(rows);

            const entityMap = {};

            await Promise.all(
                rows.map(async (row) => {
                    const type = row?.entity_type;
                    const entityId = getEntityId(row);

                    if (!type || !entityId) return;

                    const key = `${type}:${entityId}`;

                    if (entityMap[key]) return;

                    try {
                        entityMap[key] = await fetchCurrentEntity(row);
                    } catch (err) {
                        console.warn('[useEntityUpdates] entity load:', err);
                        entityMap[key] = null;
                    }
                })
            );

            setCurrentEntities(entityMap);

            return rows;
        } catch (err) {
            console.error('[useEntityUpdates] fetchAll:', err);
            setError(err);
            setUpdates([]);
            setCurrentEntities({});
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const fetchOne = useCallback(async (id) => {
        setLoading(true);
        setError(null);

        try {
            const row = await EntityUpdatesService.get(id);
            const entity = await fetchCurrentEntity(row);

            const key = `${row.entity_type}:${getEntityId(row)}`;

            setUpdates((prev) => {
                const exists = prev.some((item) => getUpdateId(item) === getUpdateId(row));

                if (exists) {
                    return prev.map((item) =>
                        getUpdateId(item) === getUpdateId(row) ? row : item
                    );
                }

                return [row, ...prev];
            });

            setCurrentEntities((prev) => ({
                ...prev,
                [key]: entity,
            }));

            return row;
        } catch (err) {
            console.error('[useEntityUpdates] fetchOne:', err);
            setError(err);
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const approveOne = useCallback(async (id, comment = '') => {
        setSavingId(id);
        setError(null);

        try {
            const result = await EntityUpdatesService.approve(id, comment);

            setUpdates((prev) =>
                prev.map((row) =>
                    getUpdateId(row) === Number(id)
                        ? {
                            ...row,
                            status: 'approved',
                            comment: comment || row.comment,
                            reviewed_at: new Date().toISOString(),
                        }
                        : row
                )
            );

            await fetchAll();

            return result;
        } catch (err) {
            console.error('[useEntityUpdates] approve:', err);
            setError(err);
            throw err;
        } finally {
            setSavingId(null);
        }
    }, [fetchAll]);

    const rejectOne = useCallback(async (id, comment = '') => {
        setSavingId(id);
        setError(null);

        try {
            const result = await EntityUpdatesService.reject(id, comment);

            setUpdates((prev) =>
                prev.map((row) =>
                    getUpdateId(row) === Number(id)
                        ? {
                            ...row,
                            status: 'rejected',
                            comment: comment || row.comment,
                            reviewed_at: new Date().toISOString(),
                        }
                        : row
                )
            );

            await fetchAll();

            return result;
        } catch (err) {
            console.error('[useEntityUpdates] reject:', err);
            setError(err);
            throw err;
        } finally {
            setSavingId(null);
        }
    }, [fetchAll]);

    const pendingUpdates = useMemo(() => {
        return updates.filter((row) => row?.status === 'pending');
    }, [updates]);

    const approvedUpdates = useMemo(() => {
        return updates.filter((row) => row?.status === 'approved');
    }, [updates]);

    const rejectedUpdates = useMemo(() => {
        return updates.filter((row) => row?.status === 'rejected');
    }, [updates]);

    const getCurrentForUpdate = useCallback(
        (row) => {
            const key = `${row?.entity_type}:${getEntityId(row)}`;
            return currentEntities[key] ?? null;
        },
        [currentEntities]
    );

    useEffect(() => {
        if (!autoLoad) return;
        fetchAll();
    }, [autoLoad, fetchAll]);

    return {
        updates,
        currentEntities,

        pendingUpdates,
        approvedUpdates,
        rejectedUpdates,

        loading,
        savingId,
        error,

        fetchAll,
        fetchOne,
        approveOne,
        rejectOne,
        getCurrentForUpdate,
    };
}