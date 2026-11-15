'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { FaCrosshairs } from 'react-icons/fa';

// === Reverse geocoding (opcional para mostrar dirección) ===
const nominatimReverse = async (lat, lng) => {
  const url = `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${lat}&lon=${lng}`;
  const res = await fetch(url, { headers: { 'Accept-Language': 'es' } });
  if (!res.ok) return '';
  const data = await res.json();
  return data?.display_name || '';
};

export default function MapPicker({
  value = { lat: -17.3895, lng: -66.1568, address: '' },
  onChange,
  height = 420,
}) {
  const [leaflet, setLeaflet] = useState(null); // dynamic import
  const [pos, setPos] = useState([value.lat, value.lng]);
  const [address, setAddress] = useState(value.address || '');
  const [loadingAddr, setLoadingAddr] = useState(false);
  const [myLocation, setMyLocation] = useState(null); // 🔵 circulito azul
  const mapRef = useRef(null);

  // Load Leaflet components dynamically
  useEffect(() => {
    let mounted = true;
    (async () => {
      const [
        { MapContainer, TileLayer, Marker, Circle, useMapEvents },
        L,
      ] = await Promise.all([import('react-leaflet'), import('leaflet')]);

      // Patch Leaflet icons for Next.js
      delete L.Icon.Default.prototype._getIconUrl;
      L.Icon.Default.mergeOptions({
        iconRetinaUrl:
          'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
        iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
        shadowUrl:
          'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
      });

      if (mounted)
        setLeaflet({ MapContainer, TileLayer, Marker, Circle, useMapEvents });
    })();

    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => {
    if (value.lat && value.lng) {
      setPos([value.lat, value.lng]);
      setAddress(value.address || '');
    }
  }, [value]);

  const emit = (lat, lng, addr) =>
    onChange?.({ lat, lng, address: addr ?? address });

  const resolveAddress = async (lat, lng) => {
    setLoadingAddr(true);
    try {
      const addr = await nominatimReverse(lat, lng);
      setAddress(addr);
      emit(lat, lng, addr);
    } finally {
      setLoadingAddr(false);
    }
  };

  const handlePick = async (lat, lng) => {
    setPos([lat, lng]);
    setMyLocation(null);
    await resolveAddress(lat, lng);
  };

  // === 📍 Mi ubicación (GPS) ===
  const useMyLocation = () => {
    if (!navigator.geolocation) return;

    navigator.geolocation.getCurrentPosition(
      async ({ coords }) => {
        const lat = coords.latitude;
        const lng = coords.longitude;

        setMyLocation([lat, lng]); // 🔵 circulo azul
        setPos([lat, lng]);

        if (mapRef.current) {
          mapRef.current.flyTo([lat, lng], 16, {
            animate: true,
            duration: 1.4,
          });
        }

        await resolveAddress(lat, lng);
      },
      (err) => console.warn(err),
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  const markerHandlers = useMemo(
    () => ({
      dragend: async (e) => {
        const { lat, lng } = e.target.getLatLng();
        setMyLocation(null);
        handlePick(lat, lng);
      },
    }),
    []
  );

  // Click en el mapa para mover marcador
  function ClickCatcher() {
    if (!leaflet) return null;
    const { useMapEvents } = leaflet;
    useMapEvents({
      click(e) {
        handlePick(e.latlng.lat, e.latlng.lng);
      },
    });
    return null;
  }

  return (
    <div className="space-y-3">

      {/* === ÚNICO BOTÓN === */}
      <div className="flex justify-start">
        <button
          type="button"
          onClick={useMyLocation}
          className="bg-[#0077B6] hover:bg-[#005f92] text-white px-4 py-2 rounded-lg font-semibold flex items-center gap-2"
        >
          <FaCrosshairs />
          Mi ubicación
        </button>
      </div>

      {/* === MAPA === */}
      <div className="rounded-xl overflow-hidden border border-slate-200">
        {!leaflet ? (
          <div
            style={{ height }}
            className="grid place-items-center text-slate-500"
          >
            Cargando mapa…
          </div>
        ) : (
          <leaflet.MapContainer
            ref={mapRef}
            center={pos}
            zoom={14}
            style={{ height }}
            scrollWheelZoom
          >
            <leaflet.TileLayer
              attribution="&copy; OpenStreetMap contributors"
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />

            <ClickCatcher />

            <leaflet.Marker
              position={pos}
              draggable
              eventHandlers={markerHandlers}
            />

            {/* 🔵 Círculo Azul GPS */}
            {myLocation && (
              <leaflet.Circle
                center={myLocation}
                radius={40}
                pathOptions={{
                  color: '#3388ff',
                  fillColor: '#3388ff',
                  fillOpacity: 0.3,
                }}
              />
            )}
          </leaflet.MapContainer>
        )}
      </div>

      {/* === DATOS === */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        <div>
          <label className="block text-sm text-slate-600">Latitud</label>
          <input
            readOnly
            value={pos[0]}
            className="w-full border border-slate-300 p-2 rounded-lg bg-slate-50 text-slate-800"
          />
        </div>

        <div>
          <label className="block text-sm text-slate-600">Longitud</label>
          <input
            readOnly
            value={pos[1]}
            className="w-full border border-slate-300 p-2 rounded-lg bg-slate-50 text-slate-800"
          />
        </div>

        <div className="md:col-span-3">
          <label className="block text-sm text-slate-600">
            Dirección {loadingAddr && <span className="text-slate-400">(buscando…)</span>}
          </label>
          <textarea
            readOnly
            rows={2}
            value={address}
            className="w-full border border-slate-300 p-2 rounded-lg bg-slate-50 text-slate-800"
          />
        </div>
      </div>
    </div>
  );
}
