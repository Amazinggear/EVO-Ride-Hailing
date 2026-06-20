import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/api_endpoints.dart';
import 'auth_event.dart';
import 'auth_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Storage key constants
// ─────────────────────────────────────────────────────────────────────────────
const _kAccessToken = 'evo_access_token';
const _kRefreshToken = 'evo_refresh_token';
const _kUserId = 'evo_user_id';
const _kUserRole = 'evo_user_role';
const _kUserName = 'evo_user_name';

/// EVO Passenger AuthBloc
///
/// Auth flow:
///   1. [SendOtpEvent]    → Firebase verifyPhoneNumber → [AuthOtpSentState]
///   2. [VerifyOtpEvent]  → Firebase credential → POST /verify-otp → store JWT → [AuthSuccessState]
///   3. [SaveNameEvent]   → PATCH /profile → [AuthSuccessState]
///   4. [SignOutEvent]    → clear Firebase + storage → [AuthUnauthenticatedState]
///   5. [CheckAuthStatusEvent] → read token → [AuthSuccessState] | [AuthUnauthenticatedState]
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth;
  final FlutterSecureStorage _secureStorage;
  final Dio _dio;

  AuthBloc({
    required FirebaseAuth firebaseAuth,
    required FlutterSecureStorage secureStorage,
    required Dio dio,
  })  : _firebaseAuth = firebaseAuth,
        _secureStorage = secureStorage,
        _dio = dio,
        super(const AuthInitialState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<SaveNameEvent>(_onSaveName);
    on<SignOutEvent>(_onSignOut);
  }

  // ───────────────────────────────────────────────
  // CheckAuthStatusEvent
  // ───────────────────────────────────────────────
  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    try {
      final accessToken = await _secureStorage.read(key: _kAccessToken);
      final userId = await _secureStorage.read(key: _kUserId);
      final role = await _secureStorage.read(key: _kUserRole);

      if (accessToken == null || userId == null || role == null) {
        emit(const AuthUnauthenticatedState());
        return;
      }

      // Validate JWT with backend
      final response = await _dio.get(
        ApiEndpoints.updateProfile.replaceAll('/profile', '/me'),
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        // Inject the stored token into Dio headers so all subsequent calls work.
        _setDioAuthHeader(accessToken);

        emit(AuthSuccessState(
          userId: userId,
          role: role,
          isNewUser: false,
          accessToken: accessToken,
        ));
      } else {
        await _clearStorage();
        emit(const AuthUnauthenticatedState());
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _clearStorage();
        emit(const AuthUnauthenticatedState());
      } else {
        // Network error / server unreachable — allow local cache offline mode
        final accessToken = await _secureStorage.read(key: _kAccessToken);
        final userId = await _secureStorage.read(key: _kUserId);
        final role = await _secureStorage.read(key: _kUserRole);
        if (accessToken != null && userId != null && role != null) {
          _setDioAuthHeader(accessToken);
          emit(AuthSuccessState(
            userId: userId,
            role: role,
            isNewUser: false,
            accessToken: accessToken,
          ));
        } else {
          emit(const AuthUnauthenticatedState());
        }
      }
    } catch (_) {
      try {
        await _clearStorage();
      } catch (_) {}
      emit(const AuthUnauthenticatedState());
    }
  }

  // ───────────────────────────────────────────────
  // SendOtpEvent
  // ───────────────────────────────────────────────
  Future<void> _onSendOtp(
    SendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    // TEMPORARY BYPASS: Skip Firebase OTP and login directly
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await _callVerifyOtpBackend(
        emit: emit,
        idToken: 'bypass-token',
        isDriver: false,
        phoneForBypass: event.phoneNumber,
      );
    } catch (e) {
      if (!emit.isDone) {
        emit(AuthErrorState(message: _friendlyError(e)));
      }
    }
  }

  // ───────────────────────────────────────────────
  // VerifyOtpEvent
  // ───────────────────────────────────────────────
  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken() ?? '';

      if (idToken.isEmpty) {
        emit(const AuthErrorState(message: 'فشل التحقق — يرجى المحاولة مجدداً'));
        return;
      }

      await _callVerifyOtpBackend(
        emit: emit,
        idToken: idToken,
        isDriver: event.isDriver,
      );
    } on FirebaseAuthException catch (e) {
      emit(AuthErrorState(message: _friendlyFirebaseError(e)));
    } catch (e) {
      emit(AuthErrorState(message: _friendlyError(e)));
    }
  }

  // ───────────────────────────────────────────────
  // Backend call — POST /api/v1/auth/verify-otp
  // ───────────────────────────────────────────────
  Future<void> _callVerifyOtpBackend({
    required Emitter<AuthState> emit,
    required String idToken,
    required bool isDriver,
    String? fullName,
    String? phoneForBypass,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyOtp,
        data: {
          'firebaseIdToken': idToken,
          if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
          if (fullName == null && idToken == 'bypass-token') 'fullName': 'راكب تجريبي',
          if (phoneForBypass != null) 'phone': phoneForBypass,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final tokens = data['tokens'] as Map<String, dynamic>?;

        final accessToken = tokens?['accessToken'] as String? ?? data['accessToken'] as String? ?? '';
        final refreshToken = tokens?['refreshToken'] as String? ?? data['refreshToken'] as String? ?? '';
        
        final user = data['user'] as Map<String, dynamic>?;
        final userId = data['userId'] as String? ??
            user?['id'] as String? ??
            user?['_id'] as String? ??
            '';
        final role = user?['role'] as String? ?? data['role'] as String? ?? (isDriver ? 'driver' : 'passenger');
        final isNewUser = data['isNewUser'] as bool? ?? false;

        // Persist tokens securely.
        await Future.wait([
          _secureStorage.write(key: _kAccessToken, value: accessToken),
          _secureStorage.write(key: _kRefreshToken, value: refreshToken),
          _secureStorage.write(key: _kUserId, value: userId),
          _secureStorage.write(key: _kUserRole, value: role),
        ]);

        // Inject into Dio for all subsequent calls.
        _setDioAuthHeader(accessToken);

        emit(AuthSuccessState(
          userId: userId,
          role: role,
          isNewUser: isNewUser,
          accessToken: accessToken,
        ));
      } else {
        emit(const AuthErrorState(message: 'خطأ في الخادم — يرجى المحاولة مجدداً'));
      }
    } on DioException catch (e) {
      emit(AuthErrorState(message: _friendlyDioError(e)));
    } catch (e) {
      emit(AuthErrorState(message: _friendlyError(e)));
    }
  }

  // ───────────────────────────────────────────────
  // SaveNameEvent
  // ───────────────────────────────────────────────
  Future<void> _onSaveName(
    SaveNameEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    try {
      final accessToken = await _secureStorage.read(key: _kAccessToken) ?? '';
      final userId = await _secureStorage.read(key: _kUserId) ?? '';
      final role = await _secureStorage.read(key: _kUserRole) ?? 'passenger';

      // PATCH /api/v1/auth/profile to save the display name.
      final response = await _dio.patch(
        ApiEndpoints.updateProfile,
        data: {'fullName': event.fullName},
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Cache the name locally.
        await _secureStorage.write(
            key: _kUserName, value: event.fullName);

        emit(AuthSuccessState(
          userId: userId,
          role: role,
          isNewUser: false,
          accessToken: accessToken,
        ));
      } else {
        emit(const AuthErrorState(message: 'فشل حفظ الاسم — يرجى المحاولة مجدداً'));
      }
    } on DioException catch (e) {
      emit(AuthErrorState(message: _friendlyDioError(e)));
    } catch (e) {
      emit(AuthErrorState(message: _friendlyError(e)));
    }
  }

  // ───────────────────────────────────────────────
  // SignOutEvent
  // ───────────────────────────────────────────────
  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _clearStorage(),
      ]);

      // Remove the Authorization header.
      _dio.options.headers.remove('Authorization');

      emit(const AuthUnauthenticatedState());
    } catch (e) {
      // Force unauthenticated even if an error occurs — safety first.
      emit(const AuthUnauthenticatedState());
    }
  }

  // ───────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────

  void _setDioAuthHeader(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> _clearStorage() async {
    await Future.wait([
      _secureStorage.delete(key: _kAccessToken),
      _secureStorage.delete(key: _kRefreshToken),
      _secureStorage.delete(key: _kUserId),
      _secureStorage.delete(key: _kUserRole),
      _secureStorage.delete(key: _kUserName),
    ]);
  }

  String _friendlyFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صالح';
      case 'too-many-requests':
        return 'طلبات كثيرة — يرجى الانتظار قليلاً';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'session-expired':
        return 'انتهت صلاحية الرمز — يرجى إعادة الإرسال';
      case 'network-request-failed':
        return 'لا يوجد اتصال بالإنترنت';
      default:
        return e.message ?? 'خطأ في المصادقة';
    }
  }

  String _friendlyDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'انتهت مهلة الاتصال بالخادم';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'تعذّر الاتصال بالخادم — تحقق من الإنترنت';
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) return 'غير مصرح — يرجى إعادة تسجيل الدخول';
    if (statusCode == 404) return 'المستخدم غير موجود';
    if (statusCode == 500) return 'خطأ داخلي في الخادم';
    return e.message ?? 'خطأ في الشبكة';
  }

  String _friendlyError(dynamic e) {
    return e?.toString() ?? 'حدث خطأ غير متوقع';
  }
}
