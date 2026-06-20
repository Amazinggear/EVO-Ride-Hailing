// lib/features/driver/charging_stations/presentation/screens/driver_charging_stations_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
// EVO Driver — Charging Stations Screen
// Shows nearby EV charging stations with type, availability, and distance
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

// ── Model ───────────────────────────────────────────────────────────────────
class ChargingStationInfo {
  final String id;
  final String nameAr;
  final String nameEn;
  final double lat;
  final double lng;
  final String address;
  final List<String> chargerTypes;
  final int totalChargers;
  final int availableChargers;
  final String operator;
  final bool isVerified;
  double? distanceKm;

  ChargingStationInfo({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.lat,
    required this.lng,
    required this.address,
    required this.chargerTypes,
    required this.totalChargers,
    required this.availableChargers,
    required this.operator,
    required this.isVerified,
    this.distanceKm,
  });

  factory ChargingStationInfo.fromJson(Map<String, dynamic> j) {
    return ChargingStationInfo(
      id: j['id'] ?? '',
      nameAr: j['name_ar'] ?? j['nameAr'] ?? 'محطة شحن',
      nameEn: j['name'] ?? j['nameEn'] ?? 'Charging Station',
      lat: double.tryParse(j['lat']?.toString() ?? '0') ?? 0,
      lng: double.tryParse(j['lng']?.toString() ?? '0') ?? 0,
      address: j['address'] ?? '',
      chargerTypes: List<String>.from(j['charger_types'] ?? j['chargerTypes'] ?? []),
      totalChargers: j['total_chargers'] ?? j['totalChargers'] ?? 0,
      availableChargers: j['available_chargers'] ?? j['availableChargers'] ?? 0,
      operator: j['operator'] ?? '',
      isVerified: j['is_verified'] ?? j['isVerified'] ?? false,
    );
  }
}

// ── Mock Data ────────────────────────────────────────────────────────────────
final _mockStations = [
  ChargingStationInfo(id: '1', nameAr: 'محطة شحن مكة مول', nameEn: 'Mecca Mall EV Station', lat: 31.9541, lng: 35.8836, address: 'مكة مول، الرابع، عمّان', chargerTypes: ['Type2', 'CCS'], totalChargers: 8, availableChargers: 5, operator: 'Zain EV', isVerified: true),
  ChargingStationInfo(id: '2', nameAr: 'مركز شحن سيتي مول', nameEn: 'City Mall Charging Hub', lat: 31.9757, lng: 35.9058, address: 'سيتي مول، تلاع العلي', chargerTypes: ['Type2', 'CHAdeMO', 'CCS'], totalChargers: 12, availableChargers: 8, operator: 'Orange EV', isVerified: true),
  ChargingStationInfo(id: '3', nameAr: 'محطة العبدلي', nameEn: 'Al-Abdali Station', lat: 31.9757, lng: 35.9244, address: 'العبدلي، وسط البلد', chargerTypes: ['CCS'], totalChargers: 4, availableChargers: 2, operator: 'حكومية', isVerified: false),
  ChargingStationInfo(id: '4', nameAr: 'شاحن موتور سيتي', nameEn: 'Motor City Charger', lat: 31.9406, lng: 35.8672, address: 'ماركا الجنوبية، عمّان', chargerTypes: ['Type2', 'CCS'], totalChargers: 6, availableChargers: 4, operator: 'Aramex EV', isVerified: true),
  ChargingStationInfo(id: '5', nameAr: 'نقطة شحن الصويفية', nameEn: 'Swefieh EV Point', lat: 31.9573, lng: 35.8789, address: 'الصويفية، عمّان', chargerTypes: ['Type2'], totalChargers: 3, availableChargers: 0, operator: 'خاص', isVerified: false),
];

// ── Screen ───────────────────────────────────────────────────────────────────
class DriverChargingStationsScreen extends StatefulWidget {
  const DriverChargingStationsScreen({super.key});

  @override
  State<DriverChargingStationsScreen> createState() => _DriverChargingStationsScreenState();
}

class _DriverChargingStationsScreenState extends State<DriverChargingStationsScreen> {
  List<ChargingStationInfo> _stations = [];
  bool _loading = true;
  String _filter = 'all'; // all | available | verified
  Position? _myPosition;
  String _search = '';
  final _searchController = TextEditingController();

  static const _kGreen = Color(0xFF00C853);
  static const _kLightGreen = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Try getting user location
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.denied) {
        _myPosition = await Geolocator.getCurrentPosition();
      }
    } catch (_) {}

    // Compute distances
    final stations = List<ChargingStationInfo>.from(_mockStations);
    if (_myPosition != null) {
      for (final s in stations) {
        s.distanceKm = Geolocator.distanceBetween(_myPosition!.latitude, _myPosition!.longitude, s.lat, s.lng) / 1000;
      }
      stations.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
    }

    setState(() {
      _stations = stations;
      _loading = false;
    });
  }

  List<ChargingStationInfo> get _filtered {
    return _stations.where((s) {
      final matchSearch = _search.isEmpty || s.nameAr.contains(_search) || s.address.contains(_search);
      final matchFilter = _filter == 'all'
          ? true
          : _filter == 'available'
              ? s.availableChargers > 0
              : s.isVerified;
      return matchSearch && matchFilter;
    }).toList();
  }

  void _openInMaps(ChargingStationInfo station) {
    // In production: launch Google Maps URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('الانتقال إلى ${station.nameAr}', style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: _kGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('محطات الشحن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: Color(0xFF212121))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF212121)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: _kGreen),
            onPressed: _loadData,
            tooltip: 'تحديث الموقع',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن محطة شحن...',
                      hintStyle: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF9E9E9E), fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9E9E9E), size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterPill(label: 'الكل', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                      const SizedBox(width: 8),
                      _FilterPill(label: '🔌 متاحة', selected: _filter == 'available', onTap: () => setState(() => _filter = 'available')),
                      const SizedBox(width: 8),
                      _FilterPill(label: '✅ موثّقة', selected: _filter == 'verified', onTap: () => setState(() => _filter = 'verified')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Summary bar
          if (!_loading)
            Container(
              color: _kLightGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.ev_station_rounded, color: _kGreen, size: 16),
                  const SizedBox(width: 6),
                  Text('${_filtered.length} محطة قريبة منك', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen)),
                  const Spacer(),
                  if (_myPosition != null)
                    const Text('📍 موقعك محدّد', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF4CAF50))),
                ],
              ),
            ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kGreen))
                : _filtered.isEmpty
                    ? _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _StationCard(station: _filtered[i], onNavigate: () => _openInMaps(_filtered[i])),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ── Station Card ─────────────────────────────────────────────────────────────
class _StationCard extends StatelessWidget {
  final ChargingStationInfo station;
  final VoidCallback onNavigate;

  static const _kGreen = Color(0xFF00C853);

  const _StationCard({required this.station, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isAvailable = station.availableChargers > 0;
    final availabilityPct = station.totalChargers > 0
        ? station.availableChargers / station.totalChargers
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3F3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.ev_station_rounded, color: isAvailable ? _kGreen : const Color(0xFFE53935), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(station.nameAr, style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                          if (station.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.verified_rounded, size: 10, color: _kGreen),
                                SizedBox(width: 2),
                                Text('موثّق', style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: _kGreen, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(station.address, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF757575)), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Charger types
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: station.chargerTypes.map((t) {
                final color = t == 'CCS' ? _kGreen : t == 'CHAdeMO' ? const Color(0xFFFF8F00) : const Color(0xFF1565C0);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
                  child: Text(t, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Availability bar
            Row(
              children: [
                Text('${station.availableChargers}/${station.totalChargers} متاح', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700, color: isAvailable ? _kGreen : const Color(0xFFE53935))),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: availabilityPct,
                      backgroundColor: const Color(0xFFEEEEEE),
                      color: isAvailable ? _kGreen : const Color(0xFFE53935),
                      minHeight: 6,
                    ),
                  ),
                ),
                if (station.distanceKm != null) ...[
                  const SizedBox(width: 10),
                  Text('${station.distanceKm!.toStringAsFixed(1)} كم', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF9E9E9E))),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Navigate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAvailable ? _kGreen : const Color(0xFF9E9E9E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: isAvailable ? onNavigate : null,
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: Text(
                  isAvailable ? 'التنقل إلى المحطة' : 'غير متاحة حالياً',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00C853) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF00C853) : const Color(0xFFE0E0E0)),
        ),
        child: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : const Color(0xFF757575))),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ev_station_rounded, size: 72, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 16),
            const Text('لا توجد محطات في منطقتك', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF424242))),
            const SizedBox(height: 8),
            const Text('حاول توسيع نطاق البحث أو تغيير المرشّح', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Color(0xFF9E9E9E)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
