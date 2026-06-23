"use client";

import React from "react";
import { MapContainer, TileLayer, Marker, Polyline, Popup } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

interface Driver {
  id: string;
  name: string;
  phone: string;
  carType: string;
  carPlate: string;
  lat: number;
  lng: number;
  heading: number;
  speed: number;
  status: "online" | "in_ride" | "arriving";
  walletBalance: number;
  rideId?: string;
  lastSeen: string;
}

interface Station {
  id: string;
  name: string;
  nameAr: string;
  lat: number;
  lng: number;
  address: string;
  totalChargers: number;
  availableChargers: number;
  operator: string;
  source: string;
}

interface Ride {
  id: string;
  status: string;
  car_type: string;
  pickup_lat: number;
  pickup_lng: number;
  dropoff_lat: number;
  dropoff_lng: number;
  pickup_address: string;
  dropoff_address: string;
  total_fare: number;
  passenger_name: string;
  driver_name?: string;
  driver_id?: string;
}

interface MapLiveComponentProps {
  drivers: Driver[];
  stations: Station[];
  rides: Ride[];
  selectedDriver: Driver | null;
  onSelectDriver: (driver: Driver | null) => void;
}

// Custom markers creators
const createDriverIcon = (status: string, carType: string) => {
  const color = status === "online" ? "#00C853" : status === "in_ride" ? "#2979FF" : "#FF9100";
  const emoji = carType === "ev_luxury" ? "🏎️" : carType === "ev_suv" ? "🛻" : carType === "ev_taxi" ? "🚕" : "🚗";
  return L.divIcon({
    className: `custom-driver-pin-${status}`,
    html: `<div style="background-color: #0B0F19; width: 34px; height: 34px; border-radius: 50%; border: 3px solid ${color}; box-shadow: 0 0 12px ${color}; display: flex; align-items: center; justify-content: center; font-size: 16px; transform: translate(-2px, -2px); transition: all 0.3s ease;">${emoji}</div>`,
    iconSize: [34, 34],
    iconAnchor: [17, 17],
  });
};

const stationIcon = L.divIcon({
  className: "custom-station-pin",
  html: `<div style="background-color: #0B0F19; width: 26px; height: 26px; border-radius: 50%; border: 2px solid #00E5FF; box-shadow: 0 0 8px #00E5FF; display: flex; align-items: center; justify-content: center; font-size: 10px; transform: translate(-2px, -2px);">⚡</div>`,
  iconSize: [26, 26],
  iconAnchor: [13, 13],
});

const pickupIcon = L.divIcon({
  className: "custom-pickup-pin",
  html: `<div style="background-color: #FF1744; width: 14px; height: 14px; border-radius: 50%; border: 2px solid #ffffff; box-shadow: 0 0 6px #FF1744; transform: translate(-2px, -2px);"></div>`,
  iconSize: [14, 14],
  iconAnchor: [7, 7],
});

const dropoffIcon = L.divIcon({
  className: "custom-dropoff-pin",
  html: `<div style="background-color: #00E676; width: 14px; height: 14px; border-radius: 50%; border: 2px solid #ffffff; box-shadow: 0 0 6px #00E676; transform: translate(-2px, -2px);"></div>`,
  iconSize: [14, 14],
  iconAnchor: [7, 7],
});

export default function MapLiveComponent({ drivers, stations, rides, selectedDriver, onSelectDriver }: MapLiveComponentProps) {
  const center: [number, number] = [31.9539, 35.9106]; // Amman center

  return (
    <div className="w-full h-full relative" style={{ minHeight: "500px" }}>
      <MapContainer 
        center={center} 
        zoom={12} 
        style={{ height: "100%", width: "100%", background: "#0B1221" }}
        zoomControl={false}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        />

        {/* Stations */}
        {stations.map(station => (
          <Marker 
            key={`station-${station.id}`} 
            position={[station.lat, station.lng]} 
            icon={stationIcon}
          >
            <Popup>
              <div className="text-right p-1 font-alexandria text-black">
                <p className="font-bold text-sm">{station.nameAr}</p>
                <p className="text-xs text-gray-500 mt-1">{station.address}</p>
                <p className="text-xs font-bold text-emerald-600 mt-1">🔌 {station.availableChargers} / {station.totalChargers} متاح</p>
              </div>
            </Popup>
          </Marker>
        ))}

        {/* Drivers */}
        {drivers.map(driver => (
          <Marker
            key={`driver-${driver.id}`}
            position={[driver.lat, driver.lng]}
            icon={createDriverIcon(driver.status, driver.carType)}
            eventHandlers={{
              click: () => onSelectDriver(driver),
            }}
          >
            <Popup>
              <div className="text-right p-1 font-alexandria text-black">
                <p className="font-bold text-sm">{driver.name}</p>
                <p className="text-xs text-gray-500 mt-0.5">{driver.carPlate}</p>
                <p className="text-xs text-gray-700 mt-1">السرعة: {driver.speed} كم/س</p>
                <p className="text-xs text-gray-700">المحفظة: {driver.walletBalance.toFixed(2)} د.أ</p>
              </div>
            </Popup>
          </Marker>
        ))}

        {/* Rides */}
        {rides.map(ride => {
          const hasPickup = ride.pickup_lat && ride.pickup_lng;
          const hasDropoff = ride.dropoff_lat && ride.dropoff_lng;
          if (!hasPickup || !hasDropoff) return null;

          const pickupPos: [number, number] = [ride.pickup_lat, ride.pickup_lng];
          const dropoffPos: [number, number] = [ride.dropoff_lat, ride.dropoff_lng];

          return (
            <React.Fragment key={`ride-elements-${ride.id}`}>
              <Marker position={pickupPos} icon={pickupIcon}>
                <Popup>
                  <div className="text-right p-1 font-alexandria text-black">
                    <p className="font-bold text-xs text-red-600">📍 موقع الالتقاء</p>
                    <p className="text-xs font-bold mt-1">{ride.passenger_name}</p>
                    <p className="text-xs text-gray-500 mt-0.5">{ride.pickup_address}</p>
                  </div>
                </Popup>
              </Marker>

              <Marker position={dropoffPos} icon={dropoffIcon}>
                <Popup>
                  <div className="text-right p-1 font-alexandria text-black">
                    <p className="font-bold text-xs text-emerald-600">🏁 موقع التنزيل</p>
                    <p className="text-xs font-bold mt-1">{ride.passenger_name}</p>
                    <p className="text-xs text-gray-500 mt-0.5">{ride.dropoff_address}</p>
                  </div>
                </Popup>
              </Marker>

              <Polyline 
                positions={[pickupPos, dropoffPos]} 
                pathOptions={{
                  color: ride.status === 'in_progress' ? '#2979FF' : '#FF9100',
                  weight: 3,
                  dashArray: "5, 10",
                  opacity: 0.8
                }}
              />
            </React.Fragment>
          );
        })}
      </MapContainer>
    </div>
  );
}
