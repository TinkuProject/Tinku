// File: src/components/Transport/TransportLinesFormEdit.jsx
'use client';

import { useEffect, useMemo, useState } from 'react';
import { FaSave, FaUpload, FaImage } from 'react-icons/fa';

import useTransportLines from '@/hooks/useTransportLines';
import useVehicleTypes from '@/hooks/useVehicleTypes';

const UI = {
    primary: '#0077B6',
    border: '#E2E8F0',
    soft: '#F8FAFC',
};

function getMediaImages(row) {
    const media = Array.isArray(row?.media) ? row.media : [];

    return media
        .map((m) => m?.url || m?.image_url || m?.media_url || m?.path)
        .filter(Boolean);
}

export default function TransportLinesFormEdit({
    open,
    onClose = () => { },
    row,
    onSaved = () => { },
}) {
    const { update, savingId } = useTransportLines();
    const { rows: vehicleTypes = [] } = useVehicleTypes();

    const [name, setName] = useState('');
    const [typeId, setTypeId] = useState('');
    const [status, setStatus] = useState('active');

    const [logoFile, setLogoFile] = useState(null);
    const [vehiclePhotoFile, setVehiclePhotoFile] = useState(null);

    const [logoPreview, setLogoPreview] = useState('');
    const [vehiclePreview, setVehiclePreview] = useState('');

    const [err, setErr] = useState('');

    useEffect(() => {
        if (!row?.id) return;

        const mediaImages = getMediaImages(row);

        setName(row.name || '');
        setTypeId(row.vehicle_type_id ?? '');
        setStatus(row.status || 'active');

        setLogoFile(null);
        setVehiclePhotoFile(null);

        setLogoPreview(row.logo || mediaImages[0] || '');
        setVehiclePreview(row.vehicle_photo || mediaImages[1] || '');

        setErr('');
    }, [row]);

    useEffect(() => {
        return () => {
            if (logoPreview?.startsWith('blob:')) URL.revokeObjectURL(logoPreview);
            if (vehiclePreview?.startsWith('blob:')) URL.revokeObjectURL(vehiclePreview);
        };
    }, [logoPreview, vehiclePreview]);

    const canSubmit = useMemo(() => {
        if (!row?.id) return false;

        const cleanName = name.trim();

        const nameChanged = cleanName !== (row.name || '');
        const typeChanged = Number(typeId) !== Number(row.vehicle_type_id);
        const statusChanged = status !== (row.status || 'active');

        return Boolean(
            cleanName &&
            typeId &&
            (nameChanged || typeChanged || statusChanged || logoFile || vehiclePhotoFile)
        );
    }, [name, typeId, status, row, logoFile, vehiclePhotoFile]);

    if (!open || !row) return null;

    const handleLogoChange = (e) => {
        const file = e.target.files?.[0] || null;

        if (logoPreview?.startsWith('blob:')) URL.revokeObjectURL(logoPreview);

        setLogoFile(file);
        setLogoPreview(file ? URL.createObjectURL(file) : row.logo || '');
    };

    const handleVehiclePhotoChange = (e) => {
        const file = e.target.files?.[0] || null;

        if (vehiclePreview?.startsWith('blob:')) URL.revokeObjectURL(vehiclePreview);

        setVehiclePhotoFile(file);
        setVehiclePreview(file ? URL.createObjectURL(file) : row.vehicle_photo || '');
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        setErr('');

        try {
            const ok = await update(
                row.id,
                {
                    vehicle_type_id: Number(typeId),
                    name: name.trim(),
                    status,
                },
                {
                    logoFile: logoFile || undefined,
                    vehiclePhotoFile: vehiclePhotoFile || undefined,
                }
            );

            if (!ok) return;

            onSaved();
            onClose();
        } catch (ex) {
            setErr(ex?.message || 'No se pudo guardar');
        }
    };

    return (
        <div className="fixed inset-0 z-50">
            <div className="absolute inset-0 bg-black/40" onClick={onClose} />

            <div className="absolute inset-0 grid place-items-center p-6">
                <div
                    className="w-full max-w-xl bg-white rounded-lg shadow-xl border"
                    style={{ borderColor: UI.border }}
                >
                    <div
                        className="px-5 py-3 flex items-center justify-between rounded-t-lg"
                        style={{
                            background: UI.soft,
                            borderBottom: `1px solid ${UI.border}`,
                        }}
                    >
                        <h2 className="font-semibold text-slate-900">
                            Editar línea #{row.id}
                        </h2>

                        <button
                            type="button"
                            onClick={onClose}
                            className="text-slate-700 hover:text-slate-900"
                        >
                            ✕
                        </button>
                    </div>

                    <form onSubmit={handleSubmit} className="p-5 space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-slate-700 mb-1">
                                Nombre
                            </label>

                            <input
                                value={name}
                                onChange={(e) => setName(e.target.value)}
                                className="w-full border border-slate-300 p-3 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
                                placeholder="Nombre de la línea"
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-slate-700 mb-1">
                                Tipo de vehículo
                            </label>

                            <select
                                value={typeId}
                                onChange={(e) => setTypeId(Number(e.target.value))}
                                className="w-full border border-slate-300 p-3 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
                            >
                                <option value="" disabled>
                                    Selecciona un tipo…
                                </option>

                                {(vehicleTypes || []).map((t) => (
                                    <option key={t.id} value={t.id}>
                                        {t.name}
                                    </option>
                                ))}
                            </select>
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-slate-700 mb-1">
                                Estado
                            </label>

                            <select
                                value={status}
                                onChange={(e) => setStatus(e.target.value)}
                                className="w-full border border-slate-300 p-3 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-[#0077B6] text-slate-800"
                            >
                                <option value="active">Activo</option>
                                <option value="inactive">Inactivo</option>
                                <option value="archived">Archivado</option>
                            </select>
                        </div>

                        <div className="space-y-2">
                            <label className="block text-sm font-medium text-slate-700">
                                Logo
                            </label>

                            <div className="flex items-center gap-3">
                                {logoPreview ? (
                                    <img
                                        src={logoPreview}
                                        alt="logo"
                                        className="h-14 w-14 object-cover rounded bg-white border"
                                    />
                                ) : (
                                    <div className="h-14 w-14 grid place-items-center text-slate-400 border rounded bg-white">
                                        —
                                    </div>
                                )}

                                <label className="inline-flex items-center gap-2 px-3 py-2 rounded-lg border bg-white text-[#0077B6] hover:bg-[#E0F4FF] cursor-pointer transition">
                                    <FaUpload />
                                    <span className="font-semibold">Elegir archivo</span>

                                    <input
                                        type="file"
                                        accept="image/*"
                                        className="hidden"
                                        onChange={handleLogoChange}
                                    />
                                </label>

                                {logoFile && (
                                    <span className="text-xs text-slate-600 truncate max-w-[12rem]">
                                        {logoFile.name}
                                    </span>
                                )}
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="block text-sm font-medium text-slate-700">
                                Foto del vehículo
                            </label>

                            <div className="flex items-center gap-3">
                                {vehiclePreview ? (
                                    <img
                                        src={vehiclePreview}
                                        alt="vehículo"
                                        className="h-14 w-20 object-cover rounded border"
                                    />
                                ) : (
                                    <div className="h-14 w-20 grid place-items-center text-slate-400 border rounded bg-white">
                                        —
                                    </div>
                                )}

                                <label className="inline-flex items-center gap-2 px-3 py-2 rounded-lg border bg-white text-[#0077B6] hover:bg-[#E0F4FF] cursor-pointer transition">
                                    <FaImage />
                                    <span className="font-semibold">Elegir archivo</span>

                                    <input
                                        type="file"
                                        accept="image/*"
                                        className="hidden"
                                        onChange={handleVehiclePhotoChange}
                                    />
                                </label>

                                {vehiclePhotoFile && (
                                    <span className="text-xs text-slate-600 truncate max-w-[12rem]">
                                        {vehiclePhotoFile.name}
                                    </span>
                                )}
                            </div>
                        </div>

                        {err && <p className="text-sm text-rose-600">{err}</p>}

                        <div className="pt-2 flex justify-end gap-2">
                            <button
                                type="button"
                                onClick={onClose}
                                className="px-5 py-2 rounded-md font-semibold border bg-white text-slate-900 hover:bg-[#F2F4F7]"
                                style={{ borderColor: UI.border }}
                            >
                                Cancelar
                            </button>

                            <button
                                type="submit"
                                disabled={!canSubmit || savingId === row.id}
                                className="px-5 py-2 rounded-md font-semibold text-white disabled:opacity-60"
                                style={{ background: UI.primary }}
                            >
                                <span className="inline-flex items-center gap-2">
                                    <FaSave /> Guardar
                                </span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
}