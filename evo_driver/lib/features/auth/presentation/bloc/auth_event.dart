// lib/features/auth/presentation/bloc/auth_event.dart
// ══════════════════════════════════════════════════════════
// EVO Driver — Auth Events
// ══════════════════════════════════════════════════════════

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on app startup — checks FlutterSecureStorage for existing JWT.
/// Navigates to driver-home if valid, phone-input if not.
class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

/// Begins Firebase phone auth — sends OTP SMS to [phoneNumber].
/// [phoneNumber] must be in E.164 format, e.g. "+962791234567".
class SendOtpEvent extends AuthEvent {
  final String phoneNumber;

  const SendOtpEvent({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

/// Verifies the 6-digit [otpCode] against Firebase's [verificationId].
/// On success, exchanges Firebase ID token for EVO JWT via backend.
class VerifyOtpEvent extends AuthEvent {
  final String verificationId;
  final String otpCode;

  const VerifyOtpEvent({
    required this.verificationId,
    required this.otpCode,
  });

  @override
  List<Object?> get props => [verificationId, otpCode];
}

/// Signs the driver out — clears JWT from secure storage, revokes session.
class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}
