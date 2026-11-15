// File: src/components/TransportLines/RegisterTrasportationLines.jsx
'use client';

import {
  useEffect,
  useMemo,
  useState,
} from 'react';

import {
  FaPlus,
  FaImage,
} from 'react-icons/fa';

import useTransportLines from '@/hooks/useTransportLines';
import useVehicleTypes from '@/hooks/useVehicleTypes';

export default function RegisterTrasportationLines({
  onCreated,
}) {
  // =====================================================
  // MODAL
  // =====================================================

  const [isOpen, setIsOpen] =
    useState(false);

  // =====================================================
  // HOOKS
  // =====================================================

  const {
    create,
    loading: saving,
    err,
  } = useTransportLines();

  const {
    rows: vehicleTypes = [],
    loading: loadingVehicleTypes,
  } = useVehicleTypes();

  // =====================================================
  // FORM
  // =====================================================

  const defaultTypeId = useMemo(
    () =>
      vehicleTypes?.[0]?.id ?? '',
    [vehicleTypes]
  );

  const [form, setForm] =
    useState({
      vehicle_type_id: '',
      name: '',
    });

  useEffect(() => {
    setForm((prev) => ({
      ...prev,
      vehicle_type_id:
        prev.vehicle_type_id ||
        defaultTypeId,
    }));
  }, [defaultTypeId]);

  // =====================================================
  // FILES
  // =====================================================

  const [logoFile, setLogoFile] =
    useState(null);

  const [
    vehiclePhotoFile,
    setVehiclePhotoFile,
  ] = useState(null);

  const [
    logoPreview,
    setLogoPreview,
  ] = useState('');

  const [
    vehiclePreview,
    setVehiclePreview,
  ] = useState('');

  // =====================================================
  // CLEAN OBJECT URLS
  // =====================================================

  useEffect(() => {
    return () => {
      if (logoPreview) {
        URL.revokeObjectURL(
          logoPreview
        );
      }

      if (vehiclePreview) {
        URL.revokeObjectURL(
          vehiclePreview
        );
      }
    };
  }, [
    logoPreview,
    vehiclePreview,
  ]);

  // =====================================================
  // HANDLERS
  // =====================================================

  const handleChange = (e) => {
    const { name, value } =
      e.target;

    setForm((prev) => ({
      ...prev,

      [name]:
        name ===
          'vehicle_type_id'
          ? Number(value)
          : value,
    }));
  };

  const handleLogo = (e) => {
    const file =
      e.target.files?.[0] || null;

    if (logoPreview) {
      URL.revokeObjectURL(
        logoPreview
      );
    }

    setLogoFile(file);

    setLogoPreview(
      file
        ? URL.createObjectURL(file)
        : ''
    );
  };

  const handleVehiclePhoto = (
    e
  ) => {
    const file =
      e.target.files?.[0] || null;

    if (vehiclePreview) {
      URL.revokeObjectURL(
        vehiclePreview
      );
    }

    setVehiclePhotoFile(file);

    setVehiclePreview(
      file
        ? URL.createObjectURL(file)
        : ''
    );
  };

  // =====================================================
  // RESET
  // =====================================================

  const resetAll = () => {
    setForm({
      vehicle_type_id:
        defaultTypeId,
      name: '',
    });

    setLogoFile(null);

    setVehiclePhotoFile(null);

    if (logoPreview) {
      URL.revokeObjectURL(
        logoPreview
      );
    }

    if (vehiclePreview) {
      URL.revokeObjectURL(
        vehiclePreview
      );
    }

    setLogoPreview('');
    setVehiclePreview('');
  };

  const closeModal = () => {
    resetAll();
    setIsOpen(false);
  };

  // =====================================================
  // SUBMIT
  // =====================================================

  const handleSubmit = async (
    e
  ) => {
    e.preventDefault();

    if (saving) return;

    const name =
      form.name.trim();

    if (!name) return;

    const ok = await create(
      {
        vehicle_type_id: Number(
          form.vehicle_type_id
        ),

        name,

        status: 'active',
      },

      {
        logoFile,
        vehiclePhotoFile,
      }
    );

    if (!ok) return;

    closeModal();

    onCreated?.();
  };

  // =====================================================
  // RENDER
  // =====================================================

  return (
    <div className="space-y-4">
      <button
        onClick={() =>
          setIsOpen(true)
        }
        className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[#16A34A] text-white font-semibold hover:bg-[#15803D] transition"
      >
        <FaPlus />

        Registrar nueva línea
      </button>

      {isOpen && (
        <div className="fixed inset-0 z-50">
          {/* overlay */}
          <div
            className="absolute inset-0 bg-black/40"
            onClick={closeModal}
          />

          {/* modal */}
          <div className="absolute inset-0 grid place-items-center p-6">
            <div className="w-full max-w-4xl bg-white rounded-2xl shadow-xl border border-slate-200">
              {/* header */}
              <div className="px-5 py-3 flex items-center justify-between border-b border-slate-200">
                <h3 className="text-lg font-semibold text-slate-900">
                  Registrar línea
                  de transporte
                </h3>

                <button
                  onClick={
                    closeModal
                  }
                  className="px-2 py-1 rounded-md text-slate-600 hover:bg-slate-100"
                  aria-label="Cerrar"
                  type="button"
                >
                  ✕
                </button>
              </div>

              {/* body */}
              <form
                onSubmit={
                  handleSubmit
                }
                className="p-5 grid gap-5"
              >
                {/* top */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div className="grid gap-1">
                    <label className="text-sm font-medium text-slate-700">
                      Tipo de
                      vehículo
                    </label>

                    <select
                      name="vehicle_type_id"
                      value={
                        form.vehicle_type_id
                      }
                      onChange={
                        handleChange
                      }
                      disabled={
                        loadingVehicleTypes
                      }
                      className="px-3 py-2 rounded-lg border border-slate-300 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                    >
                      {vehicleTypes.map(
                        (vt) => (
                          <option
                            key={
                              vt.id
                            }
                            value={
                              vt.id
                            }
                          >
                            {vt.name}
                          </option>
                        )
                      )}
                    </select>
                  </div>

                  <div className="grid gap-1">
                    <label className="text-sm font-medium text-slate-700">
                      Nombre de
                      la línea
                    </label>

                    <input
                      name="name"
                      placeholder="Ej. 120"
                      value={
                        form.name
                      }
                      onChange={
                        handleChange
                      }
                      className="px-3 py-2 rounded-lg border border-slate-300 bg-white text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-[#0077B6]"
                    />
                  </div>
                </div>

                {/* images */}
                <div className="grid md:grid-cols-2 gap-5">
                  {/* logo */}
                  <div className="grid gap-2">
                    <label className="text-sm font-medium text-slate-700">
                      Logo
                      (opcional)
                    </label>

                    <label className="inline-flex items-center gap-2 w-fit px-3 py-2 rounded-lg border border-slate-300 bg-white text-[#0077B6] hover:bg-[#E0F4FF] cursor-pointer transition">
                      <FaImage />

                      <span className="font-medium">
                        Elegir
                        archivo
                      </span>

                      <input
                        type="file"
                        accept="image/*"
                        onChange={
                          handleLogo
                        }
                        className="hidden"
                      />
                    </label>

                    {logoPreview && (
                      <img
                        src={
                          logoPreview
                        }
                        alt="logo preview"
                        className="h-24 w-24 rounded-xl border border-slate-200 bg-white object-cover"
                      />
                    )}
                  </div>

                  {/* vehicle photo */}
                  <div className="grid gap-2">
                    <label className="text-sm font-medium text-slate-700">
                      Foto del
                      vehículo
                      (opcional)
                    </label>

                    <label className="inline-flex items-center gap-2 w-fit px-3 py-2 rounded-lg border border-slate-300 bg-white text-[#0077B6] hover:bg-[#E0F4FF] cursor-pointer transition">
                      <FaImage />

                      <span className="font-medium">
                        Elegir
                        archivo
                      </span>

                      <input
                        type="file"
                        accept="image/*"
                        onChange={
                          handleVehiclePhoto
                        }
                        className="hidden"
                      />
                    </label>

                    {vehiclePreview && (
                      <img
                        src={
                          vehiclePreview
                        }
                        alt="vehicle preview"
                        className="h-32 w-full rounded-xl border border-slate-200 bg-white object-cover"
                      />
                    )}
                  </div>
                </div>

                {/* error */}
                {err && (
                  <div className="px-3 py-2 rounded-md bg-red-50 text-red-700 border border-red-200 text-sm">
                    {err}
                  </div>
                )}

                {/* actions */}
                <div className="pt-2 flex items-center justify-end gap-2">
                  <button
                    type="button"
                    onClick={
                      closeModal
                    }
                    className="px-4 py-2 rounded-lg border border-slate-300 bg-white text-slate-800 hover:bg-slate-50"
                  >
                    Cancelar
                  </button>

                  <button
                    type="submit"
                    disabled={
                      saving ||
                      !form.name.trim()
                    }
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[#16A34A] text-white font-semibold hover:bg-[#15803D] disabled:opacity-60 disabled:cursor-not-allowed transition"
                  >
                    <FaPlus />

                    {saving
                      ? 'Creando…'
                      : 'Crear línea'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}