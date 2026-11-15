// File: src/hooks/useRoutePoints.js
'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import RoutePointsService from '@/services/routePointsService';

function normalizeDirection(direction) {
  const value = String(direction || '').toLowerCase();

  if (value === 'outbound' || value === 'ida' || value === 'out') return 'outbound';
  if (value === 'return' || value === 'vuelta' || value === 'back') return 'return';

  return value;
}

function parsePoint(row) {
  if (!row) return { lat: NaN, lng: NaN };

  const loc = row.location;

  if (loc && typeof loc === 'object') {
    if (Array.isArray(loc.coordinates)) {
      const [lng, lat] = loc.coordinates.map(Number);
      return { lat, lng };
    }

    const lat = Number(loc.latitude ?? loc.lat);
    const lng = Number(loc.longitude ?? loc.lng);

    if (Number.isFinite(lat) && Number.isFinite(lng)) {
      return { lat, lng };
    }
  }

  if (typeof loc === 'string') {
    const match = loc.match(
      /POINT\s*\(\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*\)/i
    );

    if (match) {
      return {
        lng: Number(match[1]),
        lat: Number(match[2]),
      };
    }
  }

  const lat = Number(row.latitude ?? row.lat);
  const lng = Number(row.longitude ?? row.lng);

  return { lat, lng };
}

function normalizeList(data) {
  if (Array.isArray(data)) return data;
  if (Array.isArray(data?.data)) return data.data;
  if (Array.isArray(data?.items)) return data.items;
  return [];
}

function normalizeRow(row) {
  const point = parsePoint(row);

  return {
    ...row,
    ...point,
    direction: normalizeDirection(row.direction),
    stop_order: Number(row.stop_order ?? row.route_order ?? 0),
  };
}

export default function useRoutePoints({
  autoLoad = false,
  lineId,
  direction,
} = {}) {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);
  const [savingId, setSavingId] = useState(null);
  const [err, setErr] = useState('');

  const abortRef = useRef(null);

  const abortPrev = useCallback(() => {
    if (abortRef.current) {
      try {
        abortRef.current.abort();
      } catch { }
      abortRef.current = null;
    }
  }, []);

  const sortByOrder = useCallback((list = []) => {
    return [...list].sort(
      (a, b) => Number(a.stop_order ?? 0) - Number(b.stop_order ?? 0)
    );
  }, []);

  const fetchAll = useCallback(async () => {
    abortPrev();

    if (!lineId) {
      setRows([]);
      return [];
    }

    setLoading(true);
    setErr('');

    const controller = new AbortController();
    abortRef.current = controller;

    try {
      const data = direction
        ? await RoutePointsService.getByLineAndDirection(
          lineId,
          normalizeDirection(direction),
          { signal: controller.signal }
        )
        : await RoutePointsService.getByLine(lineId, {
          signal: controller.signal,
        });

      const normalized = normalizeList(data).map(normalizeRow);
      const sorted = sortByOrder(normalized);

      setRows(sorted);

      return sorted;
    } catch (e) {
      if (e?.name !== 'AbortError') {
        setErr(e?.message || 'No se pudo cargar la ruta');
      }

      return [];
    } finally {
      setLoading(false);
      abortRef.current = null;
    }
  }, [abortPrev, lineId, direction, sortByOrder]);

  const fetchByLine = useCallback(
    async (transportLineId, routeDirection) => {
      setLoading(true);
      setErr('');

      try {
        const data = routeDirection
          ? await RoutePointsService.getByLineAndDirection(
            transportLineId,
            normalizeDirection(routeDirection)
          )
          : await RoutePointsService.getByLine(transportLineId);

        const normalized = normalizeList(data).map(normalizeRow);
        const sorted = sortByOrder(normalized);

        setRows(sorted);

        return sorted;
      } catch (e) {
        setErr(e?.message || 'No se pudo cargar la ruta');
        return [];
      } finally {
        setLoading(false);
      }
    },
    [sortByOrder]
  );

  const createOne = useCallback(
    async (payload) => {
      setSavingId('new');
      setErr('');

      try {
        const created = await RoutePointsService.create(payload);
        const parsed = normalizeRow(created);

        setRows((prev) => sortByOrder([...(prev || []), parsed]));

        return parsed;
      } catch (e) {
        setErr(e?.message || 'No se pudo crear el punto');
        throw e;
      } finally {
        setSavingId(null);
      }
    },
    [sortByOrder]
  );

  const createBulk = useCallback(
    async (items = []) => {
      setSavingId('bulk');
      setErr('');

      try {
        const created = await RoutePointsService.createBulk(items);
        const normalized = normalizeList(created).map(normalizeRow);
        const sorted = sortByOrder(normalized);

        setRows(sorted);

        return sorted;
      } catch (e) {
        setErr(e?.message || 'No se pudo guardar la ruta');
        throw e;
      } finally {
        setSavingId(null);
      }
    },
    [sortByOrder]
  );

  const remove = useCallback(async (id) => {
    if (!id) throw new Error('id is required');

    setSavingId(id);
    setErr('');

    try {
      await RoutePointsService.remove(id);

      setRows((prev) =>
        (prev || []).filter((row) => Number(row.id) !== Number(id))
      );
    } catch (e) {
      setErr(e?.message || 'No se pudo eliminar el punto');
      throw e;
    } finally {
      setSavingId(null);
    }
  }, []);

  const clearLocal = useCallback(() => {
    setRows([]);
    setErr('');
  }, []);

  const outbound = useMemo(
    () => rows.filter((row) => normalizeDirection(row.direction) === 'outbound'),
    [rows]
  );

  const ret = useMemo(
    () => rows.filter((row) => normalizeDirection(row.direction) === 'return'),
    [rows]
  );

  useEffect(() => {
    if (autoLoad) fetchAll();

    return abortPrev;
  }, [autoLoad, fetchAll, abortPrev]);

  return {
    rows,
    outbound,
    return: ret,

    loading,
    savingId,
    err,

    fetchAll,
    fetchByLine,

    createOne,
    createBulk,

    remove,
    clearLocal,
  };
}