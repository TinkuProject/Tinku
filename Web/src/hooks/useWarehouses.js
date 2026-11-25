'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useUser } from '@/context/UserContext';
import WarehousesService from '@/services/warehousesService';

function normalizeList(data) {
  if (Array.isArray(data)) return data;
  if (Array.isArray(data?.data)) return data.data;
  if (Array.isArray(data?.items)) return data.items;
  return [];
}

export default function useWarehouses({ autoLoad = true } = {}) {
  const { user } = useUser();
  const role = user?.role || user?.profile?.role || null;
  const canReview = ['admin', 'master'].includes(role);
  const [rows, setRows] = useState([]);
  const [status, setStatus] = useState('pending');
  const [loading, setLoading] = useState(false);
  const [savingId, setSavingId] = useState(null);
  const [error, setError] = useState(null);
  const controllerRef = useRef(null);

  const fetchAll = useCallback(async (nextStatus = status) => {
    if (!canReview) {
      setRows([]);
      return [];
    }

    controllerRef.current?.abort();
    const controller = new AbortController();
    controllerRef.current = controller;
    setLoading(true);
    setError(null);

    try {
      const data = await WarehousesService.listAdmin({
        status: nextStatus,
        signal: controller.signal,
      });
      const list = normalizeList(data);
      setRows(list);
      return list;
    } catch (requestError) {
      if (requestError?.name !== 'AbortError') {
        setRows([]);
        setError(requestError?.message || 'No se pudieron cargar los almacenes.');
      }
      return [];
    } finally {
      if (controllerRef.current === controller) {
        controllerRef.current = null;
        setLoading(false);
      }
    }
  }, [canReview, status]);

  const replace = useCallback((updated) => {
    setRows((previous) => previous.map((row) =>
      String(row?.id) === String(updated?.id) ? updated : row
    ));
  }, []);

  const approveOne = useCallback(async (id, message = '') => {
    setSavingId(id);
    setError(null);
    try {
      const updated = await WarehousesService.approve(id, message);
      replace(updated);
      return updated;
    } catch (requestError) {
      setError(requestError?.message || 'No se pudo aprobar el almacén.');
      return null;
    } finally {
      setSavingId(null);
    }
  }, [replace]);

  const rejectOne = useCallback(async (id, message) => {
    setSavingId(id);
    setError(null);
    try {
      const updated = await WarehousesService.reject(id, message);
      replace(updated);
      return updated;
    } catch (requestError) {
      setError(requestError?.message || 'No se pudo rechazar el almacén.');
      return null;
    } finally {
      setSavingId(null);
    }
  }, [replace]);

  useEffect(() => {
    if (autoLoad) fetchAll();
    return () => controllerRef.current?.abort();
  }, [autoLoad, fetchAll]);

  const warehouses = useMemo(() => [...rows].sort((a, b) =>
    new Date(b?.created_at || 0).getTime() - new Date(a?.created_at || 0).getTime()
  ), [rows]);

  return {
    warehouses, status, setStatus, loading, savingId, error, canReview,
    fetchAll, approveOne, rejectOne,
  };
}
