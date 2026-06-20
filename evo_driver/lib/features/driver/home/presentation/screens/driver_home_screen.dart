import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:evo_driver/core/constants/evo_colors.dart';

/// Driver Home Screen — Dark Theme with OSM flutter_map
/// Based on Screen 3 reference design:
/// - Go Online/Offline toggle (pill switch)
/// - Dark Carto map with demand heatmap overlay
/// - Daily earnings + CO₂ stats cards
/// - Charging Stations CTA button

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isOnline = false;
  Position? _currentPosition;
  late AnimationController _onlineAnimController;
  late Animation<double> _onlinePulse;

  // Default to Amman, Jordan
  LatLng _center = const LatLng(31.9539, 35.9106);

  @override
  void initState() {
    super.initState();
    _onlineAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _onlinePulse = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _onlineAnimController, curve: Curves.easeInOut),
    );
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    final pos = await Geolocator.getCurrentPosition();
    final loc = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _currentPosition = pos;
      _center = loc;
    });
    _mapController.move(loc, 14.0);
  }

  void _toggleOnline(bool value) {
    setState(() => _isOnline = value);
    // TODO: Send to backend via BLoC
    // context.read<DriverBloc>().add(ToggleOnlineEvent(isOnline: value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvoColors.darkBg,
      body: Stack(
        children: [
          // ──────────────────────────
          // Dark OSM Map (Carto DarkMatter)
          // ──────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Carto Dark Matter tile layer
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.evo.driver',
                maxZoom: 20,
              ),

              // Driver location marker
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 48,
                      height: 48,
                      child: _DriverMarkerIcon(isOnline: _isOnline),
                    ),
                  ],
                ),
            ],
          ),

          // Demand Heatmap Overlay
          _buildHeatmapOverlay(),

          // ──────────────────────────
          // Top: Go Online Toggle
          // ──────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _GoOnlineToggle(
                  isOnline: _isOnline,
                  onChanged: _toggleOnline,
                  pulseAnimation: _onlinePulse,
                ),
              ),
            ),
          ),

          // ──────────────────────────
          // My Location Button
          // ──────────────────────────
          Positioned(
            right: 16,
            bottom: 260,
            child: GestureDetector(
              onTap: _getCurrentLocation,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: EvoColors.darkCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: EvoColors.primary.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: EvoColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),

          // ──────────────────────────
          // Bottom: Stats + CTA
          // ──────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _DriverBottomPanel(isOnline: _isOnline),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _HeatmapPainter(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _onlineAnimController.dispose();
    super.dispose();
  }
}

// Electric Car Marker Icon
class _DriverMarkerIcon extends StatelessWidget {
  final bool isOnline;
  const _DriverMarkerIcon({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? EvoColors.primary : Colors.grey.shade700,
        boxShadow: [
          BoxShadow(
            color: isOnline
                ? EvoColors.primary.withOpacity(0.5)
                : Colors.transparent,
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.electric_car,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

// Go Online Pill Toggle
class _GoOnlineToggle extends StatelessWidget {
  final bool isOnline;
  final void Function(bool) onChanged;
  final Animation<double> pulseAnimation;

  const _GoOnlineToggle({
    required this.isOnline,
    required this.onChanged,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: EvoColors.darkCard,
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (_, __) => Transform.scale(
                  scale: isOnline ? pulseAnimation.value : 1.0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? EvoColors.primary : Colors.grey,
                      boxShadow: isOnline
                          ? [BoxShadow(color: EvoColors.primary.withOpacity(0.5), blurRadius: 8)]
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isOnline ? 'أنت متاح' : 'غير متاح',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: isOnline ? EvoColors.primary : Colors.grey,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Switch.adaptive(
            value: isOnline,
            onChanged: onChanged,
            activeColor: EvoColors.primary,
            inactiveThumbColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}

// Bottom Stats Panel
class _DriverBottomPanel extends StatelessWidget {
  final bool isOnline;

  const _DriverBottomPanel({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EvoColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Stats Cards Row
          const Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'أرباح اليوم',
                  value: '120.50 JOD',
                  subtitle: '14 رحلة',
                  icon: Icons.account_balance_wallet_outlined,
                  color: EvoColors.primary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'CO₂ الموفّر',
                  value: '8.2 كجم',
                  subtitle: 'اليوم',
                  icon: Icons.eco_rounded,
                  color: EvoColors.ecoIcon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Charging Stations CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/charging-stations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EvoColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.ev_station_rounded, color: Colors.white),
              label: const Text(
                '⚡ محطات شحن قريبة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EvoColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: Colors.white60,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple Heatmap Painter (placeholder — in prod: use TileOverlay)
class _HeatmapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Hot zones (red/orange for high demand)
    paint.color = Colors.red.withOpacity(0.15);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.4), 60, paint);

    paint.color = Colors.orange.withOpacity(0.10);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.5), 80, paint);

    // Warm zones (green for moderate demand)
    paint.color = Colors.green.withOpacity(0.08);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.6), 50, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
