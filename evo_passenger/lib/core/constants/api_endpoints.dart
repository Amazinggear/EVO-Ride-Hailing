// ─────────────────────────────────────────────────────────────────────────────
// EVO API Endpoints
// All backend API paths — matches routes/index.js exactly
// ─────────────────────────────────────────────────────────────────────────────

class ApiEndpoints {
  ApiEndpoints._();

  static const String _base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000', // Android emulator → localhost
  );

  // Auth
  static const String verifyOtp = '$_base/api/v1/auth/verify-otp';
  static const String refreshToken = '$_base/api/v1/auth/refresh-token';
  static const String updateProfile = '$_base/api/v1/auth/profile';

  // Driver Registration
  static const String driverRegStep1 = '$_base/api/v1/driver/register/step-1';
  static const String driverRegStep2 = '$_base/api/v1/driver/register/step-2';
  static const String driverRegStep3 = '$_base/api/v1/driver/register/step-3';
  static const String driverRegStep4 = '$_base/api/v1/driver/register/step-4';
  static const String driverRegSubmit = '$_base/api/v1/driver/register/submit';
  static const String driverRegStatus = '$_base/api/v1/driver/register/status';

  // Rides
  static const String nearbyDrivers = '$_base/api/v1/rides/nearby-drivers';
  static const String estimateFare = '$_base/api/v1/rides/estimate';
  static const String requestRide = '$_base/api/v1/rides/request';
  static const String rideHistory = '$_base/api/v1/rides/history';
  static String cancelRide(String id) => '$_base/api/v1/rides/$id/cancel';
  static String acceptRide(String id) => '$_base/api/v1/rides/$id/accept';
  static String arriveRide(String id) => '$_base/api/v1/rides/$id/arrive';
  static String startRide(String id) => '$_base/api/v1/rides/$id/start';
  static String completeRide(String id) => '$_base/api/v1/rides/$id/complete';

  // Driver Ops
  static const String toggleOnline = '$_base/api/v1/driver/toggle-online';

  // Wallet
  static const String walletBalance = '$_base/api/v1/wallet/balance';
  static const String walletTransactions = '$_base/api/v1/wallet/transactions';
  static const String walletWithdraw = '$_base/api/v1/wallet/withdraw';

  // Charging Stations
  static const String chargingStations = '$_base/api/v1/charging-stations';
  static String chargingStation(String id) => '$_base/api/v1/charging-stations/$id';

  // Promo
  static const String validatePromo = '$_base/api/v1/promo/validate';

  // WebSocket Server
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );
}
