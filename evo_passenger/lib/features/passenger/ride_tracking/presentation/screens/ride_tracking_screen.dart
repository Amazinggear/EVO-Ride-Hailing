import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:evo_passenger/core/constants/evo_colors.dart';

// ══════════════════════════════════════════════════════════════════
// RIDE TRACKING SCREEN — Passenger side
// Shows after ride is accepted by driver:
// - Driver info card (name, plate, model, rating, ETA)
// - Live map with driver pin moving toward passenger
// - Status timeline: Searching → Accepted → Arriving → In Ride → Done
// - Cancel button (available until driver arrives)
// - Cash payment reminder on completion
// ══════════════════════════════════════════════════════════════════

enum RideTrackingStatus {
  searching,
  accepted,   // Driver accepted, en route to pickup
  arriving,   // Driver < 100m from pickup
  inProgress, // Ride started
  completed,
}

class RideTrackingScreen extends StatefulWidget {
  final String rideId;
  final double totalFare;
  final String carType;

  const RideTrackingScreen({
    super.key,
    required this.rideId,
    required this.totalFare,
    required this.carType,
  });

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen>
    with TickerProviderStateMixin {
  RideTrackingStatus _status = RideTrackingStatus.searching;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Mock driver info — replaced by BLoC/Socket.io
  Map<String, dynamic>? _driverInfo;
  final int _etaMinutes = 8;
  bool _canCancel = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // TODO: Connect to Socket.io — listen for ride status updates
    // socketService.onRideStatusUpdate(widget.rideId, _handleStatusUpdate);
    _simulateMockFlow(); // REMOVE in production
  }

  void _simulateMockFlow() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _status = RideTrackingStatus.accepted;
      _driverInfo = {
        'fullName': 'أحمد الخالدي',
        'carModel': 'Tesla Model 3',
        'carPlate': '87-12345',
        'carType': widget.carType,
        'rating': 4.9,
        'photoUrl': null,
        'phone': '0791234567',
      };
    });
  }

  // ignore: unused_element — will be called by Socket.io once wired
  void _handleStatusUpdate(Map<String, dynamic> data) {
    final newStatus = data['status'] as String;
    setState(() {
      switch (newStatus) {
        case 'accepted': _status = RideTrackingStatus.accepted; break;
        case 'arriving': _status = RideTrackingStatus.arriving; _canCancel = false; break;
        case 'in_progress': _status = RideTrackingStatus.inProgress; _canCancel = false; break;
        case 'completed':
          _status = RideTrackingStatus.completed;
          _showCompletionSheet();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvoColors.lightBg,
      body: Stack(
        children: [
          // Map background (Google Maps replaces this)
          _buildMapPlaceholder(),

          // Top Back Button + Ride ID
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _circleBtn(Icons.arrow_back_ios_new, () {
                    if (_status == RideTrackingStatus.searching || _canCancel) {
                      _showCancelDialog();
                    }
                  }),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8)],
                    ),
                    child: Text(
                      'رحلة #${widget.rideId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: EvoColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      color: const Color(0xFFE5EDE8),
      child: Center(
        child: _status == RideTrackingStatus.searching
            ? _buildSearchingAnimation()
            : const Icon(Icons.map_outlined, size: 80, color: Color(0xFFB0C4B8)),
      ),
    );
  }

  Widget _buildSearchingAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: EvoColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, size: 36, color: EvoColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'نبحث عن أقرب كابتن...',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w600, color: EvoColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: EvoColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          // Status Timeline
          _buildStatusTimeline(),
          const SizedBox(height: 16),

          // Driver Info Card (when accepted)
          if (_driverInfo != null) ...[
            const Divider(color: EvoColors.border, height: 1),
            _buildDriverCard(),
          ],

          // Fare info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Text('💵', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text('الدفع كاش للكابتن', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: EvoColors.textSecondary)),
                const Spacer(),
                Text(
                  '${widget.totalFare.toStringAsFixed(2)} د.أ',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: EvoColors.primary),
                ),
              ],
            ),
          ),

          // Cancel Button
          if (_canCancel && _status != RideTrackingStatus.searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _showCancelDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EvoColors.error,
                    side: const BorderSide(color: EvoColors.error),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('إلغاء الرحلة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                ),
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final steps = [
      ('بحث', Icons.search, RideTrackingStatus.searching),
      ('قبول', Icons.check_circle_outline, RideTrackingStatus.accepted),
      ('في الطريق', Icons.directions_car_outlined, RideTrackingStatus.arriving),
      ('في الرحلة', Icons.navigation_outlined, RideTrackingStatus.inProgress),
      ('اكتملت', Icons.flag_outlined, RideTrackingStatus.completed),
    ];

    final currentIndex = steps.indexWhere((s) => s.$3 == _status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < currentIndex ? EvoColors.primary : EvoColors.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final step = steps[stepIndex];
          final isDone = stepIndex < currentIndex;
          final isCurrent = stepIndex == currentIndex;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isDone || isCurrent ? EvoColors.primary : EvoColors.border,
                  shape: BoxShape.circle,
                ),
                child: Icon(step.$2, size: 16, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(step.$1, style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: isDone || isCurrent ? EvoColors.primary : EvoColors.textHint)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDriverCard() {
    final info = _driverInfo!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 54, height: 54,
            decoration: const BoxDecoration(
              color: EvoColors.primarySubtle,
              shape: BoxShape.circle,
            ),
            child: info['photoUrl'] != null
                ? ClipOval(child: Image.network(info['photoUrl'], fit: BoxFit.cover))
                : const Icon(Icons.person, size: 28, color: EvoColors.primary),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info['fullName'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: EvoColors.textPrimary)),
                Text('${info['carModel']} | ${info['carPlate']}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.textSecondary)),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                    const SizedBox(width: 2),
                    Text('${info['rating']}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    if (_status == RideTrackingStatus.accepted)
                      Text('ETA: $_etaMinutes دقائق', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.primary)),
                  ],
                ),
              ],
            ),
          ),

          // Call Button
          _circleBtn(Icons.phone, () {
            // TODO: launch_url tel:${info['phone']}
          }, color: EvoColors.primary),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color color = EvoColors.textPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 8)],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إلغاء الرحلة؟', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        content: const Text('هل أنت متأكد من إلغاء الرحلة؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لا، استمر', style: TextStyle(fontFamily: 'Cairo', color: EvoColors.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/passenger-home');
              // TODO: BLoC cancel event
            },
            style: ElevatedButton.styleFrom(backgroundColor: EvoColors.error),
            child: const Text('نعم، إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCompletionSheet() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RideCompletionSheet(
        totalFare: widget.totalFare,
        driverName: _driverInfo?['fullName'] ?? '',
        onRate: (rating, comment) {
          Navigator.pushReplacementNamed(context, '/passenger-home');
          // TODO: BLoC submit rating
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

// ════════════════════════════════════════
// RIDE COMPLETION SHEET — with rating
// ════════════════════════════════════════
class _RideCompletionSheet extends StatefulWidget {
  final double totalFare;
  final String driverName;
  final void Function(int rating, String? comment) onRate;

  const _RideCompletionSheet({required this.totalFare, required this.driverName, required this.onRate});

  @override
  State<_RideCompletionSheet> createState() => _RideCompletionSheetState();
}

class _RideCompletionSheetState extends State<_RideCompletionSheet> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: EvoColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          const Icon(Icons.check_circle, color: EvoColors.primary, size: 64),
          const SizedBox(height: 12),
          const Text('اكتملت رحلتك!', style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),

          // Fare display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: EvoColors.primarySubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💵 الأجرة:', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  '${widget.totalFare.toStringAsFixed(2)} د.أ كاش',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w900, color: EvoColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Rating
          Text('كيف كانت رحلتك مع ${widget.driverName}؟',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: EvoColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _selectedRating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFC107),
                  size: 40,
                ),
              ),
            )),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'ملاحظة اختيارية للكابتن...',
              hintStyle: const TextStyle(fontFamily: 'Cairo', color: EvoColors.textHint),
              filled: true, fillColor: EvoColors.lightBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onRate(_selectedRating, _commentController.text.trim().isEmpty ? null : _commentController.text.trim()),
              child: const Text('إرسال التقييم', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

