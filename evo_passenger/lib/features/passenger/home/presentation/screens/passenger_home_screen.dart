// lib/features/passenger/home/presentation/screens/passenger_home_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
// EVO Passenger Home Screen — flutter_map (OpenStreetMap)
// No Google Maps API Key required!
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:evo_passenger/core/di/injection_container.dart';
import 'package:evo_passenger/core/services/map_service.dart';
import 'package:evo_passenger/features/passenger/ride_booking/presentation/bloc/booking_bloc.dart';
import 'package:evo_passenger/features/passenger/ride_booking/presentation/bloc/booking_event.dart';
import 'package:evo_passenger/features/passenger/ride_booking/presentation/bloc/booking_state.dart';
import '../widgets/ev_type_selector.dart';

// Amman center coordinates
const _ammanLatLng = LatLng(31.9539, 35.9106);
const _kGreen = Color(0xFF00C853);
const _kDark = Color(0xFF1A1F2E);

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  LatLng? _currentPosition;
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  String? _pickupName;
  String? _dropoffName;
  List<LatLng> _routePoints = [];
  EvoRoute? _currentRoute;

  // Driver tracking (updated via Socket.io)
  LatLng? _driverPosition;
  double _driverHeading = 0;

  // UI state
  bool _showVehicleSelector = false;
  bool _isLoadingRoute = false;
  String? _selectedCarType = 'ev_sedan'; // default selection
  final _searchController = TextEditingController();
  List<EvoPlace> _searchResults = [];
  bool _searchingForDropoff = false;


  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);

      // Reverse geocode to get address name
      final name = await MapService.reverseGeocode(latLng);

      if (mounted) {
        setState(() {
          _currentPosition = latLng;
          _pickupLatLng = latLng;
          _pickupName = name?.split(',').first ?? 'موقعي الحالي';
        });
        _mapController.move(latLng, 15.0);
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await MapService.searchPlaces(query);
    if (mounted) setState(() => _searchResults = results);
  }

  void _selectPlace(EvoPlace place) {
    setState(() {
      _searchResults = [];
      _searchController.clear();
      if (_searchingForDropoff) {
        _dropoffLatLng = place.location;
        _dropoffName = place.shortName;
      } else {
        _pickupLatLng = place.location;
        _pickupName = place.shortName;
      }
    });
    _mapController.move(place.location, 15.0);

    // If we have both pickup and dropoff, get route
    if (_pickupLatLng != null && _dropoffLatLng != null) {
      _fetchRoute();
      setState(() => _showVehicleSelector = true);
    }
  }

  Future<void> _fetchRoute() async {
    if (_pickupLatLng == null || _dropoffLatLng == null) return;
    setState(() => _isLoadingRoute = true);

    final route = await MapService.getRoute(_pickupLatLng!, _dropoffLatLng!);

    if (mounted) {
      setState(() {
        _currentRoute = route;
        _routePoints = route?.points ?? [];
        _isLoadingRoute = false;
      });

      if (route != null && _routePoints.isNotEmpty) {
        // Fit map to show full route
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(_routePoints),
            padding: const EdgeInsets.all(64),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingBloc>(),
      child: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is RideMatchedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ تم إيجاد كابتن! جاري التتبع...'),
                backgroundColor: _kGreen,
              ),
            );
            // context.pushNamed('ride-tracking', extra: state.rideData);
          } else if (state is BookingErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, bookingState) {
          return Scaffold(
            body: Stack(
              children: [
                // ── Full-Screen Map (flutter_map + OSM) ──────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _ammanLatLng,
                    initialZoom: 13.0,
                    minZoom: 5,
                    maxZoom: 19,
                    onTap: (tapPos, latLng) {
                      // Set dropoff on tap
                      if (_pickupLatLng != null && _dropoffLatLng == null) {
                        setState(() => _dropoffLatLng = latLng);
                        _fetchRoute();
                        setState(() => _showVehicleSelector = true);
                      }
                    },
                  ),
                  children: [
                    // OSM Tile Layer
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.evo.passenger',
                      retinaMode: MediaQuery.of(context).devicePixelRatio > 1.5,
                    ),

                    // Route Polyline
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5.0,
                            color: _kGreen,
                            borderStrokeWidth: 2.0,
                            borderColor: _kGreen.withOpacity(0.3),
                          ),
                        ],
                      ),

                    // Markers
                    MarkerLayer(
                      markers: [
                        // Current location blue dot
                        if (_currentPosition != null)
                          Marker(
                            point: _currentPosition!,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8)],
                              ),
                            ),
                          ),

                        // Pickup marker (green)
                        if (_pickupLatLng != null)
                          Marker(
                            point: _pickupLatLng!,
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: const Icon(Icons.location_on, color: _kGreen, size: 40),
                          ),

                        // Dropoff marker (red)
                        if (_dropoffLatLng != null)
                          Marker(
                            point: _dropoffLatLng!,
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),

                        // Driver marker (animated electric car icon)
                        if (_driverPosition != null)
                          Marker(
                            point: _driverPosition!,
                            width: 44,
                            height: 44,
                            child: Transform.rotate(
                              angle: _driverHeading * 3.14159 / 180,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _kDark,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.5), blurRadius: 12)],
                                ),
                                child: const Icon(Icons.electric_car, color: _kGreen, size: 24),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // OSM Attribution (required by OSM license)
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),

                // ── Top Search Bar ────────────────────────────────────────
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _buildSearchCard(),
                      ),

                      // Search Results Dropdown
                      if (_searchResults.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildSearchResults(),
                        ),
                    ],
                  ),
                ),

                // ── Route Info Banner ─────────────────────────────────────
                if (_currentRoute != null && !_showVehicleSelector)
                  Positioned(
                    bottom: 120,
                    left: 16,
                    right: 16,
                    child: _buildRouteInfoBanner(),
                  ),

                // ── Vehicle Selector (bottom sheet style) ─────────────────
                if (_showVehicleSelector && _dropoffLatLng != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildVehicleSelectorSheet(context, bookingState),
                  ),

                // ── My Location Button ────────────────────────────────────
                Positioned(
                  right: 16,
                  bottom: _showVehicleSelector ? 320 : 80,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    onPressed: () {
                      if (_currentPosition != null) {
                        _mapController.move(_currentPosition!, 15.0);
                      } else {
                        _initLocation();
                      }
                    },
                    child: const Icon(Icons.my_location, color: _kGreen),
                  ),
                ),

                // ── Loading indicator ─────────────────────────────────────
                if (_isLoadingRoute)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(color: _kGreen, minHeight: 3),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Pickup row
          ListTile(
            dense: true,
            leading: Container(width: 10, height: 10, decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle)),
            title: Text(
              _pickupName ?? 'موقعي الحالي',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _pickupName != null
                ? GestureDetector(
                    onTap: () {
                      setState(() { _searchingForDropoff = false; });
                      _searchController.clear();
                    },
                    child: const Icon(Icons.edit, size: 16, color: Colors.grey),
                  )
                : null,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Dropoff row
          ListTile(
            dense: true,
            leading: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.red.shade400, shape: BoxShape.circle)),
            title: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _dropoffLatLng != null ? (_dropoffName ?? 'الوجهة') : 'إلى أين؟',
                hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: _dropoffLatLng != null ? const Color(0xFF212121) : Colors.grey),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              onChanged: (v) {
                setState(() => _searchingForDropoff = true);
                _searchPlaces(v);
              },
            ),
            trailing: _dropoffLatLng != null
                ? GestureDetector(
                    onTap: () => setState(() {
                      _dropoffLatLng = null;
                      _dropoffName = null;
                      _routePoints = [];
                      _currentRoute = null;
                      _showVehicleSelector = false;
                    }),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.take(5).length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 48),
        itemBuilder: (_, i) {
          final place = _searchResults[i];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
            title: Text(place.shortName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(place.city ?? '', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey)),
            onTap: () => _selectPlace(place),
          );
        },
      ),
    );
  }

  Widget _buildRouteInfoBanner() {
    if (_currentRoute == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _RouteInfo(icon: Icons.route, label: _currentRoute!.distanceFormatted, sublabel: 'المسافة'),
          const VerticalDivider(),
          _RouteInfo(icon: Icons.timer, label: _currentRoute!.durationFormatted, sublabel: 'الوقت'),
          const VerticalDivider(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _showVehicleSelector = true),
            child: const Text('اختر سيارة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelectorSheet(BuildContext context, BookingState bookingState) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x20000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('اختر نوع السيارة', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 8),
          EvTypeSelector(
            selectedType: _selectedCarType ?? 'ev_sedan',
            distanceKm: _currentRoute?.distanceKm ?? 0,
            durationMin: (_currentRoute?.durationSeconds ?? 0) ~/ 60,

            onVehicleSelected: (carType, fare) {
              setState(() => _selectedCarType = carType);
              if (_pickupLatLng != null && _dropoffLatLng != null) {
                context.read<BookingBloc>().add(
                  RequestRideEvent(
                    pickupLat: _pickupLatLng!.latitude,
                    pickupLng: _pickupLatLng!.longitude,
                    dropoffLat: _dropoffLatLng!.latitude,
                    dropoffLng: _dropoffLatLng!.longitude,
                    carType: carType,
                    estimatedFare: fare,
                    pickupAddress: _pickupName ?? '',
                    dropoffAddress: _dropoffName ?? '',
                  ),
                );
              }
            },

          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RouteInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  const _RouteInfo({required this.icon, required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _kGreen, size: 20),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w800)),
        Text(sublabel, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
