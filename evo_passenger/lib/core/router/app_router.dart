import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/auth_screens.dart';
import '../../features/auth/presentation/screens/passenger_name_input_screen.dart';
import '../../features/passenger/home/presentation/screens/passenger_home_screen.dart';
import '../../features/passenger/home/presentation/screens/passenger_search_screen.dart';
import '../../features/passenger/ride_history/presentation/screens/ride_history_screen.dart';
import '../../features/passenger/profile/presentation/screens/passenger_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route name constants — use these throughout the app with context.goNamed(...)
// ─────────────────────────────────────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String phoneInput = '/phone-input';
  static const String verifyOtp = '/verify-otp';
  static const String nameInput = '/name-input';
  static const String passengerShell = '/passenger';
  static const String passengerHome = '/passenger/home';
  static const String passengerHistory = '/passenger/history';
  static const String passengerProfile = '/passenger/profile';
  static const String passengerSearch = '/passenger-search';
  static const String driverRegistration = '/driver-registration';
  static const String pendingApproval = '/pending-approval';
}

/// Creates the [GoRouter] instance wired to the current [AuthBloc].
///
/// Called once in [_AppContentState.build] — the router rebuilds its redirect
/// logic whenever [AuthBloc] emits a new state.
GoRouter createAppRouter(BuildContext context) {
  final authBloc = context.read<AuthBloc>();

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _BlocChangeNotifier(authBloc),
    debugLogDiagnostics: true,

    // ── Global redirect ────────────────────────────────────────────────────
    redirect: (BuildContext ctx, GoRouterState state) {
      final authState = authBloc.state;
      final location = state.matchedLocation;

      // While the auth status is being resolved keep showing the splash.
      if (authState is AuthInitialState || authState is AuthLoadingState) {
        return AppRoutes.splash;
      }

      final isUnauthenticated = authState is AuthUnauthenticatedState;
      final isAuthenticated = authState is AuthSuccessState;

      if (isUnauthenticated) {
        const authRoutes = [
          AppRoutes.phoneInput,
          AppRoutes.verifyOtp,
        ];
        if (!authRoutes.contains(location)) {
          return AppRoutes.phoneInput;
        }
      }

      if (isAuthenticated) {
        final successState = authState;

        // New passenger → must enter name before accessing the home screen.
        if (successState.isNewUser &&
            successState.role == 'passenger' &&
            location != AppRoutes.nameInput) {
          return AppRoutes.nameInput;
        }

        // Authenticated user tries to visit auth screens → redirect to home.
        const authOnlyRoutes = [
          AppRoutes.splash,
          AppRoutes.phoneInput,
          AppRoutes.verifyOtp,
        ];
        if (authOnlyRoutes.contains(location)) {
          return AppRoutes.passengerHome;
        }
      }

      return null; // No redirect needed.
    },

    // ── Route tree ─────────────────────────────────────────────────────────
    routes: [
      // / — loading splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),

      // /phone-input
      GoRoute(
        path: AppRoutes.phoneInput,
        builder: (context, state) {
          // Support optional ?isDriver=true query param for the driver flow.
          final isDriver =
              state.uri.queryParameters['isDriver'] == 'true';
          return PhoneInputScreen(isDriver: isDriver);
        },
      ),

      // /verify-otp?verificationId=...&phone=...&isDriver=true|false
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (context, state) {
          // Params can come either from go_router extra (Map) or from
          // Navigator.pushNamed arguments (legacy screens).
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return OtpVerificationScreen(
              verificationId: extra['verificationId'] as String? ?? '',
              phone: extra['phone'] as String? ?? '',
              isDriver: extra['isDriver'] as bool? ?? false,
            );
          }
          // Fallback — read from query parameters.
          final params = state.uri.queryParameters;
          return OtpVerificationScreen(
            verificationId: params['verificationId'] ?? '',
            phone: params['phone'] ?? '',
            isDriver: params['isDriver'] == 'true',
          );
        },
      ),

      // /name-input — new-passenger name collection step
      GoRoute(
        path: AppRoutes.nameInput,
        builder: (context, state) => const PassengerNameInputScreen(),
      ),

      // /passenger — shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => _PassengerShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.passengerHome,
            builder: (context, state) => const PassengerHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.passengerHistory,
            builder: (context, state) => const RideHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.passengerProfile,
            builder: (context, state) => const PassengerProfileScreen(),
          ),
        ],
      ),

      // /passenger-search
      GoRoute(
        path: AppRoutes.passengerSearch,
        builder: (context, state) {
          final isPickup = state.uri.queryParameters['isPickup'] == 'true';
          return PassengerSearchScreen(isPickup: isPickup);
        },
      ),

      // /driver-registration
      GoRoute(
        path: AppRoutes.driverRegistration,
        builder: (context, state) => const Scaffold(body: Center(child: Text('Driver app only'))),
      ),

      // /pending-approval
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (context, state) => const Scaffold(body: Center(child: Text('Driver app only'))),
      ),
    ],

    // ── Error fallback ─────────────────────────────────────────────────────
    errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading/Splash screen
// ─────────────────────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'EVO',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Color(0xFF00C853),
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Color(0xFF00C853),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 404 Error screen
// ─────────────────────────────────────────────────────────────────────────────

class _RouteErrorScreen extends StatelessWidget {
  final Exception? error;

  const _RouteErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFE53935),
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'الصفحة غير موجودة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error?.toString() ?? 'الرابط المطلوب غير موجود.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.splash),
                child: const Text(
                  'العودة للرئيسية',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Listenable bridge: BLoC → GoRouter refreshListenable
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps a [Bloc] so that [GoRouter.refreshListenable] re-evaluates its
/// redirect logic whenever the BLoC emits a new state.
class _BlocChangeNotifier extends ChangeNotifier {
  _BlocChangeNotifier(AuthBloc bloc) {
    // Listen to auth state changes and notify router listeners.
    bloc.stream.listen((_) => notifyListeners());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Passenger Shell — wraps all passenger tabs with a bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────

class _PassengerShell extends StatelessWidget {
  final Widget child;

  const _PassengerShell({required this.child});

  int _tabIndex(String location) {
    if (location.startsWith(AppRoutes.passengerHistory)) return 1;
    if (location.startsWith(AppRoutes.passengerProfile)) return 2;
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
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  label: 'الرئيسية',
                  isActive: currentIndex == 0,
                  onTap: () => context.go(AppRoutes.passengerHome),
                ),
                _BottomNavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: 'رحلاتي',
                  isActive: currentIndex == 1,
                  onTap: () => context.go(AppRoutes.passengerHistory),
                ),
                _BottomNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'حسابي',
                  isActive: currentIndex == 2,
                  onTap: () => context.go(AppRoutes.passengerProfile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00C853).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? const Color(0xFF00C853) : const Color(0xFF9E9E9E),
              size: 26,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF00C853) : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

