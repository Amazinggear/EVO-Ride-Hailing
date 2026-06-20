"use client";

import { useEffect } from "react";
import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

// EV themed custom green glowing marker icon to prevent Next.js relative path asset bugs
const chargerIcon = L.divIcon({
  className: "custom-charger-pin",
  html: `<div style="background-color: var(--color-brand-500, #00C853); width: 28px; height: 28px; border-radius: 50%; border: 3px solid #0B0F19; box-shadow: 0 0 15px rgba(0,200,83,0.7); display: flex; align-items: center; justify-content: center; font-size: 12px; color: white; transform: translate(-2px, -2px);">⚡</div>`,
  iconSize: [28, 28],
  iconAnchor: [14, 14],
});

interface MapPickerProps {
  lat: number;
  lng: number;
  onChange: (lat: number, lng: number) => void;
}

// Click listener inside React Leaflet context
function MapClickEvents({ onClick }: { onClick: (lat: number, lng: number) => void }) {
  useMapEvents({
    click(e) {
      onClick(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

export default function MapPickerComponent({ lat, lng, onChange }: MapPickerProps) {
  useEffect(() => {
    // Reset icon option
    L.Marker.prototype.options.icon = chargerIcon;
  }, []);

  const position: [number, number] = [lat || 31.9539, lng || 35.9106];

  return (
    <div className="w-full h-[240px] rounded-xl overflow-hidden border border-white/10 relative z-20 shadow-inner">
      <MapContainer 
        center={position} 
        zoom={13} 
        style={{ height: "100%", width: "100%", background: "#0B1221" }}
        zoomControl={false}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png" // Dark theme tile layer
        />
        <Marker position={position} icon={chargerIcon} />
        <MapClickEvents onClick={onChange} />
      </MapContainer>
      <div className="absolute bottom-2 right-2 bg-black/70 backdrop-blur-sm px-2.5 py-1 rounded-lg text-[10px] text-gray-400 font-bold border border-white/5 pointer-events-none z-[1000]">
        📍 انقر على الخريطة لتحديد مكان المحطة بدقة
      </div>
    </div>
  );
}
