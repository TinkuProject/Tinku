// src/hooks/useTransportLines.js
'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import toast from 'react-hot-toast';

import TransportLinesService, {
  buildTransportLinePayload,
} from '@/services/transportLinesService';

import VehicleTypesService from '@/services/vehicleTypesService';

import { uploadImages } from '@/services/storageService';
import mediaService from '@/services/mediaService';


export default function useTransportLines() {
  const [allRows, setAllRows] = useState([]);
  const [vehicleTypes, setVehicleTypes] = useState([]);

  const [loading, setLoading] = useState(true);
  const [loadingVehicleTypes, setLoadingVehicleTypes] = useState(true);

  const [err, setErr] = useState('');
  const [savingId, setSavingId] = useState(null);

  const [search, setSearch] = useState('');
  const [vehicleTypeFilter, setVehicleTypeFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');

  const normalizeList = (data) => {
    if (Array.isArray(data)) return data;

    if (Array.isArray(data?.data)) return data.data;

    if (Array.isArray(data?.items)) return data.items;

    return [];
  };

  const loadVehicleTypes = useCallback(async () => {
    setLoadingVehicleTypes(true);

    try {
      const data = await VehicleTypesService.list();

      setVehicleTypes(normalizeList(data));
    } catch (e) {
      console.error('[useTransportLines] vehicle types:', e);

      setVehicleTypes([]);

      toast.error(
        'No se pudieron cargar los tipos de vehículo'
      );
    } finally {
      setLoadingVehicleTypes(false);
    }
  }, []);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    setErr('');

    try {
      const data = await TransportLinesService.list();

      const lines = normalizeList(data);

      const ids = lines
        .map((line) => Number(line.id))
        .filter((id) => Number.isFinite(id));

      let mediaMap = {};

      if (ids.length > 0) {
        mediaMap = await mediaService.getByEntities('transport_line', ids);
      }

      const withMedia = lines.map((line) => ({
        ...line,
        media: mediaMap?.[line.id] || [],
      }));

      setAllRows(withMedia);
    } catch (e) {
      setErr(
        e?.message ||
        'Error al cargar líneas'
      );

      toast.error(
        'Error al cargar líneas'
      );

      setAllRows([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAll();
    loadVehicleTypes();
  }, [fetchAll, loadVehicleTypes]);

  const vehicleTypeMap = useMemo(() => {
    const map = {};

    vehicleTypes.forEach((type) => {
      map[String(type.id)] = type;
    });

    return map;
  }, [vehicleTypes]);

  const rowsWithVehicleType =
    useMemo(() => {
      return allRows.map((row) => {
        const vehicleType =
          vehicleTypeMap[
          String(row.vehicle_type_id)
          ];

        return {
          ...row,

          vehicle_type_name:
            row.vehicle_type_name ||
            vehicleType?.name ||
            '—',
        };
      });
    }, [allRows, vehicleTypeMap]);

  const filtered = useMemo(() => {
    let data = [...rowsWithVehicleType];

    const term = search
      .trim()
      .toLowerCase();

    if (term) {
      data = data.filter((row) =>
        [
          row.id,
          row.name,
          row.status,
          row.vehicle_type_id,
          row.vehicle_type_name,
        ]
          .map((x) =>
            String(x || '').toLowerCase()
          )
          .some((v) => v.includes(term))
      );
    }

    if (vehicleTypeFilter !== 'all') {
      data = data.filter(
        (row) =>
          Number(row.vehicle_type_id) ===
          Number(vehicleTypeFilter)
      );
    }

    if (statusFilter !== 'all') {
      data = data.filter(
        (row) =>
          row.status === statusFilter
      );
    }

    return data;
  }, [
    rowsWithVehicleType,
    search,
    vehicleTypeFilter,
    statusFilter,
  ]);

  // =====================================================
  // CREATE
  // =====================================================

  const create = useCallback(
    async (values, files = {}) => {
      const payload =
        buildTransportLinePayload(values);

      if (!payload.name) {
        toast.error(
          'El nombre es obligatorio'
        );

        return false;
      }

      if (
        !payload.vehicle_type_id ||
        Number.isNaN(
          payload.vehicle_type_id
        )
      ) {
        toast.error(
          'Selecciona un tipo de vehículo'
        );

        return false;
      }

      const toastId =
        toast.loading('Creando línea…');

      try {
        const created =
          await TransportLinesService.create(
            payload
          );

        const uploadList = [];

        if (files.logoFile) {
          uploadList.push(
            files.logoFile
          );
        }

        if (files.vehiclePhotoFile) {
          uploadList.push(
            files.vehiclePhotoFile
          );
        }

        if (uploadList.length > 0) {
          await uploadImages(uploadList, {
            entityType:
              'transport_line',

            entityId: created.id,
          });
        }

        toast.success(
          'Línea creada',
          {
            id: toastId,
          }
        );

        await fetchAll();

        return true;
      } catch (e) {
        toast.error(
          e?.message ||
          'No se pudo crear',
          {
            id: toastId,
          }
        );

        return false;
      }
    },
    [fetchAll]
  );

  // =====================================================
  // UPDATE
  // =====================================================

  const update = useCallback(
    async (id, values, files = {}) => {
      if (!id) {
        toast.error('ID inválido');
        return false;
      }

      const payload = buildTransportLinePayload(values);

      if (!payload.name) {
        toast.error('El nombre es obligatorio');
        return false;
      }

      if (!payload.vehicle_type_id || Number.isNaN(payload.vehicle_type_id)) {
        toast.error('Selecciona un tipo de vehículo');
        return false;
      }

      setSavingId(id);

      const toastId = toast.loading('Guardando cambios…');

      try {
        await TransportLinesService.update(id, payload);

        const uploadList = [];

        if (files.logoFile) uploadList.push(files.logoFile);
        if (files.vehiclePhotoFile) uploadList.push(files.vehiclePhotoFile);

        if (uploadList.length > 0) {
          await uploadImages(uploadList, {
            entityType: 'transport_line',
            entityId: id,
          });
        }

        toast.success('Línea actualizada', { id: toastId });

        await fetchAll();

        return true;
      } catch (e) {
        toast.error(e?.message || 'No se pudo actualizar', { id: toastId });
        return false;
      } finally {
        setSavingId(null);
      }
    },
    [fetchAll]
  );

  // =====================================================
  // UPDATE NAME
  // =====================================================

  const updateName = useCallback(
    async (id, name) => {
      const row = allRows.find(
        (r) =>
          Number(r.id) === Number(id)
      );

      if (!row) return false;

      return update(id, {
        vehicle_type_id:
          row.vehicle_type_id,

        name,

        status:
          row.status || 'active',
      });
    },
    [allRows, update]
  );

  // =====================================================
  // TOGGLE STATUS
  // =====================================================

  const toggleStatus = useCallback(
    async (id) => {
      const row = allRows.find(
        (r) =>
          Number(r.id) === Number(id)
      );

      if (!row) return false;

      const nextStatus =
        row.status === 'active'
          ? 'inactive'
          : 'active';

      setSavingId(id);

      try {
        const updated =
          await TransportLinesService.setStatus(
            id,
            nextStatus
          );

        setAllRows((prev) =>
          prev.map((r) =>
            Number(r.id) ===
              Number(id)
              ? updated
              : r
          )
        );

        toast.success(
          nextStatus === 'active'
            ? 'Línea activada'
            : 'Línea desactivada'
        );

        return true;
      } catch (e) {
        toast.error(
          e?.message ||
          'No se pudo cambiar el estado'
        );

        return false;
      } finally {
        setSavingId(null);
      }
    },
    [allRows]
  );

  // =====================================================
  // ARCHIVE
  // =====================================================

  const remove = useCallback(
    async (id) => {
      const ok = window.confirm(
        '¿Archivar esta línea?'
      );

      if (!ok) return false;

      setSavingId(id);

      const toastId =
        toast.loading('Archivando…');

      try {
        await TransportLinesService.archive(
          id
        );

        setAllRows((prev) =>
          prev.filter(
            (row) =>
              Number(row.id) !==
              Number(id)
          )
        );

        toast.success(
          'Línea archivada',
          {
            id: toastId,
          }
        );

        return true;
      } catch (e) {
        toast.error(
          e?.message ||
          'No se pudo archivar',
          {
            id: toastId,
          }
        );

        return false;
      } finally {
        setSavingId(null);
      }
    },
    []
  );

  return {
    rows: filtered,
    filteredRows: filtered,
    allRows: rowsWithVehicleType,

    vehicleTypes,
    loadingVehicleTypes,

    loading,
    err,
    savingId,

    search,
    setSearch,

    vehicleTypeFilter,
    setVehicleTypeFilter,

    statusFilter,
    setStatusFilter,

    fetchAll,
    loadVehicleTypes,

    create,
    update,
    updateName,
    toggleStatus,
    remove,
  };
}