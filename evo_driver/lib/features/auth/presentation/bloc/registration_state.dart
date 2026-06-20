// lib/features/auth/presentation/bloc/registration_state.dart
// ══════════════════════════════════════════════════════════
// EVO Driver — RegistrationBloc States
//
// States 1-4 carry a `data` map with the accumulated fields
// so screens can inspect them if needed (debug / review step).
// ══════════════════════════════════════════════════════════

import 'package:equatable/equatable.dart';

abstract class RegistrationState extends Equatable {
  const RegistrationState();

  @override
  List<Object?> get props => [];
}

// ─────────────────────────────────────────────────────────
// INITIAL — No data collected yet
// ─────────────────────────────────────────────────────────
class RegistrationInitialState extends RegistrationState {
  const RegistrationInitialState();
}

// ─────────────────────────────────────────────────────────
// STEP 1 COMPLETE — Basic info stored
// ─────────────────────────────────────────────────────────
class RegistrationStep1CompleteState extends RegistrationState {
  final Map<String, dynamic> data;

  const RegistrationStep1CompleteState({required this.data});

  @override
  List<Object?> get props => [data];
}

// ─────────────────────────────────────────────────────────
// STEP 2 COMPLETE — Identity docs stored
// ─────────────────────────────────────────────────────────
class RegistrationStep2CompleteState extends RegistrationState {
  final Map<String, dynamic> data;

  const RegistrationStep2CompleteState({required this.data});

  @override
  List<Object?> get props => [data];
}

// ─────────────────────────────────────────────────────────
// STEP 3 COMPLETE — License + clearance stored
// ─────────────────────────────────────────────────────────
class RegistrationStep3CompleteState extends RegistrationState {
  final Map<String, dynamic> data;

  const RegistrationStep3CompleteState({required this.data});

  @override
  List<Object?> get props => [data];
}

// ─────────────────────────────────────────────────────────
// STEP 4 COMPLETE — Vehicle info stored
// ─────────────────────────────────────────────────────────
class RegistrationStep4CompleteState extends RegistrationState {
  final Map<String, dynamic> data;

  const RegistrationStep4CompleteState({required this.data});

  @override
  List<Object?> get props => [data];
}

// ─────────────────────────────────────────────────────────
// LOADING — API call in progress
// ─────────────────────────────────────────────────────────
class RegistrationLoadingState extends RegistrationState {
  const RegistrationLoadingState();
}

// ─────────────────────────────────────────────────────────
// SUCCESS — Backend accepted the registration (HTTP 201)
// Router should navigate to /driver-register/step-5
// ─────────────────────────────────────────────────────────
class RegistrationSuccessState extends RegistrationState {
  const RegistrationSuccessState();
}

// ─────────────────────────────────────────────────────────
// ERROR — API or network failure
// ─────────────────────────────────────────────────────────
class RegistrationErrorState extends RegistrationState {
  final String message;

  const RegistrationErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
