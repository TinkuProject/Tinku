// src/hooks/useMedia.js
'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import mediaService from '@/services/mediaService';

const normalizeId = (v) =>
  v === undefined || v === null ? '' : String(v);

export default function useMedia(options = {}) {
  const { autoLoad = false, entity_type, entity_id } = options;

  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(!!autoLoad);
  const [error, setError] = useState(null);

  const reqRef = useRef(null);

  const abortActive = () => {
    if (reqRef.current) {
      try {
        reqRef.current.abort();
      } catch { }

      reqRef.current = null;
    }
  };

  const fetchAll = useCallback(
    async (filters) => {
      abortActive();

      const controller = new AbortController();
      reqRef.current = controller;

      setLoading(true);
      setError(null);

      try {
        const eType =
          filters?.entity_type ??
          entity_type;

        const eId =
          filters?.entity_id ??
          entity_id;

        let data = [];

        if (eType && eId !== undefined && eId !== null) {
          data = await mediaService.listByEntity(
            eType,
            eId,
            { signal: controller.signal }
          );
        } else {
          data = await mediaService.getAll({
            signal: controller.signal,
          });
        }

        setItems(Array.isArray(data) ? data : []);
      } catch (e) {
        if (e.name !== 'AbortError') {
          setError(e);
        }
      } finally {
        setLoading(false);
        reqRef.current = null;
      }
    },
    [entity_type, entity_id]
  );

  const createOne = useCallback(async (payload) => {
    setError(null);

    const created = await mediaService.create(payload);

    setItems((prev) => [created, ...prev]);

    return created;
  }, []);

  const updateOne = useCallback(async (id, patch) => {
    setError(null);

    const updated = await mediaService.update(id, patch);

    setItems((prev) =>
      prev.map((m) =>
        normalizeId(m.id) === normalizeId(id)
          ? { ...m, ...updated }
          : m
      )
    );

    return updated;
  }, []);

  const removeOne = useCallback(async (id) => {
    setError(null);

    await mediaService.remove(id);

    setItems((prev) =>
      prev.filter((m) => normalizeId(m.id) !== normalizeId(id))
    );
  }, []);

  const getUrlsFor = useCallback(
    (eid) => {
      const idStr = normalizeId(eid);

      return items
        .filter(
          (m) =>
            normalizeId(
              m.entity_id ??
              m.target_id
            ) === idStr
        )
        .map((m) => m.url)
        .filter(Boolean);
    },
    [items]
  );

  const multiReqRef = useRef(null);

  const fetchForBusinessIds = useCallback(
    async (ids = [], eType = 'business') => {
      if (multiReqRef.current) {
        multiReqRef.current = null;
      }

      const controller = new AbortController();
      multiReqRef.current = controller;

      const uniqueIds = [
        ...new Set(ids.map(Number).filter((n) => Number.isFinite(n))),
      ];

      if (!uniqueIds.length) return new Map();

      try {
        const response = await mediaService.getByEntities(eType, uniqueIds, {
          signal: controller.signal,
        });

        console.log('MEDIA RESPONSE:', response);

        const grouped = new Map();

        uniqueIds.forEach((id) => grouped.set(id, []));

        // Caso 1: API devuelve array
        if (Array.isArray(response)) {
          response.forEach((m) => {
            const id = Number(m.entity_id ?? m.target_id ?? m.targetId);
            if (!grouped.has(id)) grouped.set(id, []);
            grouped.get(id).push(m);
          });
        }

        // Caso 2: API devuelve { data: [...] }
        else if (Array.isArray(response?.data)) {
          response.data.forEach((m) => {
            const id = Number(m.entity_id ?? m.target_id ?? m.targetId);
            if (!grouped.has(id)) grouped.set(id, []);
            grouped.get(id).push(m);
          });
        }

        // Caso 3: API devuelve objeto agrupado { "1": [...], "2": [...] }
        else if (response && typeof response === 'object') {
          Object.entries(response).forEach(([id, arr]) => {
            grouped.set(Number(id), Array.isArray(arr) ? arr : []);
          });
        }

        const merged = Array.from(grouped.values()).flat();

        setItems(merged);

        return grouped;
      } catch (e) {
        if (e?.name !== 'AbortError') {
          console.error('ERROR FETCH MEDIA:', e);
          setError(e);
        }

        return new Map(uniqueIds.map((id) => [id, []]));
      } finally {
        multiReqRef.current = null;
      }
    },
    []
  );

  useEffect(() => {
    if (!autoLoad) return;

    fetchAll();

    return abortActive;

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [autoLoad, entity_type, entity_id]);

  return {
    items,
    loading,
    error,

    fetchAll,
    createOne,
    updateOne,
    removeOne,

    getUrlsFor,
    fetchForBusinessIds,
  };
}