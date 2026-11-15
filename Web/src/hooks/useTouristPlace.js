// File: src/hooks/useTouristPlace.js

'use client';

import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';

import { useUser } from '@/context/UserContext';
import { TouristPlaceService } from '@/services/touristPlaceService';
import TagTouristPlaceService from '@/services/tagTouristPlaceService';

function normalizeList(data) {
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
}

function sameId(item, id) {
  return String(item?.id ?? item?._id) === String(id);
}

function isAbortError(error) {
  return (
    error?.name === 'AbortError' ||
    error?.code === 'ABORT_ERR' ||
    error === 'cancelled-by-hook' ||
    error?.message === 'cancelled-by-hook' ||
    error?.message === 'The operation was aborted.'
  );
}

function getErrorMessage(error, fallback) {
  if (error?.status === 401) {
    return 'Tu sesión no es válida o ha expirado.';
  }

  if (error?.status === 403) {
    return 'No tienes permisos para realizar esta acción.';
  }

  if (error?.status === 404) {
    return 'El recurso solicitado no fue encontrado.';
  }

  return error?.message || fallback;
}

export default function useTouristPlace({
  autoLoad = false,
  filters: initialFilters = {},
  adminMode = false,
} = {}) {
  const { user: currentUser } = useUser();

  const currentRole =
    currentUser?.role ||
    currentUser?.profile?.role ||
    null;

  const canManage =
    currentRole === 'admin' ||
    currentRole === 'master';

  const [places, setPlaces] = useState([]);
  const [current, setCurrent] = useState(null);
  const [placeTags, setPlaceTags] = useState({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState(initialFilters);

  const abortRef = useRef(null);
  const mountedRef = useRef(true);

  const abortActive = useCallback(() => {
    if (!abortRef.current) {
      return;
    }

    /*
     * Abort estándar, sin motivo personalizado.
     * Así fetch genera un AbortError reconocible.
     */
    abortRef.current.abort();
    abortRef.current = null;
  }, []);

  const logWarning = useCallback((scope, requestError) => {
    console.warn(`[useTouristPlace] ${scope}:`, {
      message: requestError?.message || String(requestError || ''),
      status: requestError?.status || null,
      code: requestError?.code || null,
    });
  }, []);

  const wrap = useCallback(
    async (fn, fallbackMessage = 'Ocurrió un error inesperado.') => {
      abortActive();

      const controller = new AbortController();
      abortRef.current = controller;

      if (mountedRef.current) {
        setLoading(true);
        setError(null);
      }

      try {
        return await fn(controller.signal);
      } catch (requestError) {
        if (isAbortError(requestError) || controller.signal.aborted) {
          return undefined;
        }

        logWarning('request', requestError);

        if (mountedRef.current) {
          setError(
            getErrorMessage(
              requestError,
              fallbackMessage
            )
          );
        }

        /*
         * No relanzamos el error.
         * Las acciones retornan undefined y evitan
         * Uncaught (in promise).
         */
        return undefined;
      } finally {
        if (abortRef.current === controller) {
          abortRef.current = null;

          if (mountedRef.current) {
            setLoading(false);
          }
        }
      }
    },
    [abortActive, logWarning]
  );

  // =====================================================
  // FETCH ALL
  // =====================================================

  const fetchAll = useCallback(
    async (nextFilters) => {
      /*
       * En modo administrativo, user y partner
       * no deben ejecutar endpoints protegidos.
       */
      if (adminMode && !canManage) {
        setPlaces([]);
        setError(null);
        setLoading(false);
        return [];
      }

      const appliedFilters = {
        ...filters,
        ...(nextFilters || {}),
      };

      const data = await wrap(
        async (signal) => {
          if (appliedFilters.category_id) {
            return TouristPlaceService.getByCategory(
              appliedFilters.category_id,
              { signal }
            );
          }

          /*
           * Si tu service posee listAdmin, úsalo cuando
           * adminMode sea true.
           */
          if (
            adminMode &&
            typeof TouristPlaceService.listAdmin === 'function'
          ) {
            return TouristPlaceService.listAdmin(
              appliedFilters,
              { signal }
            );
          }

          return TouristPlaceService.list(
            appliedFilters,
            { signal }
          );
        },
        'No se pudieron cargar los lugares turísticos.'
      );

      if (data === undefined) {
        return [];
      }

      const list = normalizeList(data);

      if (mountedRef.current) {
        setPlaces(list);
      }

      return list;
    },
    [
      adminMode,
      canManage,
      filters,
      wrap,
    ]
  );

  // =====================================================
  // FETCH ONE
  // =====================================================

  const fetchOne = useCallback(
    async (id) => {
      if (!id) {
        setError('El identificador es obligatorio.');
        return null;
      }

      const data = await wrap(
        (signal) =>
          TouristPlaceService.get(id, { signal }),
        'No se pudo cargar el lugar turístico.'
      );

      if (data === undefined) {
        return null;
      }

      if (mountedRef.current) {
        setCurrent(data);
      }

      return data;
    },
    [wrap]
  );

  // =====================================================
  // CREATE
  // =====================================================

  const createOne = useCallback(
    async (payload, tagIds = []) => {
      if (!canManage) {
        setError(
          'No tienes permisos para crear lugares turísticos.'
        );
        return null;
      }

      const created = await wrap(
        (signal) =>
          TouristPlaceService.create(payload, { signal }),
        'No se pudo crear el lugar turístico.'
      );

      if (!created) {
        return null;
      }

      const placeId =
        created?.id ??
        created?.data?.id ??
        created?.place?.id;

      if (placeId && Array.isArray(tagIds)) {
        try {
          await TagTouristPlaceService.replaceTags(
            placeId,
            tagIds
          );

          if (mountedRef.current) {
            setPlaceTags((previous) => ({
              ...previous,
              [String(placeId)]: tagIds,
            }));
          }
        } catch (tagError) {
          logWarning('create tags', tagError);

          if (mountedRef.current) {
            setError(
              getErrorMessage(
                tagError,
                'El lugar fue creado, pero no se pudieron asignar las etiquetas.'
              )
            );
          }
        }
      }

      if (mountedRef.current) {
        setPlaces((previous) => [
          created,
          ...(Array.isArray(previous) ? previous : []),
        ]);
      }

      return created;
    },
    [canManage, logWarning, wrap]
  );

  // =====================================================
  // UPDATE
  // =====================================================

  const updateOne = useCallback(
    async (id, payload, tagIds) => {
      if (!canManage) {
        setError(
          'No tienes permisos para actualizar lugares turísticos.'
        );
        return null;
      }

      if (!id) {
        setError('El identificador es obligatorio.');
        return null;
      }

      const updated = await wrap(
        (signal) =>
          TouristPlaceService.update(
            id,
            payload,
            { signal }
          ),
        'No se pudo actualizar el lugar turístico.'
      );

      if (!updated) {
        return null;
      }

      if (Array.isArray(tagIds)) {
        try {
          await TagTouristPlaceService.replaceTags(
            id,
            tagIds
          );

          if (mountedRef.current) {
            setPlaceTags((previous) => ({
              ...previous,
              [String(id)]: tagIds,
            }));
          }
        } catch (tagError) {
          logWarning('update tags', tagError);

          if (mountedRef.current) {
            setError(
              getErrorMessage(
                tagError,
                'El lugar fue actualizado, pero no se pudieron actualizar las etiquetas.'
              )
            );
          }
        }
      }

      if (mountedRef.current) {
        setPlaces((previous) =>
          previous.map((place) =>
            sameId(place, id) ? updated : place
          )
        );

        setCurrent((previous) =>
          previous && sameId(previous, id)
            ? updated
            : previous
        );
      }

      return updated;
    },
    [canManage, logWarning, wrap]
  );

  // =====================================================
  // ARCHIVE
  // =====================================================

  const archiveOne = useCallback(
    async (id) => {
      if (!canManage) {
        setError(
          'No tienes permisos para archivar lugares turísticos.'
        );
        return null;
      }

      if (!id) {
        setError('El identificador es obligatorio.');
        return null;
      }

      const updated = await wrap(
        (signal) =>
          TouristPlaceService.archive(id, { signal }),
        'No se pudo archivar el lugar turístico.'
      );

      if (!updated) {
        return null;
      }

      if (mountedRef.current) {
        setPlaces((previous) =>
          previous.map((place) =>
            sameId(place, id) ? updated : place
          )
        );

        setCurrent((previous) =>
          previous && sameId(previous, id)
            ? updated
            : previous
        );
      }

      return updated;
    },
    [canManage, wrap]
  );

  // =====================================================
  // STATUS
  // =====================================================

  const setStatus = useCallback(
    async (id, status) => {
      if (!canManage) {
        setError(
          'No tienes permisos para modificar el estado.'
        );
        return null;
      }

      if (!id) {
        setError('El identificador es obligatorio.');
        return null;
      }

      const updated = await wrap(
        (signal) =>
          TouristPlaceService.update(
            id,
            { status },
            { signal }
          ),
        'No se pudo modificar el estado.'
      );

      if (!updated) {
        return null;
      }

      if (mountedRef.current) {
        setPlaces((previous) =>
          previous.map((place) =>
            sameId(place, id) ? updated : place
          )
        );

        setCurrent((previous) =>
          previous && sameId(previous, id)
            ? updated
            : previous
        );
      }

      return updated;
    },
    [canManage, wrap]
  );

  // =====================================================
  // TAGS
  // =====================================================

  const fetchTagsByPlace = useCallback(
    async (placeId) => {
      if (!placeId) {
        return [];
      }

      try {
        const data =
          await TagTouristPlaceService.getByPlace(
            placeId
          );

        const list = normalizeList(data);

        if (mountedRef.current) {
          setPlaceTags((previous) => ({
            ...previous,
            [String(placeId)]: list,
          }));
        }

        return list;
      } catch (tagError) {
        logWarning('fetch tags', tagError);

        if (mountedRef.current) {
          setError(
            getErrorMessage(
              tagError,
              'No se pudieron cargar las etiquetas.'
            )
          );
        }

        return [];
      }
    },
    [logWarning]
  );

  const fetchPlacesByTag = useCallback(
    async (tagId) => {
      if (!tagId) {
        return [];
      }

      const data = await wrap(
        () =>
          TagTouristPlaceService.getByTag(tagId),
        'No se pudieron cargar los lugares por etiqueta.'
      );

      return data === undefined
        ? []
        : normalizeList(data);
    },
    [wrap]
  );

  const replaceTags = useCallback(
    async (placeId, tagIds = []) => {
      if (!canManage) {
        setError(
          'No tienes permisos para modificar etiquetas.'
        );
        return null;
      }

      try {
        const result =
          await TagTouristPlaceService.replaceTags(
            placeId,
            tagIds
          );

        if (mountedRef.current) {
          setPlaceTags((previous) => ({
            ...previous,
            [String(placeId)]: tagIds,
          }));
        }

        return result;
      } catch (tagError) {
        logWarning('replace tags', tagError);

        if (mountedRef.current) {
          setError(
            getErrorMessage(
              tagError,
              'No se pudieron actualizar las etiquetas.'
            )
          );
        }

        return null;
      }
    },
    [canManage, logWarning]
  );

  // =====================================================
  // AUTO LOAD / CLEANUP
  // =====================================================

  useEffect(() => {
    mountedRef.current = true;

    if (autoLoad) {
      if (!adminMode || canManage) {
        fetchAll();
      }
    }

    return () => {
      mountedRef.current = false;
      abortActive();
    };
  }, [
    autoLoad,
    adminMode,
    canManage,
    fetchAll,
    abortActive,
  ]);

  // =====================================================
  // RETURN
  // =====================================================

  const state = useMemo(
    () => ({
      places,
      items: places,
      current,
      placeTags,
      loading,
      error,
      filters,
      currentRole,
      canManage,
    }),
    [
      places,
      current,
      placeTags,
      loading,
      error,
      filters,
      currentRole,
      canManage,
    ]
  );

  const actions = useMemo(
    () => ({
      fetchAll,
      fetchOne,
      createOne,
      updateOne,
      archiveOne,

      // Alias para componentes antiguos
      deleteOne: archiveOne,

      setStatus,
      fetchTagsByPlace,
      fetchPlacesByTag,
      replaceTags,
      setFilters,
      clearError: () => setError(null),
    }),
    [
      fetchAll,
      fetchOne,
      createOne,
      updateOne,
      archiveOne,
      setStatus,
      fetchTagsByPlace,
      fetchPlacesByTag,
      replaceTags,
    ]
  );

  return {
    ...state,
    ...actions,
  };
}