// File: src/hooks/useBusiness.js

import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';

import BusinessService from '@/services/businessService';

export default function useBusiness({
  autoLoad = false,
  filters: initialFilters = {},
} = {}) {
  const [businesses, setBusinesses] = useState([]);
  const [current, setCurrent] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState(initialFilters);

  const abortRef = useRef(null);

  // ========================================
  // CANCELAR PETICIÓN ACTIVA
  // ========================================

  const abortActive = useCallback(() => {
    if (abortRef.current) {
      abortRef.current.abort();
      abortRef.current = null;
    }
  }, []);

  // ========================================
  // EJECUTAR PETICIONES
  // ========================================

  const wrap = useCallback(
    async (fn) => {
      abortActive();

      const controller = new AbortController();
      abortRef.current = controller;

      setLoading(true);
      setError(null);

      try {
        return await fn(controller.signal);
      } catch (err) {
        if (err?.name === 'AbortError') {
          return undefined;
        }

        setError(err);
        throw err;
      } finally {
        if (abortRef.current === controller) {
          abortRef.current = null;
          setLoading(false);
        }
      }
    },
    [abortActive]
  );

  // ========================================
  // HELPERS DE ESTADO
  // ========================================

  const sameId = useCallback((business, id) => {
    return String(business?.id ?? business?._id) === String(id);
  }, []);

  const normalizeList = useCallback((data) => {
    if (Array.isArray(data)) {
      return data;
    }

    if (Array.isArray(data?.items)) {
      return data.items;
    }

    if (Array.isArray(data?.data)) {
      return data.data;
    }

    return [];
  }, []);

  const replaceOneInList = useCallback(
    (id, business) => {
      setBusinesses((previous) => {
        if (!Array.isArray(previous)) {
          return previous;
        }

        return previous.map((item) =>
          sameId(item, id) ? business : item
        );
      });
    },
    [sameId]
  );

  const prependOneToList = useCallback((business) => {
    setBusinesses((previous) => {
      if (!Array.isArray(previous)) {
        return [business];
      }

      const alreadyExists = previous.some(
        (item) =>
          String(item?.id ?? item?._id) ===
          String(business?.id ?? business?._id)
      );

      if (alreadyExists) {
        return previous.map((item) =>
          String(item?.id ?? item?._id) ===
            String(business?.id ?? business?._id)
            ? business
            : item
        );
      }

      return [business, ...previous];
    });
  }, []);

  // ========================================
  // OBTENER TODOS
  // ========================================

  const fetchAll = useCallback(
    async (nextFilters = {}) => {
      const appliedFilters = {
        ...filters,
        ...nextFilters,
      };

      const data = await wrap((signal) => {
        if (appliedFilters.category_id) {
          return BusinessService.getByCategory(
            appliedFilters.category_id,
            { signal }
          );
        }

        return BusinessService.list({ signal });
      });

      if (data !== undefined) {
        setBusinesses(normalizeList(data));
      }

      return data;
    },
    [filters, normalizeList, wrap]
  );

  // ========================================
  // OBTENER UNO
  // ========================================

  const fetchOne = useCallback(
    async (id) => {
      if (!id) {
        throw new Error('El ID del negocio es requerido');
      }

      const data = await wrap((signal) =>
        BusinessService.getById(id, { signal })
      );

      if (data !== undefined) {
        setCurrent(data);
      }

      return data;
    },
    [wrap]
  );

  // ========================================
  // OBTENER NEGOCIOS DEL USUARIO
  // ========================================

  const fetchMine = useCallback(async () => {
    const data = await wrap((signal) =>
      BusinessService.getMine({ signal })
    );

    if (data !== undefined) {
      setBusinesses(normalizeList(data));
    }

    return data;
  }, [normalizeList, wrap]);

  // ========================================
  // OBTENER POR ESTADO
  // ========================================

  const fetchByStatus = useCallback(
    async (status) => {
      if (!status) {
        throw new Error('El estado del negocio es requerido');
      }

      const data = await wrap((signal) =>
        BusinessService.getByStatus(status, { signal })
      );

      if (data !== undefined) {
        setBusinesses(normalizeList(data));
      }

      return data;
    },
    [normalizeList, wrap]
  );

  // ========================================
  // CREAR NEGOCIO ASOCIADO AL USUARIO
  // ========================================

  const createOne = useCallback(
    async (payload) => {
      if (!payload || typeof payload !== 'object') {
        throw new Error('Los datos del negocio son requeridos');
      }

      const created = await wrap((signal) =>
        BusinessService.createOwned(payload, { signal })
      );

      if (created !== undefined) {
        prependOneToList(created);
        setCurrent(created);
      }

      return created;
    },
    [prependOneToList, wrap]
  );

  // ========================================
  // CREAR NEGOCIO DESDE EL SISTEMA
  // ADMIN / MASTER
  // ========================================

  const createSystemOne = useCallback(
    async (payload) => {
      if (!payload || typeof payload !== 'object') {
        throw new Error('Los datos del negocio son requeridos');
      }

      const created = await wrap((signal) =>
        BusinessService.createSystem(payload, { signal })
      );

      if (created !== undefined) {
        prependOneToList(created);
        setCurrent(created);
      }

      return created;
    },
    [prependOneToList, wrap]
  );

  // ========================================
  // ACTUALIZAR
  // ========================================

  const updateOne = useCallback(
    async (id, payload) => {
      if (!id) {
        throw new Error('El ID del negocio es requerido');
      }

      if (!payload || typeof payload !== 'object') {
        throw new Error('Los datos del negocio son requeridos');
      }

      const updated = await wrap((signal) =>
        BusinessService.update(id, payload, { signal })
      );

      if (updated !== undefined) {
        replaceOneInList(id, updated);

        setCurrent((previous) =>
          previous && sameId(previous, id)
            ? updated
            : previous
        );
      }

      return updated;
    },
    [replaceOneInList, sameId, wrap]
  );

  // ========================================
  // VALIDAR / APROBAR
  // ========================================

  const validateOne = useCallback(
    async (id, message = '') => {
      if (!id) {
        throw new Error('El ID del negocio es requerido');
      }

      const updated = await wrap((signal) =>
        BusinessService.validate(id, message, { signal })
      );

      if (updated !== undefined) {
        replaceOneInList(id, updated);

        setCurrent((previous) =>
          previous && sameId(previous, id)
            ? updated
            : previous
        );
      }

      return updated;
    },
    [replaceOneInList, sameId, wrap]
  );

  // ========================================
  // RECHAZAR
  // ========================================

  const rejectOne = useCallback(
    async (id, message = '') => {
      if (!id) {
        throw new Error('El ID del negocio es requerido');
      }

      const updated = await wrap((signal) =>
        BusinessService.reject(id, message, { signal })
      );

      if (updated !== undefined) {
        replaceOneInList(id, updated);

        setCurrent((previous) =>
          previous && sameId(previous, id)
            ? updated
            : previous
        );
      }

      return updated;
    },
    [replaceOneInList, sameId, wrap]
  );

  // ========================================
  // ELIMINAR LÓGICAMENTE
  // ========================================

  const deleteOne = useCallback(
    async (id) => {
      if (!id) {
        throw new Error('El ID del negocio es requerido');
      }

      const deleted = await wrap((signal) =>
        BusinessService.softDelete(id, { signal })
      );

      if (deleted !== undefined) {
        /*
         * El backend realiza eliminación lógica y devuelve
         * el negocio con status "inactive".
         *
         * Lo reemplazamos en la lista para mantener el estado
         * sincronizado con la base de datos.
         */
        replaceOneInList(id, deleted);

        setCurrent((previous) =>
          previous && sameId(previous, id)
            ? deleted
            : previous
        );
      }

      return deleted;
    },
    [replaceOneInList, sameId, wrap]
  );

  // ========================================
  // QUITAR NEGOCIO LOCALMENTE
  // ========================================

  const removeOneFromState = useCallback(
    (id) => {
      setBusinesses((previous) =>
        Array.isArray(previous)
          ? previous.filter((business) => !sameId(business, id))
          : previous
      );

      setCurrent((previous) =>
        previous && sameId(previous, id)
          ? null
          : previous
      );
    },
    [sameId]
  );

  // ========================================
  // LIMPIAR ESTADOS
  // ========================================

  const clearCurrent = useCallback(() => {
    setCurrent(null);
  }, []);

  const clearError = useCallback(() => {
    setError(null);
  }, []);

  const reset = useCallback(() => {
    abortActive();
    setBusinesses([]);
    setCurrent(null);
    setLoading(false);
    setError(null);
    setFilters(initialFilters);
  }, [abortActive, initialFilters]);

  // ========================================
  // AUTO LOAD
  // ========================================

  useEffect(() => {
    if (autoLoad) {
      fetchAll();
    }

    return () => {
      abortActive();
    };
  }, [autoLoad, abortActive, fetchAll]);

  // ========================================
  // STATE
  // ========================================

  const state = useMemo(
    () => ({
      businesses,
      current,
      loading,
      error,
      filters,
    }),
    [
      businesses,
      current,
      loading,
      error,
      filters,
    ]
  );

  // ========================================
  // ACTIONS
  // ========================================

  const actions = useMemo(
    () => ({
      fetchAll,
      fetchOne,
      fetchMine,
      fetchByStatus,

      createOne,
      createSystemOne,

      updateOne,
      validateOne,
      rejectOne,
      deleteOne,

      removeOneFromState,
      clearCurrent,
      clearError,
      reset,
      setFilters,
      setBusinesses,
      setCurrent,
    }),
    [
      fetchAll,
      fetchOne,
      fetchMine,
      fetchByStatus,
      createOne,
      createSystemOne,
      updateOne,
      validateOne,
      rejectOne,
      deleteOne,
      removeOneFromState,
      clearCurrent,
      clearError,
      reset,
    ]
  );

  return {
    ...state,
    ...actions,
  };
}