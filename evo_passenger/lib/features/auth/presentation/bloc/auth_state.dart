import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any check has been performed.
class AuthInitialState extends AuthState {
  const AuthInitialState();
}

/// Any async operation is in progress (OTP send, OTP verify, token check …).
class AuthLoadingState extends AuthState {
  const AuthLoadingState();
}

/// Firebase has dispatched the OTP — the UI should navigate to the OTP screen.
class AuthOtpSentState extends AuthState {
  final String verificationId;
  final String phone;

  const AuthOtpSentState({
    required this.verificationId,
    required this.phone,
  });

  @override
  List<Object?> get props => [verificationId, phone];
}

/// Authentication succeeded and JWT tokens are now stored securely.
///
/// [isNewUser] — true when the user just created their account (no name set).
/// [role]      — 'passenger' | 'driver'
/// [accessToken] — the JWT returned from the backend (useful for header injection).
class AuthSuccessState extends AuthState {
  final String userId;
  final String role;
  final bool isNewUser;
  final String? accessToken;

  const AuthSuccessState({
    required this.userId,
    required this.role,
    this.isNewUser = false,
    this.accessToken,
  });

  @override
  List<Object?> get props => [userId, role, isNewUser, accessToken];
}

/// An error occurred during any auth step.
class AuthErrorState extends AuthState {
  final String message;

  const AuthErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

/// No valid JWT found in storage — user must authenticate.
class AuthUnauthenticatedState extends AuthState {
  const AuthUnauthenticatedState();
}
