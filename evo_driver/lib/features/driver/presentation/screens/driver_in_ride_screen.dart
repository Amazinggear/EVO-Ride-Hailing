import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evo_driver/core/constants/evo_colors.dart';
import '../bloc/driver_bloc.dart';

// ══════════════════════════════════════════════════════════════════
// DRIVER IN-RIDE SCREEN
// Displays real-time map, passenger info, and dynamic action buttons:
// 1. Arriving (Swipe to Arrive)
// 2. Arrived (Swipe to Start Ride)
// 3. In Progress (Swipe to Complete Ride)
// ══════════════════════════════════════════════════════════════════

class DriverInRideScreen extends StatefulWidget {
  final String rideId;
  const DriverInRideScreen({super.key, required this.rideId});

  @override
  State<DriverInRideScreen> createState() => _DriverInRideScreenState();
}

class _DriverInRideScreenState extends State<DriverInRideScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverBloc, DriverState>(
      listener: (context, state) {
        if (state is RideCompletedState) {
          // Show summary sheet and pop
          _showCompletionSummary(state);
        } else if (state is DriverOfflineState || state is DriverOnlineState) {
          // Ride was cancelled or finished
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },
      builder: (context, state) {
        if (state is! RideAcceptedState) {
          return const Scaffold(
            backgroundColor: EvoColors.darkBg,
            body: Center(child: CircularProgressIndicator(color: EvoColors.primary)),
          );
        }

        final rideStatus = state.status;
        final rideData = state.rideData;

        return Scaffold(
          backgroundColor: EvoColors.darkBg,
          body: Stack(
            children: [
              // Map Background (Placeholder)
              _buildMapBackground(),

              // Top Bar with back button (only visible if allowed to back out)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: EvoColors.darkCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: EvoColors.borderDark),
                    ),
                  ),
                ),
              ),

              // Bottom Sheet with Ride Controls
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildRideControls(rideStatus, rideData),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapBackground() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: CustomPaint(
        painter: _GridPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildRideControls(String status, Map<String, dynamic> rideData) {
    String passengerName = rideData['passengerName'] ?? 'راكب محترم';
    String destination = status == 'arriving' || status == 'arrived'
        ? (rideData['pickup'] ?? 'نقطة الاستلام')
        : (rideData['dropoff'] ?? 'وجهة الوصول');
    String actionText = '';
    VoidCallback? onAction;

    if (status == 'arriving') {
      actionText = 'تأكيد الوصول للموقع 📍';
      onAction = () => context.read<DriverBloc>().add(MarkArrivedEvent(rideId: widget.rideId));
    } else if (status == 'arrived') {
      actionText = 'بدء الرحلة 🚀';
      onAction = () => context.read<DriverBloc>().add(StartRideEvent(rideId: widget.rideId));
    } else if (status == 'in_progress') {
      actionText = 'إنهاء الرحلة وتحصيل ${rideData['fare'] ?? '--'} د.أ ✅';
      onAction = () => context.read<DriverBloc>().add(CompleteRideEvent(rideId: widget.rideId));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: EvoColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Passenger Info Row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: EvoColors.primary.withOpacity(0.2),
                child: const Icon(Icons.person, color: EvoColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: EvoColors.textOnDark),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text('5.0', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.textOnDarkSecondary)),
                      ],
                    )
                  ],
                ),
              ),
              // Call Button
              Container(
                decoration: BoxDecoration(
                  color: EvoColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.phone, color: EvoColors.primary),
                  onPressed: () {
                    // Call passenger logic
                  },
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: EvoColors.borderDark),
          const SizedBox(height: 20),

          // Destination Info
          Row(
            children: [
              Icon(
                status == 'in_progress' ? Icons.flag : Icons.my_location,
                color: EvoColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == 'in_progress' ? 'الوجهة' : 'نقطة الاستلام',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.textOnDarkSecondary),
                    ),
                    Text(
                      destination,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: EvoColors.textOnDark),
                    ),
                  ],
                ),
              ),
              // Navigation Button
              Container(
                decoration: BoxDecoration(
                  color: EvoColors.darkBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EvoColors.borderDark),
                ),
                child: IconButton(
                  icon: const Icon(Icons.navigation, color: EvoColors.primary),
                  onPressed: () {
                    // Open Google Maps
                  },
                ),
              )
            ],
          ),
          const SizedBox(height: 32),

          // Action Button (Ideally a swipe-to-action button, using ElevatedButton for now)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'in_progress' ? EvoColors.success : EvoColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                actionText,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _showCompletionSummary(RideCompletedState state) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: EvoColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: EvoColors.success, size: 64),
              const SizedBox(height: 16),
              const Text(
                'اكتملت الرحلة بنجاح!',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w800, color: EvoColors.textOnDark),
              ),
              const SizedBox(height: 24),
              _buildSummaryRow('الأجرة الإجمالية', '${state.totalFare} د.أ', isTotal: true),
              const SizedBox(height: 12),
              _buildSummaryRow('عمولة التطبيق', '${state.commission} د.أ', color: EvoColors.error),
              const SizedBox(height: 24),
              const Divider(color: EvoColors.borderDark),
              const SizedBox(height: 16),
              _buildSummaryRow('رصيد المحفظة الجديد', '${state.newWalletBalance} د.أ', color: EvoColors.primary, isTotal: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close sheet
                    Navigator.pop(context); // Go back to Home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EvoColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('عودة للرئيسية', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: EvoColors.textOnDarkSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w800,
            color: color ?? EvoColors.textOnDark,
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C2C3E).withOpacity(0.5)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

