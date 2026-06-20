// lib/features/passenger/ride_history/presentation/screens/ride_history_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
// EVO Passenger — Ride History Screen
// Shows paginated list of past rides with fare, route, status & rating
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:evo_passenger/core/constants/evo_colors.dart';
import 'package:evo_passenger/core/di/injection_container.dart';

// ── Model ──────────────────────────────────────────────────────────────────
class RideHistoryItem {
  final String id;
  final String pickupAddress;
  final String dropoffAddress;
  final double totalFare;
  final String carType;
  final String status;
  final DateTime createdAt;
  final double? driverRating;
  final String? driverName;
  final double? distanceKm;
  final int? durationMin;

  const RideHistoryItem({
    required this.id,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.totalFare,
    required this.carType,
    required this.status,
    required this.createdAt,
    this.driverRating,
    this.driverName,
    this.distanceKm,
    this.durationMin,
  });

  factory RideHistoryItem.fromJson(Map<String, dynamic> json) {
    return RideHistoryItem(
      id: json['id'] ?? '',
      pickupAddress: json['pickup_address'] ?? json['pickupAddress'] ?? 'موقع الانطلاق',
      dropoffAddress: json['dropoff_address'] ?? json['dropoffAddress'] ?? 'الوجهة',
      totalFare: double.tryParse(json['total_fare']?.toString() ?? '0') ?? 0.0,
      carType: json['car_type'] ?? json['carType'] ?? 'ev_mini',
      status: json['status'] ?? 'completed',
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      driverRating: double.tryParse(json['driver_rating']?.toString() ?? ''),
      driverName: json['driver_name'] ?? json['driverName'],
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? ''),
      durationMin: json['duration_min'] is int ? json['duration_min'] : null,
    );
  }
}

// ── Mock Data ──────────────────────────────────────────────────────────────
final _mockRides = [
  RideHistoryItem(
    id: 'r001',
    pickupAddress: 'دوار الداخلية، وسط البلد',
    dropoffAddress: 'مجمع الجاردنز، الصويفية',
    totalFare: 4.80,
    carType: 'ev_sedan',
    status: 'completed',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    driverRating: 5.0,
    driverName: 'أحمد الخالدي',
    distanceKm: 8.2,
    durationMin: 18,
  ),
  RideHistoryItem(
    id: 'r002',
    pickupAddress: 'فندق ريجنسي، الشميساني',
    dropoffAddress: 'مطار الملكة علياء',
    totalFare: 18.50,
    carType: 'ev_luxury',
    status: 'completed',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    driverRating: 4.0,
    driverName: 'خالد النجار',
    distanceKm: 32.5,
    durationMin: 42,
  ),
  RideHistoryItem(
    id: 'r003',
    pickupAddress: 'الجامعة الأردنية',
    dropoffAddress: 'مستشفى الأردن',
    totalFare: 3.20,
    carType: 'ev_mini',
    status: 'completed',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    driverRating: 5.0,
    driverName: 'محمد العبادي',
    distanceKm: 5.1,
    durationMin: 12,
  ),
  RideHistoryItem(
    id: 'r004',
    pickupAddress: 'مدينة الحسين للشباب',
    dropoffAddress: 'مجمع تلاع العلي',
    totalFare: 0.0,
    carType: 'ev_taxi',
    status: 'cancelled',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    driverName: null,
    distanceKm: 0,
    durationMin: 0,
  ),
  RideHistoryItem(
    id: 'r005',
    pickupAddress: 'دوار السفارات، الرابع',
    dropoffAddress: 'العبدلي مول',
    totalFare: 6.40,
    carType: 'ev_suv',
    status: 'completed',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    driverRating: 4.0,
    driverName: 'عمر الشرع',
    distanceKm: 11.3,
    durationMin: 25,
  ),
];

// ── Screen ─────────────────────────────────────────────────────────────────
class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<RideHistoryItem> _rides = [];
  bool _loading = true;
  String _filter = 'all'; // all | completed | cancelled

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/api/v1/rides/history');
      final List<dynamic> data = response.data as List? ?? [];
      setState(() {
        _rides = data.map((j) => RideHistoryItem.fromJson(j as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (_) {
      // Use mock data
      setState(() {
        _rides = _mockRides;
        _loading = false;
      });
    }
  }

  List<RideHistoryItem> get _filtered {
    if (_filter == 'all') return _rides;
    return _rides.where((r) => r.status == _filter).toList();
  }

  String _carTypeLabel(String type) {
    const map = {
      'ev_mini': 'EV Mini',
      'ev_taxi': 'EV Taxi',
      'ev_sedan': 'EV Sedan',
      'ev_suv': 'EV SUV',
      'ev_luxury': 'EV Luxury',
    };
    return map[type] ?? type;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvoColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'الرحلات السابقة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: EvoColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: EvoColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _FilterChip(label: 'الكل', value: 'all', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(label: 'مكتملة', value: 'completed', selected: _filter == 'completed', onTap: () => setState(() => _filter = 'completed')),
                const SizedBox(width: 8),
                _FilterChip(label: 'ملغاة', value: 'cancelled', selected: _filter == 'cancelled', onTap: () => setState(() => _filter = 'cancelled')),
              ],
            ),
          ),
          const Divider(height: 1, color: EvoColors.border),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: EvoColors.primary))
                : _filtered.isEmpty
                    ? _EmptyState(filter: _filter)
                    : RefreshIndicator(
                        color: EvoColors.primary,
                        onRefresh: _loadHistory,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _RideCard(
                            ride: _filtered[i],
                            carTypeLabel: _carTypeLabel(_filtered[i].carType),
                            timeAgo: _timeAgo(_filtered[i].createdAt),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Ride Card ──────────────────────────────────────────────────────────────
class _RideCard extends StatelessWidget {
  final RideHistoryItem ride;
  final String carTypeLabel;
  final String timeAgo;

  const _RideCard({required this.ride, required this.carTypeLabel, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final isCompleted = ride.status == 'completed';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: EvoColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: route + status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // From
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: EvoColors.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ride.pickupAddress,
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: EvoColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Container(width: 2, height: 16, color: EvoColors.border),
                      ),
                      // To
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: EvoColors.error, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ride.dropoffAddress,
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: EvoColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCompleted ? EvoColors.primarySubtle : const Color(0xFFFFF3F3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isCompleted ? EvoColors.primary : EvoColors.error, width: 0.5),
                  ),
                  child: Text(
                    isCompleted ? 'مكتملة' : 'ملغاة',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: isCompleted ? EvoColors.primary : EvoColors.error),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: EvoColors.border, height: 1),
            const SizedBox(height: 12),

            // Bottom row: meta info
            Row(
              children: [
                // Car type
                _MetaChip(icon: Icons.electric_car_outlined, label: carTypeLabel),
                const SizedBox(width: 8),
                if (ride.distanceKm != null && ride.distanceKm! > 0)
                  _MetaChip(icon: Icons.straighten, label: '${ride.distanceKm!.toStringAsFixed(1)} كم'),
                if (ride.durationMin != null && ride.durationMin! > 0) ...[
                  const SizedBox(width: 8),
                  _MetaChip(icon: Icons.schedule, label: '${ride.durationMin} د'),
                ],
                const Spacer(),
                // Fare
                if (isCompleted)
                  Text(
                    '${ride.totalFare.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: EvoColors.primary),
                  ),
              ],
            ),

            if (ride.driverName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: EvoColors.textHint),
                  const SizedBox(width: 4),
                  Text(ride.driverName!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.textSecondary)),
                  if (ride.driverRating != null) ...[
                    const Spacer(),
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
                    const SizedBox(width: 2),
                    Text('${ride.driverRating!.toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                  const Spacer(),
                  Text(timeAgo, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: EvoColors.textHint)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EvoColors.lightBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: EvoColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: EvoColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? EvoColors.primary : EvoColors.lightBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? EvoColors.primary : EvoColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : EvoColors.textSecondary),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 72, color: EvoColors.textHint),
            const SizedBox(height: 16),
            Text(
              filter == 'all' ? 'لا توجد رحلات سابقة' : 'لا توجد رحلات ${filter == 'completed' ? 'مكتملة' : 'ملغاة'}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: EvoColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'ستظهر رحلاتك هنا بعد أول رحلة',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: EvoColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
