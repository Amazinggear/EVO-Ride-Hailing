// lib/features/auth/presentation/bloc/auth_state.dart
// ══════════════════════════════════════════════════════════
// EVO Driver — Auth States
// ══════════════════════════════════════════════════════════

import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// App just launched — auth check not yet performed.
class AuthInitialState extends AuthState {
  const AuthInitialState();
}

/// Any async auth operation is in-flight (OTP send, verification, sign-out).
class AuthLoadingState extends AuthState {
  const AuthLoadingState();
}

/// OTP has been sent to the driver's phone number.
/// Carries [verificationId] to pass to VerifyOtpEvent.
/// [phoneNumber] is displayed in the UI for UX confirmation.
class AuthOtpSentState extends AuthState {
  final String verificationId;
  final String phoneNumber;

  const AuthOtpSentState({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [verificationId, phoneNumber];
}

/// Driver authenticated successfully.
/// [role] — expected "driver" for registered captains, "new" for first-timers.
/// [isNewUser] — true → redirect to /driver-register/step-1.
///               false + role=="driver" → redirect to /driver-home.
///               false + other role → show error/sign out.
class AuthSuccessState extends AuthState {
  final String userId;
  final String role;
  final bool isNewUser;

  const AuthSuccessState({
    required this.userId,
    required this.role,
    required this.isNewUser,
  });

  @override
  List<Object?> get props => [userId, role, isNewUser];
}

/// Any auth error — OTP expired, wrong code, network failure, etc.
class AuthErrorState extends AuthState {
  final String message;

  const AuthErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

/// No valid session found — driver must authenticate from scratch.
class AuthUnauthenticatedState extends AuthState {
  const AuthUnauthenticatedState();
}
