import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/passenger/ride_booking/presentation/bloc/booking_bloc.dart';
import '../constants/api_endpoints.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Initialises all dependencies.
///
/// Call this once before [runApp], after Firebase and other SDK inits:
/// ```dart
/// await initDependencies();
/// ```
Future<void> initDependencies() async {
  // ── External / Platform singletons ─────────────────────────────────────────

  // SharedPreferences — async, so we await it once and register the instance.
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // FirebaseAuth — thin wrapper around the platform SDK.
  sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);

  // FlutterSecureStorage — hardware-backed keystore on Android/iOS.
  sl.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  );

  // ── Networking ──────────────────────────────────────────────────────────────

  sl.registerSingleton<Dio>(_buildDio());

  // ── BLoCs — factories so each BlocProvider gets a fresh instance ────────────

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      firebaseAuth: sl<FirebaseAuth>(),
      secureStorage: sl<FlutterSecureStorage>(),
      dio: sl<Dio>(),
    ),
  );

  sl.registerFactory<BookingBloc>(
    () => BookingBloc(
      dio: sl<Dio>(),
      storage: sl<FlutterSecureStorage>(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dio factory
// ─────────────────────────────────────────────────────────────────────────────

Dio _buildDio() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // ── Interceptors ──────────────────────────────────────────────────────────

  // Log interceptor — only in debug builds.
  assert(() {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (obj) => debugPrintDio(obj.toString()),
      ),
    );
    return true;
  }());

  // Token refresh interceptor — automatically retries on 401.
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        if (error.response?.statusCode == 401) {
          if (error.requestOptions.extra['isRetry'] == true) {
            return handler.next(error);
          }
          final refreshed = await _tryRefreshToken(dio);
          if (refreshed) {
            // Retry the original request with the new token.
            final opts = error.requestOptions;
            opts.extra['isRetry'] = true;
            opts.headers['Authorization'] = dio.options.headers['Authorization'];
            try {
              final retryResponse = await dio.fetch(opts);
              return handler.resolve(retryResponse);
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}

/// Attempts to refresh the access token using the stored refresh token.
/// Returns true if the refresh succeeded and the Dio headers were updated.
Future<bool> _tryRefreshToken(Dio dio) async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  try {
    final refreshToken = await storage.read(key: 'evo_refresh_token');
    if (refreshToken == null) return false;

    // Bypass interceptors for the refresh call to avoid infinite loops.
    final refreshDio = Dio(BaseOptions(
      baseUrl: dio.options.baseUrl,
      headers: {'Content-Type': 'application/json'},
    ));

    final response = await refreshDio.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );

    if (response.statusCode == 200) {
      final newAccessToken = response.data['accessToken'] as String?;
      final newRefreshToken = response.data['refreshToken'] as String?;

      if (newAccessToken != null) {
        await storage.write(key: 'evo_access_token', value: newAccessToken);
        if (newRefreshToken != null) {
          await storage.write(key: 'evo_refresh_token', value: newRefreshToken);
        }
        dio.options.headers['Authorization'] = 'Bearer $newAccessToken';
        return true;
      }
    }
  } catch (_) {
    // Refresh failed — caller will propagate the 401.
  }
  return false;
}

// ignore: avoid_print
void debugPrintDio(String message) => print('[EVO-DIO] $message');
