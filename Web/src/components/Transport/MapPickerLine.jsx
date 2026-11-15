// File: src/components/Transport/MapPickerLine.jsx
'use client';

import { useEffect, useMemo, useRef, useState } from 'react';

export default function MapPickerLine({
  value = { lat: -17.3895, lng: -66.1568 },
  onChange,
  points = [],
  height = 360,
  zoom = 14,
  showMyLocation = true,
  showPolyline = true,
  showMarkers = true,
  fitToRoute = true,
  disabled = false,
  toolbarExtra = null,
}) {
  const [leaflet, setLeaflet] = useState(null);
  const [pos, setPos] = useState([Number(value.lat), Number(value.lng)]);

  const mapRef = useRef(null);
  const LRef = useRef(null);

  useEffect(() => {
    let mounted = true;

    async function loadLeaflet() {
      const [
        { MapContainer, TileLayer, Marker, CircleMarker, Polyline, Tooltip, useMapEvents },
        L,
      ] = await Promise.all([import('react-leaflet'), import('leaflet')]);

      delete L.Icon.Default.prototype._getIconUrl;

      L.Icon.Default.mergeOptions({
        iconRetinaUrl:
          'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
        iconUrl:
          'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
        shadowUrl:
          'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
      });

      if (mounted) {
        setLeaflet({
          MapContainer,
          TileLayer,
          Marker,
          CircleMarker,
          Polyline,
          Tooltip,
          useMapEvents,
        });

        LRef.current = L;
      }
    }

    loadLeaflet();

    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => {
    const lat = Number(value?.lat);
    const lng = Number(value?.lng);

    if (Number.isFinite(lat) && Number.isFinite(lng)) {
      setPos([lat, lng]);
    }
  }, [value?.lat, value?.lng]);

  const normalizedPoints = useMemo(() => {
    return (points || [])
      .map((p, index) => ({
        ...p,
        lat: Number(p.lat ?? p.latitude),
        lng: Number(p.lng ?? p.longitude),
        order: Number(p.stop_order ?? p.order ?? index),
      }))
      .filter((p) => Number.isFinite(p.lat) && Number.isFinite(p.lng))
      .sort((a, b) => Number(a.order ?? 0) - Number(b.order ?? 0));
  }, [points]);

  const routeLatLngs = useMemo(
    () => normalizedPoints.map((p) => [p.lat, p.lng]),
    [normalizedPoints]
  );

  const emit = (lat, lng) => {
    onChange?.({ lat, lng });
  };

  const handlePick = (lat, lng) => {
    if (disabled) return;

    setPos([lat, lng]);
    emit(lat, lng);
  };

  const useMyLocation = () => {
    if (!navigator.geolocation || disabled) return;

    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        const lat = Number(coords.latitude);
        const lng = Number(coords.longitude);

        setPos([lat, lng]);
        emit(lat, lng);

        mapRef.current?.setView([lat, lng], 16);
      },
      (err) => console.warn(err),
      {
        enableHighAccuracy: true,
        timeout: 10000,
      }
    );
  };

  const markerHandlers = useMemo(
    () => ({
      dragend: (e) => {
        if (disabled) return;

        const { lat, lng } = e.target.getLatLng();

        setPos([lat, lng]);
        emit(lat, lng);
      },
    }),
    [disabled]
  );

  function ClickCatcher() {
    if (!leaflet || disabled) return null;

    const { useMapEvents } = leaflet;

    useMapEvents({
      click(e) {
        handlePick(e.latlng.lat, e.latlng.lng);
      },
    });

    return null;
  }

  const fitBoundsToRoute = () => {
    if (!LRef.current || !mapRef.current) return;

    const L = LRef.current;
    const map = mapRef.current;

    const coords = routeLatLngs.length ? routeLatLngs : [pos];

    if (!coords.length) return;

    if (coords.length === 1) {
      map.setView(coords[0], 16);
      return;
    }

    const bounds = L.latLngBounds(coords);
    map.fitBounds(bounds.pad(0.15), { maxZoom: 17 });
  };

  useEffect(() => {
    if (!fitToRoute) return;

    const t = setTimeout(() => {
      fitBoundsToRoute();
    }, 100);

    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fitToRoute, routeLatLngs.length]);

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        {showMyLocation && (
          <button
            type="button"
            onClick={useMyLocation}
            className="bg-sky-100 text-sky-800 px-4 py-2 rounded-lg font-semibold hover:bg-sky-200 disabled:opacity-60"
            disabled={disabled}
          >
            📍 Mi ubicación
          </button>
        )}

        <button
          type="button"
          onClick={fitBoundsToRoute}
          className="bg-sky-600 text-white px-4 py-2 rounded-lg font-semibold hover:bg-sky-700 disabled:opacity-60"
          disabled={disabled}
        >
          Ajustar a ruta
        </button>

        {toolbarExtra && <div className="ml-1">{toolbarExtra}</div>}
      </div>

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
            zoom={zoom}
            style={{ height }}
            scrollWheelZoom={!disabled}
            className="z-0"
          >
            <leaflet.TileLayer
              attribution="&copy; OpenStreetMap contributors"
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />

            <ClickCatcher />

            {showPolyline && routeLatLngs.length >= 2 && (
              <leaflet.Polyline
                positions={routeLatLngs}
                pathOptions={{
                  color: '#0EA5E9',
                  weight: 4,
                }}
              />
            )}

            {showMarkers &&
              normalizedPoints.map((p, idx) => (
                <leaflet.CircleMarker
                  key={p.id ?? `${p.lat}-${p.lng}-${idx}`}
                  center={[p.lat, p.lng]}
                  radius={7}
                  pathOptions={{
                    color: '#0369A1',
                    fillColor: '#0284C7',
                    fillOpacity: 0.9,
                  }}
                >
                  <leaflet.Tooltip
                    direction="top"
                    offset={[0, -8]}
                    opacity={0.95}
                  >
                    #{Number(p.stop_order ?? idx)}
                  </leaflet.Tooltip>
                </leaflet.CircleMarker>
              ))}

            <leaflet.Marker
              position={pos}
              draggable={!disabled}
              eventHandlers={markerHandlers}
            />
          </leaflet.MapContainer>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        <div>
          <label className="block text-sm text-slate-600">Latitud</label>

          <input
            readOnly
            value={pos[0]}
            className="w-full border border-slate-300 p-2 rounded-lg text-black bg-slate-100 cursor-not-allowed"
          />
        </div>

        <div>
          <label className="block text-sm text-slate-600">Longitud</label>

          <input
            readOnly
            value={pos[1]}
            className="w-full border border-slate-300 p-2 rounded-lg text-black bg-slate-100 cursor-not-allowed"
          />
        </div>
      </div>
    </div>
  );
}