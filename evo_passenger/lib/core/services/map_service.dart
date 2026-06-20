// lib/core/services/map_service.dart
// ══════════════════════════════════════════════════════════════════════════════
// EVO Map Service — OpenStreetMap (flutter_map) + Nominatim + OSRM
// 100% Free — No API Key Required
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ── Place Result (returned from search) ─────────────────────────────────────
class EvoPlace {
  final String displayName;
  final String shortName;
  final LatLng location;
  final String? city;
  final String? country;

  const EvoPlace({
    required this.displayName,
    required this.shortName,
    required this.location,
    this.city,
    this.country,
  });
}

// ── Route Result (returned from OSRM) ────────────────────────────────────────
class EvoRoute {
  final List<LatLng> points;   // polyline points
  final double distanceKm;
  final int durationSeconds;

  const EvoRoute({
    required this.points,
    required this.distanceKm,
    required this.durationSeconds,
  });

  String get durationFormatted {
    final minutes = (durationSeconds / 60).ceil();
    if (minutes < 60) return '$minutes دقيقة';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours س${mins > 0 ? ' $mins د' : ''}';
  }

  String get distanceFormatted {
    if (distanceKm < 1) return '${(distanceKm * 1000).toStringAsFixed(0)} م';
    return '${distanceKm.toStringAsFixed(1)} كم';
  }
}

// ── Map Service ───────────────────────────────────────────────────────────────
class MapService {
  // Nominatim — geocoding (address ↔ coordinates)
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';

  // OSRM — routing (directions + polyline)
  static const String _osrmBase = 'https://router.project-osrm.org/route/v1/driving';

  static const Map<String, String> _headers = {
    'User-Agent': 'EVO-RideHailing/1.0 (contact@evo.jo)',
    'Accept-Language': 'ar,en',
  };

  // ── Search places by text ─────────────────────────────────────────────────
  static Future<List<EvoPlace>> searchPlaces(String query, {
    // Bias towards Jordan (Amman)
    double viewboxMinLat = 29.0,
    double viewboxMaxLat = 33.5,
    double viewboxMinLng = 35.0,
    double viewboxMaxLng = 39.5,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_nominatimBase/search').replace(queryParameters: {
        'q': query,
        'format': 'json',
        'limit': '8',
        'countrycodes': 'jo',  // Prioritize Jordan
        'addressdetails': '1',
        'viewbox': '$viewboxMinLng,$viewboxMaxLat,$viewboxMaxLng,$viewboxMinLat',
        'bounded': '0',
      });

      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final List<dynamic> results = json.decode(response.body);
      return results.map((r) {
        final address = r['address'] as Map<String, dynamic>? ?? {};
        final displayName = r['display_name'] as String? ?? '';
        
        // Build a short human-readable name
        final shortParts = <String>[
          if (address['road'] != null) address['road'],
          if (address['suburb'] != null) address['suburb'],
          if (address['city'] != null || address['town'] != null)
            (address['city'] ?? address['town']),
        ];
        
        final shortName = shortParts.isNotEmpty
            ? shortParts.take(2).join('، ')
            : displayName.split(',').first;

        return EvoPlace(
          displayName: displayName,
          shortName: shortName,
          location: LatLng(
            double.parse(r['lat'].toString()),
            double.parse(r['lon'].toString()),
          ),
          city: address['city'] ?? address['town'],
          country: address['country'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Reverse geocode: coordinates → address ────────────────────────────────
  static Future<String?> reverseGeocode(LatLng location) async {
    try {
      final uri = Uri.parse('$_nominatimBase/reverse').replace(queryParameters: {
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'format': 'json',
        'zoom': '18',
      });

      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;
      final data = json.decode(response.body);
      return data['display_name'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ── Get route between two points (OSRM) ──────────────────────────────────
  static Future<EvoRoute?> getRoute(LatLng from, LatLng to) async {
    try {
      final url = '$_osrmBase/'
          '${from.longitude},${from.latitude};'
          '${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson&steps=false';

      final response = await http.get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;

      // Convert [lng, lat] pairs to LatLng list
      final points = coordinates
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();

      return EvoRoute(
        points: points,
        distanceKm: (route['distance'] as num).toDouble() / 1000,
        durationSeconds: (route['duration'] as num).toInt(),
      );
    } catch (e) {
      return null;
    }
  }

  // ── Calculate straight-line distance ─────────────────────────────────────
  static double calculateDistance(LatLng from, LatLng to) {
    const distance = Distance();
    return distance(from, to) / 1000; // km
  }
}
