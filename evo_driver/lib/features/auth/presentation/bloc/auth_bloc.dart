// lib/features/auth/presentation/bloc/auth_bloc.dart
// ══════════════════════════════════════════════════════════
// EVO Driver — AuthBloc
//
// Firebase Phone Auth flow:
//   1. SendOtpEvent        → verifyPhoneNumber() → emit AuthOtpSentState
//   2. VerifyOtpEvent      → signInWithCredential() → POST /api/auth/driver/verify
//                          → stores JWT → emit AuthSuccessState
//   3. CheckAuthStatusEvent→ reads JWT from FlutterSecureStorage
//                          → validates with backend → emit AuthSuccessState or AuthUnauthenticatedState
//   4. SignOutEvent         → clears JWT → emit AuthUnauthenticatedState
// ══════════════════════════════════════════════════════════

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth;
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const String _jwtKey = 'evo_driver_jwt';
  static const String _userIdKey = 'evo_driver_user_id';
  static const String _roleKey = 'evo_driver_role';

  AuthBloc({
    required FirebaseAuth firebaseAuth,
    required Dio dio,
    required FlutterSecureStorage secureStorage,
  })  : _firebaseAuth = firebaseAuth,
        _dio = dio,
        _secureStorage = secureStorage,
        super(const AuthInitialState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<SignOutEvent>(_onSignOut);
  }

  // ─────────────────────────────────────────────────────────
  // CHECK AUTH STATUS
  // ─────────────────────────────────────────────────────────
  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    try {
      final jwt = await _secureStorage.read(key: _jwtKey);
      final userId = await _secureStorage.read(key: _userIdKey);
      final role = await _secureStorage.read(key: _roleKey);

      if (jwt == null || userId == null || role == null) {
        emit(const AuthUnauthenticatedState());
        return;
      }

      // Validate JWT with backend — silent token refresh
      final response = await _dio.get(
        '/api/v1/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $jwt'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final serverRole = data['role']?.toString() ?? role;
        final serverUserId = data['id']?.toString() ?? userId;

        emit(AuthSuccessState(
          userId: serverUserId,
          role: serverRole,
          isNewUser: false,
        ));
      } else {
        await _clearSession();
        emit(const AuthUnauthenticatedState());
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // JWT expired — clear and ask to login again
        await _clearSession();
        emit(const AuthUnauthenticatedState());
      } else {
        // Network error — let user in if JWT exists (offline-tolerant)
        final jwt = await _secureStorage.read(key: _jwtKey);
        final userId = await _secureStorage.read(key: _userIdKey);
        final role = await _secureStorage.read(key: _roleKey);
        if (jwt != null && userId != null && role != null) {
          emit(AuthSuccessState(
            userId: userId,
            role: role,
            isNewUser: false,
          ));
        } else {
          emit(const AuthUnauthenticatedState());
        }
      }
    } catch (_) {
      emit(const AuthUnauthenticatedState());
    }
  }

  // ─────────────────────────────────────────────────────────
  // SEND OTP
  // ─────────────────────────────────────────────────────────
  Future<void> _onSendOtp(
    SendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    // TEMPORARY BYPASS: Skip Firebase OTP and login directly
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final response = await _dio.post(
        '/api/v1/auth/verify-otp',
        data: {
          'firebaseIdToken': 'bypass-token',
          'phone': event.phoneNumber,
          'fullName': 'كابتن تجريبي',
        },
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        
        final tokens = data['tokens'] as Map<String, dynamic>?;
        final jwt = tokens?['accessToken']?.toString() ?? data['token']?.toString() ?? '';
        
        final user = data['user'] as Map<String, dynamic>?;
        final userId = user?['id']?.toString() ?? '';
        
        final role = user?['role']?.toString() ?? 'new';
        // Treat anyone who isn't an approved driver as a new user so they can register
        final isNewUser = data['isNewUser'] == true || role != 'driver';

        await _secureStorage.write(key: _jwtKey, value: jwt);
        await _secureStorage.write(key: _userIdKey, value: userId);
        await _secureStorage.write(key: _roleKey, value: role);

        _dio.options.headers['Authorization'] = 'Bearer $jwt';

        emit(AuthSuccessState(
          userId: userId,
          role: role,
          isNewUser: isNewUser,
        ));
      } else {
        emit(const AuthErrorState(message: 'خطأ في الخادم — يرجى المحاولة مجدداً'));
      }
    } catch (e) {
      emit(AuthErrorState(message: 'حدث خطأ: $e'));
    }
  }

  // ─────────────────────────────────────────────────────────
  // VERIFY OTP
  // ─────────────────────────────────────────────────────────
  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    try {
      // 1. Build Firebase credential
      final credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.otpCode,
      );

      // 2. Sign in with Firebase
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        emit(const AuthErrorState(message: 'فشل التحقق — يرجى المحاولة مجدداً'));
        return;
      }

      // 3. Get Firebase ID token
      final idToken = await firebaseUser.getIdToken();

      // 4. Exchange with EVO backend for JWT + role check
      final response = await _dio.post(
        '/api/auth/driver/verify',
        data: {
          'firebase_token': idToken,
          'phone': firebaseUser.phoneNumber,
          'is_driver': true,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final jwt = data['token']?.toString() ?? '';
        final userId = data['user']?['id']?.toString() ?? firebaseUser.uid;
        final role = data['user']?['role']?.toString() ?? 'new';
        final isNewUser = data['is_new_user'] == true || role == 'new';

        // 5. Persist JWT
        await _secureStorage.write(key: _jwtKey, value: jwt);
        await _secureStorage.write(key: _userIdKey, value: userId);
        await _secureStorage.write(key: _roleKey, value: role);

        // 6. Set Dio default auth header for subsequent requests
        _dio.options.headers['Authorization'] = 'Bearer $jwt';

        emit(AuthSuccessState(
          userId: userId,
          role: role,
          isNewUser: isNewUser,
        ));
      } else {
        emit(const AuthErrorState(
          message: 'خطأ في الخادم — يرجى المحاولة مجدداً',
        ));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthErrorState(message: _mapFirebaseError(e)));
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          'خطأ في الشبكة — تحقق من اتصالك';
      emit(AuthErrorState(message: msg));
    } catch (e) {
      emit(AuthErrorState(message: 'حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  // ─────────────────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────────────────
  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      // Notify backend (fire-and-forget — don't block UI)
      final jwt = await _secureStorage.read(key: _jwtKey);
      if (jwt != null) {
        _dio.post(
          '/api/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $jwt'}),
        ).ignore();
      }

      await _firebaseAuth.signOut();
      await _clearSession();
      emit(const AuthUnauthenticatedState());
    } catch (_) {
      // Force-clear regardless
      await _clearSession();
      emit(const AuthUnauthenticatedState());
    }
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────
  Future<void> _clearSession() async {
    await _secureStorage.delete(key: _jwtKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _roleKey);
    _dio.options.headers.remove('Authorization');
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صحيح';
      case 'too-many-requests':
        return 'طلبات كثيرة — انتظر قليلاً ثم حاول مجدداً';
      case 'invalid-verification-code':
        return 'رمز OTP غير صحيح';
      case 'session-expired':
        return 'انتهت صلاحية رمز OTP — أعد إرسال الرمز';
      case 'quota-exceeded':
        return 'تجاوزت الحصة المسموح بها — حاول لاحقاً';
      case 'network-request-failed':
        return 'خطأ في الشبكة — تحقق من اتصالك';
      case 'user-disabled':
        return 'هذا الحساب معطّل — تواصل مع الدعم';
      default:
        return 'خطأ في المصادقة: ${e.message ?? e.code}';
    }
  }
}
