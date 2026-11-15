'use client';

import { useEffect, useMemo, useState } from 'react';
import { useUser } from '../../context/UserContext';

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

/** ---- Componente que sólo pinta el mapa cuando react-leaflet/leaflet están cargados en cliente ---- */
function MapSection({ mapCenter, initialMarker, setFormData }) {
  const [RL, setRL] = useState(null);       // { MapContainer, TileLayer, Marker, useMapEvents }
  const [L, setLeaflet] = useState(null);   // leaflet namespace
  const [markerUrl, setMarkerUrl] = useState('/images/marker.png'); // fallback

  useEffect(() => {
    let mounted = true;
    (async () => {
      // Importa CSS y librerías sólo en cliente
      await import('leaflet/dist/leaflet.css');
      const rlMod = await import('react-leaflet');
      const lMod = await import('leaflet');

      // Carga imagen del marker en runtime (evita import estático en SSR)
      try {
        const img = await import('../../../public/images/marker.png');
        const src = img?.default?.src || img?.src || '/images/marker.png';
        if (mounted) setMarkerUrl(src);
      } catch {
        // deja el fallback
      }

      if (!mounted) return;

      const Lns = lMod.default ?? lMod;

      // Fix de iconos por defecto
      try {
        delete Lns.Icon.Default.prototype._getIconUrl;
        Lns.Icon.Default.mergeOptions({
          iconUrl: 'https://unpkg.com/leaflet@1.9.3/dist/images/marker-icon.png',
          shadowUrl: 'https://unpkg.com/leaflet@1.9.3/dist/images/marker-shadow.png',
        });
      } catch {}

      setRL(rlMod);
      setLeaflet(Lns);
    })();

    return () => { mounted = false; };
  }, []);

  if (!RL || !L) {
    // skeleton mientras carga leaflet
    return <div className="h-64 rounded-lg bg-slate-100 border border-slate-200" />;
  }

  const { MapContainer, TileLayer, Marker, useMapEvents } = RL;

  function LocationMarker({ initialPosition }) {
    const [position, setPosition] = useState(initialPosition || null);

    const customMarker = useMemo(
      () => new L.Icon({ iconUrl: markerUrl, iconSize: [28, 28] }),
      [L, markerUrl]
    );

    useEffect(() => {
      if (initialPosition) setPosition(initialPosition);
    }, [initialPosition]);

    useMapEvents({
      async click(e) {
        const { lat, lng } = e.latlng;
        setPosition([lat, lng]);

        try {
          const res = await fetch(
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`
          );
          const data = await res.json();
          const address = data?.display_name || 'Dirección desconocida';

          setFormData((prev) => ({
            ...prev,
            address,
            location: { type: 'Point', coordinates: [lng, lat] }, // GeoJSON
          }));
        } catch {
          setFormData((prev) => ({
            ...prev,
            location: { type: 'Point', coordinates: [lng, lat] },
          }));
        }
      },
    });

    return position ? <Marker position={position} icon={customMarker} /> : null;
  }

  return (
    <div className="col-span-2 h-64 rounded-lg overflow-hidden border border-slate-200">
      <MapContainer center={mapCenter} zoom={13} style={{ height: '100%', width: '100%' }}>
        <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
        <LocationMarker initialPosition={initialMarker} />
      </MapContainer>
    </div>
  );
}

export default function EditUser({ onClose }) {
  const { user, updateUser } = useUser();

  const [isEditing, setIsEditing] = useState(true);
  const [formData, setFormData] = useState({
    first_name: '',
    last_name: '',
    username: '',
    email: '',
    phone: '',
    ci: '',
    address: '',
    location: null,
    photo: '',
  });
  const [preview, setPreview] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);

  // Cargar datos del usuario
  useEffect(() => {
    if (user) {
      setFormData({
        first_name: user.first_name || '',
        last_name: user.last_name || '',
        username: user.username || '',
        email: user.email || '',
        phone: user.phone || '',
        ci: user.ci || '',
        address: user.address || '',
        location: user.location || null,
        photo: user.photo || '',
      });
      setPreview(user.photo || null);
    }
  }, [user]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  // Subir foto
  const handleFileChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    try {
      const fd = new FormData();
      fd.append('folder', 'users');
      fd.append('itemId', user.id);
      fd.append('images', file);

      const token = localStorage.getItem('token');
      const res = await fetch(`${API_URL}/storage/upload`, {
        method: 'POST',
        headers: token ? { Authorization: `Bearer ${token}` } : undefined,
        body: fd,
      });

      if (!res.ok) throw new Error('Error al subir la imagen');

      const data = await res.json();
      const url = data?.urls?.[0];
      if (!url) throw new Error('No se recibió URL de imagen');

      setFormData((prev) => ({ ...prev, photo: url }));
      setPreview(url);
    } catch (err) {
      console.error('Error al subir la imagen:', err);
      alert('Error al subir la imagen');
    } finally {
      setUploading(false);
    }
  };

  // Guardar
  const handleSave = async (e) => {
    e.preventDefault();
    if (!user?.id) return;

    setSaving(true);
    try {
      const result = await updateUser(user.id, formData);
      if (result?.success) {
        alert('Usuario actualizado correctamente');
        setIsEditing(false);
        onClose?.();
      } else {
        alert(result?.message || 'No se pudo actualizar el usuario');
      }
    } catch (err) {
      console.error('Error al actualizar usuario:', err);
      alert('Ocurrió un error al actualizar');
    } finally {
      setSaving(false);
    }
  };

  // Centro del mapa e initial marker
  const mapCenter = useMemo(() => {
    const coords = user?.location?.coordinates; // [lng, lat]
    if (Array.isArray(coords) && coords.length === 2) {
      return [coords[1], coords[0]]; // Leaflet usa [lat, lng]
    }
    return [-16.5, -68.15]; // default
  }, [user]);

  const initialMarker = useMemo(() => {
    const coords = user?.location?.coordinates;
    return Array.isArray(coords) && coords.length === 2 ? [coords[1], coords[0]] : null;
  }, [user]);

  if (!user?.id) {
    return (
      <p className="p-10 text-center text-gray-500 italic">
        Cargando usuario...
      </p>
    );
  }

  return (
    <div className="p-6 bg-white rounded-2xl shadow-sm max-w-3xl mx-auto mt-6 border border-slate-200">
      <h1 className="text-3xl font-semibold text-[#0077B6] mb-6 text-center">
        Editar Perfil
      </h1>

      <form onSubmit={handleSave} className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Nombres */}
        <input
          type="text"
          name="first_name"
          value={formData.first_name}
          onChange={handleChange}
          placeholder="Nombre"
          className="bg-white border border-slate-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-[#0077B6]/20 focus:border-[#0077B6] text-slate-800"
        />
        <input
          type="text"
          name="last_name"
          value={formData.last_name}
          onChange={handleChange}
          placeholder="Apellido"
          className="bg-white border border-slate-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-[#0077B6]/20 focus:border-[#0077B6] text-slate-800"
        />

        {/* Email y teléfono */}
        <input
          type="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          placeholder="Correo electrónico"
          className="bg-white border border-slate-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-[#0077B6]/20 focus:border-[#0077B6] text-slate-800"
        />
        <input
          type="text"
          name="phone"
          value={formData.phone}
          onChange={handleChange}
          placeholder="Teléfono"
          className="bg-white border border-slate-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-[#0077B6]/20 focus:border-[#0077B6] text-slate-800"
        />

        {/* CI */}
        <input
          type="text"
          name="ci"
          value={formData.ci}
          onChange={handleChange}
          placeholder="C.I."
          className="bg-white border border-slate-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-[#0077B6]/20 focus:border-[#0077B6] text-slate-800"
        />

        {/* Username + Dirección (readOnly) */}
        <input
          type="text"
          name="username"
          value={formData.username}
          readOnly
          className="px-3 py-2 border border-slate-200 rounded-lg bg-gray-100 cursor-not-allowed col-span-2 text-slate-700"
        />
        <input
          type="text"
          name="address"
          value={formData.address}
          readOnly
          className="px-3 py-2 border border-slate-200 rounded-lg bg-gray-100 cursor-not-allowed col-span-2 text-slate-700"
        />

        {/* Mapa: ahora client-only y sin SSR */}
        <MapSection
          mapCenter={mapCenter}
          initialMarker={initialMarker}
          setFormData={setFormData}
        />

        {/* Foto de perfil */}
        <div className="col-span-2">
          <label className="block text-[#0077B6] font-semibold mb-2">Foto de perfil</label>
          <input
            type="file"
            accept="image/*"
            onChange={handleFileChange}
            className="px-3 py-2 border border-slate-200 rounded-lg w-full bg-white text-slate-800 disabled:opacity-60 disabled:pointer-events-none"
            disabled={uploading || saving}
          />
          {preview && (
            <div className="mt-3 flex justify-center">
              <img
                src={preview}
                alt="Preview"
                className="w-32 h-32 rounded-full object-cover border-2 border-[#0077B6]/50 shadow-sm"
              />
            </div>
          )}
        </div>

        {/* Botones */}
        <div className="col-span-2 flex gap-4 mt-4">
          <button
            type="submit"
            disabled={uploading || saving}
            className="flex-1 bg-[#0077B6] text-white py-2 rounded-lg hover:bg-[#005F92] transition disabled:opacity-60 disabled:pointer-events-none"
          >
            {saving ? 'Guardando…' : 'Guardar'}
          </button>
          <button
            type="button"
            onClick={() => {
              setIsEditing(false);
              onClose?.();
            }}
            disabled={saving}
            className="flex-1 bg-gray-400 text-white py-2 rounded-lg hover:bg-gray-500 transition disabled:opacity-60 disabled:pointer-events-none"
          >
            Cancelar
          </button>
        </div>
      </form>
    </div>
  );
}
