import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on app startup — checks secure storage for a valid JWT.
class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

/// Step 1 — triggers Firebase verifyPhoneNumber.
class SendOtpEvent extends AuthEvent {
  final String phoneNumber;

  const SendOtpEvent({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

/// Step 2 — takes the verificationId from Firebase and the 6-digit code the
/// user typed, then calls our backend to exchange for a JWT.
class VerifyOtpEvent extends AuthEvent {
  final String verificationId;
  final String smsCode;

  /// When [isDriver] is true the OTP flow is being used for driver on-boarding.
  final bool isDriver;

  const VerifyOtpEvent({
    required this.verificationId,
    required this.smsCode,
    this.isDriver = false,
  });

  @override
  List<Object?> get props => [verificationId, smsCode, isDriver];
}

/// Step 3 (new users only) — persists the passenger's display name via the
/// backend profile endpoint, then transitions to the home screen.
class SaveNameEvent extends AuthEvent {
  final String fullName;

  const SaveNameEvent({required this.fullName});

  @override
  List<Object?> get props => [fullName];
}

/// Signs out the current user: clears Firebase session + local secure storage.
class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}
