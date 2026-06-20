// lib/core/router/app_router.dart
// ══════════════════════════════════════════════════════════
// EVO Driver — GoRouter Configuration
//
// createDriverRouter(context) → RouterConfig<Object>
//
// Auth guard logic:
//   • AuthSuccessState + isNewUser=true  → /driver-register/step-1
//   • AuthSuccessState + role='driver'   → /driver-home
//   • AuthSuccessState + pending_approval→ /pending-approval
//   • AuthUnauthenticated / Initial      → /phone-input
// ══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/auth_screens.dart';
import '../../features/auth/presentation/screens/driver_registration_screens.dart';
import '../../features/driver/presentation/screens/driver_home_screen.dart';
import '../../features/driver/presentation/screens/driver_in_ride_screen.dart';
import '../../features/driver/presentation/screens/driver_wallet_screen.dart';
import '../../features/driver/charging_stations/presentation/screens/driver_charging_stations_screen.dart';
import '../../features/driver/profile/presentation/screens/driver_profile_screen.dart';

RouterConfig<Object> createDriverRouter(BuildContext context) {
  final authBloc = context.read<AuthBloc>();

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: _BlocListenable(authBloc),

    // ─── Auth Redirect Guard ───────────────────────────────
    redirect: (BuildContext ctx, GoRouterState state) {
      final authState = authBloc.state;
      final location = state.matchedLocation;

      // While checking auth — stay put (show splash / loading)
      if (authState is AuthInitialState || authState is AuthLoadingState) {
        return null;
      }

      final isAuthenticated = authState is AuthSuccessState;
      final isOnAuthRoute =
          location == '/phone-input' || location == '/verify-otp';
      final isOnRegisterRoute = location.startsWith('/driver-register');
      final isOnPendingRoute = location == '/pending-approval';

      // Not authenticated — force to phone-input
      if (!isAuthenticated) {
        return isOnAuthRoute ? null : '/phone-input';
      }

      // Authenticated
      // New driver — must complete registration
      if (authState.isNewUser) {
        return isOnRegisterRoute ? null : '/driver-register/step-1';
      }

      // Registered driver
      if (authState.role == 'driver') {
        // Don't redirect if already on a valid authenticated route or splash
        if (isOnAuthRoute || location == '/') return '/driver-home';
        return null;
      }

      // Pending approval (registered but not yet approved)
      if (authState.role == 'pending_approval') {
        if (isOnAuthRoute || location == '/') return '/pending-approval';
        return isOnPendingRoute ? null : '/pending-approval';
      }

      // Unknown role — go home as fallback
      if (isOnAuthRoute || location == '/') return '/driver-home';
    
      return null;
    },

    // ─── Routes ───────────────────────────────────────────
    routes: [
      // Root — redirect handled above
      GoRoute(
        path: '/',
        builder: (context, state) => const _SplashRedirectScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────
      GoRoute(
        path: '/phone-input',
        name: 'phone-input',
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        name: 'verify-otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpVerificationScreen(
            verificationId: extra?['verificationId'] as String? ?? '',
            phoneNumber: extra?['phoneNumber'] as String? ?? '',
          );
        },
      ),

      // ── Driver Main Shell — bottom nav ─────────────────────
      ShellRoute(
        builder: (context, state, child) => _DriverShell(child: child),
        routes: [
          GoRoute(
            path: '/driver-home',
            name: 'driver-home',
            builder: (context, state) => const DriverHomeScreen(),
          ),
          GoRoute(
            path: '/driver-stations',
            name: 'driver-stations',
            builder: (context, state) => const DriverChargingStationsScreen(),
          ),
          GoRoute(
            path: '/driver-wallet',
            name: 'driver-wallet',
            builder: (context, state) => const DriverWalletScreen(),
          ),
          GoRoute(
            path: '/driver-profile',
            name: 'driver-profile',
            builder: (context, state) => const DriverProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/driver-in-ride',
        name: 'driver-in-ride',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return DriverInRideScreen(rideId: args['rideId'] ?? '');
        },
      ),
      GoRoute(
        path: '/pending-approval',
        name: 'pending-approval',
        builder: (context, state) => const DriverApprovalStatusScreen(
          status: 'pending',
        ),
      ),

      // ── Driver Registration Steps ─────────────────────────
      GoRoute(
        path: '/driver-register/step-1',
        name: 'driver-register-step-1',
        builder: (context, state) => const DriverStep1Screen(),
      ),
      GoRoute(
        path: '/driver-register/step-2',
        name: 'driver-register-step-2',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return DriverStep2Screen(stepData: args);
        },
      ),
      GoRoute(
        path: '/driver-register/step-3',
        name: 'driver-register-step-3',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return DriverStep3Screen(stepData: args);
        },
      ),
      GoRoute(
        path: '/driver-register/step-4',
        name: 'driver-register-step-4',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return DriverStep4Screen(stepData: args);
        },
      ),
      GoRoute(
        path: '/driver-register/step-5',
        name: 'driver-register-step-5',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return DriverStep5Screen(stepData: args);
        },
      ),
    ],

    // ─── Error Route ──────────────────────────────────────
    errorBuilder: (context, state) => _RouterErrorScreen(
      error: state.error?.toString() ?? 'صفحة غير موجودة',
    ),
  );
}

// ═══════════════════════════════════════════════════════════
// SPLASH / REDIRECT SCREEN
// Shown at "/" while GoRouter evaluates the redirect guard.
// ═══════════════════════════════════════════════════════════
class _SplashRedirectScreen extends StatelessWidget {
  const _SplashRedirectScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EvoLogoMark(),
            SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvoLogoMark extends StatelessWidget {
  const _EvoLogoMark();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(
          Icons.electric_bolt_rounded,
          size: 64,
          color: Color(0xFF00C853),
        ),
        SizedBox(height: 8),
        Text(
          'EVO Captain',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ROUTER ERROR SCREEN
// ═══════════════════════════════════════════════════════════
class _RouterErrorScreen extends StatelessWidget {
  final String error;

  const _RouterErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Color(0xFFE53935),
              ),
              const SizedBox(height: 16),
              const Text(
                'حدث خطأ في التنقل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: Color(0xFFB0B0B0),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BLOC LISTENABLE ADAPTER
// Makes GoRouter re-evaluate redirect whenever AuthBloc emits.
// ═══════════════════════════════════════════════════════════
class _BlocListenable extends ChangeNotifier {
  final AuthBloc _authBloc;

  _BlocListenable(this._authBloc) {
    _authBloc.stream.listen((_) => notifyListeners());
  }
}

// ═══════════════════════════════════════════════════════════
// DRIVER SHELL — Bottom Navigation Bar
// ═══════════════════════════════════════════════════════════
class _DriverShell extends StatelessWidget {
  final Widget child;

  const _DriverShell({required this.child});

  int _tabIndex(String location) {
    if (location.startsWith('/driver-stations')) return 1;
    if (location.startsWith('/driver-wallet')) return 2;
    if (location.startsWith('/driver-profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F2E),
          boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DriverNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isActive: currentIndex == 0,
                  onTap: () => context.go('/driver-home'),
                ),
                _DriverNavItem(
                  icon: Icons.ev_station_outlined,
                  activeIcon: Icons.ev_station_rounded,
                  label: 'الشحن',
                  isActive: currentIndex == 1,
                  onTap: () => context.go('/driver-stations'),
                ),
                _DriverNavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'المحفظة',
                  isActive: currentIndex == 2,
                  onTap: () => context.go('/driver-wallet'),
                ),
                _DriverNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'حسابي',
                  isActive: currentIndex == 3,
                  onTap: () => context.go('/driver-profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DriverNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const kGreen = Color(0xFF00C853);
    const kGray = Color(0xFF4A5568);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kGreen.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? kGreen : kGray,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? kGreen : kGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

