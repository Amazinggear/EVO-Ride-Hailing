// lib/core/di/injection_container.dart
// ══════════════════════════════════════════════════════════
// EVO Driver — Dependency Injection Container (get_it)
//
// Call [initDependencies()] once in main() before runApp().
// Access registered singletons via [sl<T>()].
// ══════════════════════════════════════════════════════════

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/registration_bloc.dart';
import '../../features/driver/presentation/bloc/driver_bloc.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Backend base URL — override via --dart-define=BASE_URL=https://...
const String _baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://10.0.2.2:5000',
);

Future<void> initDependencies() async {
  // ─────────────────────────────────────────────────────────
  // EXTERNAL / THIRD-PARTY
  // ─────────────────────────────────────────────────────────

  // SharedPreferences — for non-sensitive user prefs (locale, onboarding flag)
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);

  // FlutterSecureStorage — for JWT, userId, role
  sl.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  );

  // Firebase Auth
  sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);

  // Dio HTTP client with interceptors
  sl.registerSingleton<Dio>(_buildDio());

  // ─────────────────────────────────────────────────────────
  // BLOCS — registered as factories so each BlocProvider
  // gets a fresh instance (avoids stale state across rebuilds)
  // ─────────────────────────────────────────────────────────

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      firebaseAuth: sl<FirebaseAuth>(),
      dio: sl<Dio>(),
      secureStorage: sl<FlutterSecureStorage>(),
    ),
  );

  // RegistrationBloc — factory so each provider gets a fresh instance
  sl.registerFactory<RegistrationBloc>(
    () => RegistrationBloc(dio: sl<Dio>()),
  );

  sl.registerFactory<DriverBloc>(
    () => DriverBloc(
      dio: sl<Dio>(),
      socketUrl: const String.fromEnvironment(
        'SOCKET_URL',
        defaultValue: 'https://api.evo-ride.jo',
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────
// DIO BUILDER — centralised HTTP config
// ─────────────────────────────────────────────────────────
Dio _buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Client': 'evo-driver-flutter',
      },
    ),
  );

  // Logging interceptor (debug builds only)
  assert(() {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: false,
      responseHeader: false,
      error: true,
      logPrint: (obj) => print('[EVO-DIO] $obj'),
    ));
    return true;
  }());

  // Auth retry interceptor — refreshes JWT on 401
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired — clear and let AuthBloc handle navigation
          // (No silent refresh on driver app — driver must re-authenticate)
          handler.next(error);
          return;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
