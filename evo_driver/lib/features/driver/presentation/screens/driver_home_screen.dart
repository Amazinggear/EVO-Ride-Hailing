import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import 'package:evo_driver/core/constants/evo_colors.dart';
import '../bloc/driver_bloc.dart';

// ══════════════════════════════════════════════════════════════════
// DRIVER HOME SCREEN
// - Go Online/Offline pill switch (animated)
// - Prepaid wallet balance card (linked to car plate)
// - Today's stats (rides, commission deducted)
// - Low balance warning
// - Real-time map with demand heatmap (Google Maps placeholder)
// ══════════════════════════════════════════════════════════════════

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with TickerProviderStateMixin {
  String _carType = 'ev_basic';
  bool _isOnline = false;
  bool _isTogglingOnline = false;

  // Mock data — replaced by BLoC
  double _walletBalance = 12.50;
  final String _carPlate = '87-12345';
  final int _todayRides = 7;
  final double _todayCommission = 2.34;
  bool _lowBalance = false;

  late AnimationController _onlineGlowController;
  late Animation<double> _onlineGlowAnimation;

  // Map
  final MapController _mapController = MapController();
  LatLng _driverPosition = const LatLng(31.9539, 35.9106); // Amman default
  double _driverHeading = 0;

  @override
  void initState() {
    super.initState();
    _onlineGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _onlineGlowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _onlineGlowController, curve: Curves.easeInOut),
    );
    _lowBalance = _walletBalance < 3.0;
    _initLocation();
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
      if (mounted) {
        setState(() {
          _driverPosition = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_driverPosition, 15.0);
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _toggleOnline() async {
    if (_isTogglingOnline) return;
    setState(() => _isTogglingOnline = true);
    HapticFeedback.mediumImpact();

    final bloc = context.read<DriverBloc>();
    if (_isOnline) {
      bloc.add(DriverGoOfflineEvent());
    } else {
      bloc.add(DriverGoOnlineEvent(carType: _carType));
    }
    // State update comes from BlocConsumer listener
    setState(() => _isTogglingOnline = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverBloc, DriverState>(
      listener: (context, state) {
        if (state is DriverOnlineState) {
          setState(() {
            _isOnline = true;
            _walletBalance = state.walletBalance;
            _carType = state.carType;
            _lowBalance = false;
          });
        } else if (state is DriverOfflineState) {
          setState(() {
            _isOnline = false;
            _walletBalance = state.walletBalance;
            _carType = state.carType;
          });
        } else if (state is LowBalanceState) {
          setState(() {
            _isOnline = false;
            _walletBalance = state.balance;
            _lowBalance = true;
          });
        } else if (state is RideAcceptedState) {
          context.pushNamed(
            'driver-in-ride',
            extra: {'rideId': state.rideId},
          );
        } else if (state is IncomingRideState) {
          _showIncomingRideSheet(state);
        }
      },
      child: Scaffold(
        backgroundColor: EvoColors.darkBg,
        body: Stack(
          children: [
            _buildMapBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  if (_lowBalance) _buildLowBalanceBanner(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomPanel(),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  void _showIncomingRideSheet(IncomingRideState state) {
    // Bottom sheet is already built as part of the screen
    // Just update the state — the _IncomingRideSheet widget handles timer display
  }

  Widget _buildMapBackground() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _driverPosition,
        initialZoom: 14.0,
        minZoom: 5,
        maxZoom: 19,
      ),
      children: [
        // Dark OSM tile layer for driver (Carto dark matter style)
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.evo.driver',
          retinaMode: MediaQuery.of(context).devicePixelRatio > 1.5,
        ),
        // Driver position marker
        MarkerLayer(
          markers: [
            Marker(
              point: _driverPosition,
              width: 48,
              height: 48,
              child: Transform.rotate(
                angle: _driverHeading * math.pi / 180,
                child: Container(
                  decoration: BoxDecoration(
                    color: EvoColors.darkCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isOnline ? EvoColors.primary : EvoColors.borderDark,
                      width: 2,
                    ),
                    boxShadow: _isOnline ? [
                      BoxShadow(
                        color: EvoColors.primary.withOpacity(0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ] : [],
                  ),
                  child: const Icon(
                    Icons.electric_car,
                    color: EvoColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Attribution
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
            TextSourceAttribution('CartoDB'),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // EVO Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: EvoColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EvoColors.borderDark),
            ),
            child: const Center(
              child: Text(
                'EVO',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: EvoColors.primary,
                ),
              ),
            ),
          ),

          const Spacer(),

          // ═══ ONLINE/OFFLINE PILL SWITCH ═══
          GestureDetector(
            onTap: _toggleOnline,
            child: AnimatedBuilder(
              animation: _onlineGlowAnimation,
              builder: (context, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isOnline
                        ? EvoColors.primary.withOpacity(0.15)
                        : EvoColors.darkCard,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _isOnline
                          ? EvoColors.primary.withOpacity(_onlineGlowAnimation.value)
                          : EvoColors.borderDark,
                      width: _isOnline ? 2 : 1,
                    ),
                    boxShadow: _isOnline
                        ? [
                            BoxShadow(
                              color: EvoColors.primary.withOpacity(
                                0.3 * _onlineGlowAnimation.value,
                              ),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isTogglingOnline)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: EvoColors.primary,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _isOnline ? EvoColors.primary : EvoColors.textOnDarkSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isOnline ? 'متاح للطلبات' : 'غير متاح',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _isOnline ? EvoColors.primary : EvoColors.textOnDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Spacer(),

          // Notifications
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: EvoColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EvoColors.borderDark),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: EvoColors.textOnDark, size: 22),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowBalanceBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: EvoColors.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvoColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: EvoColors.warning, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '⚠️ رصيدك منخفض! تواصل مع الإدارة لشحن محفظتك',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.warning),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/driver-wallet'),
            child: const Text('المحفظة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.warning, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: EvoColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: EvoColors.borderDark, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: EvoColors.borderDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                // ═══ Wallet Balance Card ═══
                _buildWalletCard(),
                const SizedBox(height: 16),

                // ═══ Today's Stats Row ═══
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.directions_car_outlined,
                        label: 'رحلات اليوم',
                        value: '$_todayRides',
                        color: EvoColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'عمولة اليوم',
                        value: '${_todayCommission.toStringAsFixed(2)} د.أ',
                        color: EvoColors.payoutRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.eco_outlined,
                        label: 'CO₂ موفّر',
                        value: '${(_todayRides * 3.5).toStringAsFixed(1)} كغ',
                        color: EvoColors.ecoIcon,
                      ),
                    ),
                  ],
                ),

                // Status message when offline
                if (!_isOnline) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EvoColors.darkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EvoColors.borderDark),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.power_settings_new, color: EvoColors.textOnDarkSecondary, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'اضغط "متاح للطلبات" للبدء باستقبال الرحلات',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: EvoColors.textOnDarkSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Safe area bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EvoColors.primary.withOpacity(_lowBalance ? 0.05 : 0.12),
            EvoColors.primaryDark.withOpacity(_lowBalance ? 0.03 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _lowBalance
              ? EvoColors.warning.withOpacity(0.4)
              : EvoColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: EvoColors.primary, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'الرصيد المسبق',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: EvoColors.textOnDarkSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _walletBalance.toStringAsFixed(2),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _lowBalance ? EvoColors.warning : EvoColors.primary,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      'د.أ',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: EvoColors.textOnDarkSecondary),
                    ),
                  ),
                ],
              ),
              Text(
                'مربوطة بسيارة: $_carPlate',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: EvoColors.textOnDarkSecondary),
              ),
            ],
          ),
          const Spacer(),
          // Arrow to wallet screen
          GestureDetector(
            onTap: () => context.pushNamed('driver-wallet'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EvoColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: EvoColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: EvoColors.darkBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvoColors.borderDark),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: EvoColors.textOnDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: EvoColors.darkCard,
      selectedItemColor: EvoColors.primary,
      unselectedItemColor: EvoColors.textOnDarkSecondary,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
      currentIndex: 0,
      onTap: (i) {
        switch (i) {
          case 1: context.pushNamed('driver-wallet'); break;
          case 2: /* context.pushNamed('driver-charging'); */ break;
          case 3: /* context.pushNamed('driver-profile'); */ break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'المحفظة'),
        BottomNavigationBarItem(icon: Icon(Icons.ev_station_outlined), label: 'الشحن'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'حسابي'),
      ],
    );
  }

  @override
  void dispose() {
    _onlineGlowController.dispose();
    super.dispose();
  }
}

/// ════════════════════════════════════════
/// INCOMING RIDE REQUEST POPUP
/// Full-screen bottom sheet with 15s timer
/// ════════════════════════════════════════
class IncomingRideRequestSheet extends StatefulWidget {
  final Map<String, dynamic> rideData;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingRideRequestSheet({
    super.key,
    required this.rideData,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<IncomingRideRequestSheet> createState() => _IncomingRideRequestSheetState();
}

class _IncomingRideRequestSheetState extends State<IncomingRideRequestSheet>
    with TickerProviderStateMixin {
  // ignore: unused_field — will be used to display car type icon in the UI
  final String _carType = 'ev_basic';
  late AnimationController _timerController;
  int _secondsLeft = 15;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )
      ..forward()
      ..addListener(() {
        final s = 15 - (_timerController.value * 15).floor();
        if (s != _secondsLeft) {
          setState(() => _secondsLeft = s);
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onDecline(); // Auto-decline on timeout
        }
      });
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: EvoColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, child) => CircularProgressIndicator(
                    value: 1 - _timerController.value,
                    backgroundColor: EvoColors.borderDark,
                    valueColor: AlwaysStoppedAnimation(
                      _secondsLeft <= 5 ? EvoColors.error : EvoColors.primary,
                    ),
                    strokeWidth: 4,
                  ),
                ),
              ),
              Text(
                '$_secondsLeft',
                style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 24,
                  fontWeight: FontWeight.w800, color: EvoColors.textOnDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Ride Info
          const Text(
            'طلب رحلة جديد!',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w800, color: EvoColors.textOnDark),
          ),
          const SizedBox(height: 16),

          _buildInfoRow(Icons.location_on_outlined, 'الاستلام', widget.rideData['pickup'] ?? 'غير محدد'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.flag_outlined, 'التوصيل', widget.rideData['dropoff'] ?? 'غير محدد'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.straighten_outlined, 'المسافة', '${widget.rideData['distance'] ?? '--'} كم'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.payments_outlined, 'الأجرة التقديرية', '${widget.rideData['fare'] ?? '--'} د.أ'),

          const SizedBox(height: 24),

          // Accept / Decline Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EvoColors.error,
                    side: const BorderSide(color: EvoColors.error),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('رفض', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EvoColors.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('قبول الرحلة ✓', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: EvoColors.primary, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: EvoColors.textOnDarkSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: EvoColors.textOnDark)),
      ],
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }
}

// Grid painter removed — replaced with flutter_map


