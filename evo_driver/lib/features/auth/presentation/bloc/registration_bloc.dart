// lib/features/auth/presentation/bloc/registration_bloc.dart
// ══════════════════════════════════════════════════════════
// EVO Driver — RegistrationBloc
//
// Multi-step registration state machine:
//   Steps 1-4  → accumulate data in memory (no API call)
//   FinalSubmit → POST /api/v1/drivers/register (multipart)
//   Success    → emit RegistrationSuccessState (router navigates)
//   Error      → emit RegistrationErrorState (screen shows snackbar)
//
// Dio instance injected via sl<Dio>() from the DI container.
// The Dio instance already has the Authorization header set
// after OTP verification (see AuthBloc._onVerifyOtp).
// ══════════════════════════════════════════════════════════

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'registration_event.dart';
import 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final Dio _dio;

  // ─── Accumulated data across all 4 steps ───────────────
  // Stored as File objects (not just paths) for direct FormData use.
  String? _fullName;
  DateTime? _dob;
  String? _cliqAlias;

  String? _idNumber;
  File? _idFrontFile;
  File? _idBackFile;
  File? _selfieFile;

  String? _licenseNumber;
  File? _licenseFile;
  File? _clearanceFile;

  String? _carType;
  String? _carModel;
  String? _carPlate;
  String? _batteryCapacity;
  String? _rangeKm;

  RegistrationBloc({required Dio dio})
      : _dio = dio,
        super(const RegistrationInitialState()) {
    on<RegistrationStep1Submitted>(_onStep1);
    on<RegistrationStep2Submitted>(_onStep2);
    on<RegistrationStep3Submitted>(_onStep3);
    on<RegistrationStep4Submitted>(_onStep4);
    on<RegistrationSubmitFinalEvent>(_onSubmitFinal);
    on<RegistrationResetEvent>(_onReset);
  }

  // ─────────────────────────────────────────────────────────
  // STEP 1 — Store basic info, emit step-1 complete
  // ─────────────────────────────────────────────────────────
  void _onStep1(
    RegistrationStep1Submitted event,
    Emitter<RegistrationState> emit,
  ) {
    _fullName = event.fullName;
    _dob = event.dob;
    _cliqAlias = event.cliqAlias;

    emit(RegistrationStep1CompleteState(data: {
      'fullName': _fullName,
      'dob': _dob?.toIso8601String(),
      'cliqAlias': _cliqAlias,
    }));
  }

  // ─────────────────────────────────────────────────────────
  // STEP 2 — Store identity documents, emit step-2 complete
  // ─────────────────────────────────────────────────────────
  void _onStep2(
    RegistrationStep2Submitted event,
    Emitter<RegistrationState> emit,
  ) {
    _idNumber = event.idNumber;
    _idFrontFile = event.idFrontFile;
    _idBackFile = event.idBackFile;
    _selfieFile = event.selfieFile;

    emit(RegistrationStep2CompleteState(data: {
      'idNumber': _idNumber,
      'idFrontPath': _idFrontFile?.path,
      'idBackPath': _idBackFile?.path,
      'selfiePath': _selfieFile?.path,
    }));
  }

  // ─────────────────────────────────────────────────────────
  // STEP 3 — Store license + clearance, emit step-3 complete
  // ─────────────────────────────────────────────────────────
  void _onStep3(
    RegistrationStep3Submitted event,
    Emitter<RegistrationState> emit,
  ) {
    _licenseNumber = event.licenseNumber;
    _licenseFile = event.licenseFile;
    _clearanceFile = event.clearanceFile;

    emit(RegistrationStep3CompleteState(data: {
      'licenseNumber': _licenseNumber,
      'licensePath': _licenseFile?.path,
      'clearancePath': _clearanceFile?.path,
    }));
  }

  // ─────────────────────────────────────────────────────────
  // STEP 4 — Store vehicle info, emit step-4 complete
  // NOTE: Does NOT fire the API. Caller adds SubmitFinalEvent next.
  // ─────────────────────────────────────────────────────────
  void _onStep4(
    RegistrationStep4Submitted event,
    Emitter<RegistrationState> emit,
  ) {
    _carType = event.carType;
    _carModel = event.carModel;
    _carPlate = event.carPlate;
    _batteryCapacity = event.batteryCapacity;
    _rangeKm = event.rangeKm;

    emit(RegistrationStep4CompleteState(data: {
      'carType': _carType,
      'carModel': _carModel,
      'carPlate': _carPlate,
      'batteryCapacity': _batteryCapacity,
      'rangeKm': _rangeKm,
    }));
  }

  // ─────────────────────────────────────────────────────────
  // FINAL SUBMIT — Multipart POST to /api/v1/drivers/register
  // ─────────────────────────────────────────────────────────
  Future<void> _onSubmitFinal(
    RegistrationSubmitFinalEvent event,
    Emitter<RegistrationState> emit,
  ) async {
    // Guard: ensure all steps were completed
    if (_fullName == null ||
        _dob == null ||
        _cliqAlias == null ||
        _idNumber == null ||
        _idFrontFile == null ||
        _idBackFile == null ||
        _selfieFile == null ||
        _licenseNumber == null ||
        _licenseFile == null ||
        _clearanceFile == null ||
        _carType == null ||
        _carModel == null ||
        _carPlate == null) {
      emit(const RegistrationErrorState(
        message: 'بيانات التسجيل غير مكتملة — يرجى إعادة المحاولة من البداية',
      ));
      return;
    }

    emit(const RegistrationLoadingState());

    try {
      final formData = FormData.fromMap({
        // ── Step 1 ──
        'full_name': _fullName,
        'date_of_birth': _dob!.toIso8601String().split('T').first, // YYYY-MM-DD
        'cliq_alias': _cliqAlias,

        // ── Step 2 ──
        'national_id_number': _idNumber,
        if (_idFrontFile != null)
          'id_front': await MultipartFile.fromFile(
            _idFrontFile!.path,
            filename: 'id_front.jpg',
          ),
        if (_idBackFile != null)
          'id_back': await MultipartFile.fromFile(
            _idBackFile!.path,
            filename: 'id_back.jpg',
          ),
        if (_selfieFile != null)
          'selfie': await MultipartFile.fromFile(
            _selfieFile!.path,
            filename: 'selfie.jpg',
          ),

        // ── Step 3 ──
        'license_number': _licenseNumber,
        if (_licenseFile != null)
          'license_photo': await MultipartFile.fromFile(
            _licenseFile!.path,
            filename: 'license.jpg',
          ),
        if (_clearanceFile != null)
          'criminal_clearance': await MultipartFile.fromFile(
            _clearanceFile!.path,
            filename: 'clearance${_clearanceFile!.path.endsWith('.pdf') ? '.pdf' : '.jpg'}',
          ),

        // ── Step 4 ──
        'car_type': _carType,
        'car_model': _carModel,
        'car_plate': _carPlate,
        if (_batteryCapacity != null && _batteryCapacity!.isNotEmpty)
          'battery_capacity_kwh': _batteryCapacity,
        if (_rangeKm != null && _rangeKm!.isNotEmpty)
          'range_km': _rangeKm,
      });

      final response = await _dio.post(
        '/api/v1/drivers/register',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60), // generous for file uploads
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        emit(const RegistrationSuccessState());
      } else {
        final msg = response.data?['message']?.toString() ??
            'حدث خطأ — رمز الخطأ: ${response.statusCode}';
        emit(RegistrationErrorState(message: msg));
      }
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message']?.toString();
      final statusCode = e.response?.statusCode;

      String errorMessage;
      if (serverMsg != null && serverMsg.isNotEmpty) {
        errorMessage = serverMsg;
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'انتهت مهلة الاتصال — تحقق من إنترنتك وحاول مجدداً';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'خطأ في الاتصال — تحقق من اتصالك بالإنترنت';
      } else if (statusCode == 409) {
        errorMessage = 'هذا الحساب مسجّل مسبقاً — تواصل مع الدعم';
      } else if (statusCode == 422) {
        errorMessage = 'بيانات غير صالحة — يرجى مراجعة المعلومات المدخلة';
      } else if (statusCode == 401) {
        errorMessage = 'انتهت الجلسة — يرجى تسجيل الدخول مجدداً';
      } else {
        errorMessage = 'حدث خطأ غير متوقع — يرجى المحاولة مجدداً';
      }

      emit(RegistrationErrorState(message: errorMessage));
    } catch (e) {
      emit(RegistrationErrorState(
        message: 'خطأ غير متوقع: ${e.toString()}',
      ));
    }
  }

  // ─────────────────────────────────────────────────────────
  // RESET — Clear all accumulated data and return to initial
  // ─────────────────────────────────────────────────────────
  void _onReset(
    RegistrationResetEvent event,
    Emitter<RegistrationState> emit,
  ) {
    _fullName = null;
    _dob = null;
    _cliqAlias = null;
    _idNumber = null;
    _idFrontFile = null;
    _idBackFile = null;
    _selfieFile = null;
    _licenseNumber = null;
    _licenseFile = null;
    _clearanceFile = null;
    _carType = null;
    _carModel = null;
    _carPlate = null;
    _batteryCapacity = null;
    _rangeKm = null;

    emit(const RegistrationInitialState());
  }
}
