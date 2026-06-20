// lib/features/auth/presentation/bloc/registration_event.dart
// ══════════════════════════════════════════════════════════
// EVO Driver — RegistrationBloc Events
//
// Event flow:
//   Step1Submitted → Step2Submitted → Step3Submitted
//   → Step4Submitted → RegistrationSubmitFinalEvent (API call)
// ══════════════════════════════════════════════════════════

import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => [];
}

// ─────────────────────────────────────────────────────────
// STEP 1 — Basic Info
// ─────────────────────────────────────────────────────────
class RegistrationStep1Submitted extends RegistrationEvent {
  final String fullName;
  final DateTime dob;
  final String cliqAlias;

  const RegistrationStep1Submitted({
    required this.fullName,
    required this.dob,
    required this.cliqAlias,
  });

  @override
  List<Object?> get props => [fullName, dob, cliqAlias];
}

// ─────────────────────────────────────────────────────────
// STEP 2 — Identity Documents
// ─────────────────────────────────────────────────────────
class RegistrationStep2Submitted extends RegistrationEvent {
  final String idNumber;
  final File idFrontFile;
  final File idBackFile;
  final File selfieFile;

  const RegistrationStep2Submitted({
    required this.idNumber,
    required this.idFrontFile,
    required this.idBackFile,
    required this.selfieFile,
  });

  @override
  List<Object?> get props => [idNumber, idFrontFile.path, idBackFile.path, selfieFile.path];
}

// ─────────────────────────────────────────────────────────
// STEP 3 — License + Criminal Clearance
// ─────────────────────────────────────────────────────────
class RegistrationStep3Submitted extends RegistrationEvent {
  final String licenseNumber;
  final File licenseFile;
  final File clearanceFile;

  const RegistrationStep3Submitted({
    required this.licenseNumber,
    required this.licenseFile,
    required this.clearanceFile,
  });

  @override
  List<Object?> get props => [licenseNumber, licenseFile.path, clearanceFile.path];
}

// ─────────────────────────────────────────────────────────
// STEP 4 — Vehicle Info
// Matches the actual DriverStep4Screen fields:
//   carModel, carPlate, carType, batteryCapacity (opt), rangeKm (opt)
// ─────────────────────────────────────────────────────────
class RegistrationStep4Submitted extends RegistrationEvent {
  final String carType;
  final String carModel;
  final String carPlate;
  final String? batteryCapacity;
  final String? rangeKm;

  const RegistrationStep4Submitted({
    required this.carType,
    required this.carModel,
    required this.carPlate,
    this.batteryCapacity,
    this.rangeKm,
  });

  @override
  List<Object?> get props => [carType, carModel, carPlate, batteryCapacity, rangeKm];
}

// ─────────────────────────────────────────────────────────
// FINAL SUBMIT — Triggers multipart POST to backend API
// Must be fired AFTER Step4Submitted so the BLoC has all data.
// ─────────────────────────────────────────────────────────
class RegistrationSubmitFinalEvent extends RegistrationEvent {
  const RegistrationSubmitFinalEvent();
}

// ─────────────────────────────────────────────────────────
// RESET — Clears all accumulated data (e.g., after error)
// ─────────────────────────────────────────────────────────
class RegistrationResetEvent extends RegistrationEvent {
  const RegistrationResetEvent();
}
