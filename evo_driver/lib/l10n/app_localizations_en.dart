// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'EVO';

  @override
  String get whereToTitle => 'Where to?';

  @override
  String get whereToHint => 'Search your destination...';

  @override
  String get currentLocation => 'Your current location';

  @override
  String get destinationLabel => 'Destination';

  @override
  String get confirmBooking => 'Confirm Booking';

  @override
  String get bookingConfirmed => 'Booking Confirmed';

  @override
  String get evBasic => 'EV Basic';

  @override
  String get evLuxury => 'EV Luxury';

  @override
  String get evSuv => 'EV SUV';

  @override
  String co2Saved(double kg) {
    final intl.NumberFormat kgNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String kgString = kgNumberFormat.format(kg);

    return '$kgString kg CO₂ saved';
  }

  @override
  String get estimatedArrival => 'Estimated Arrival';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get driverArriving => 'Driver is on the way';

  @override
  String get driverArrived => 'Driver has arrived! 📍';

  @override
  String get rideStarted => 'Ride started';

  @override
  String get rideCompleted => 'Ride completed ✅';

  @override
  String get rideCancelled => 'Ride cancelled';

  @override
  String get totalFare => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Discount';

  @override
  String get jod => 'JOD';

  @override
  String get payWithCash => 'Pay with Cash';

  @override
  String get payWithCard => 'Pay with Card';

  @override
  String get cardNumber => 'Card Number';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get cvv => 'CVV';

  @override
  String get saveCard => 'Save Card';

  @override
  String get addNewCard => 'Add New Card';

  @override
  String get promoCodeHint => 'Enter promo code';

  @override
  String get promoApply => 'Apply';

  @override
  String promoApplied(double amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'Code applied! $amountString JOD discount';
  }

  @override
  String get promoInvalid => 'Invalid or expired code';

  @override
  String get goOnline => 'Go Online';

  @override
  String get goOffline => 'Go Offline';

  @override
  String get youAreOnline => 'You\'re Online';

  @override
  String get youAreOffline => 'You\'re Offline';

  @override
  String get dailyEarnings => 'Daily Earnings';

  @override
  String get weeklyEarnings => 'Weekly Earnings';

  @override
  String get totalRides => 'Total Rides';

  @override
  String get carbonOffset => 'Carbon Offset';

  @override
  String get nearbyChargingStations => '⚡ Nearby Charging Stations';

  @override
  String get navigate => 'Navigate';

  @override
  String get available => 'Available';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get level2Charger => 'Level 2 Charger';

  @override
  String get dcFastCharger => 'DC Fast Charger';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get withdrawToBank => 'Withdraw to Bank';

  @override
  String get withdrawAmount => 'Withdrawal Amount';

  @override
  String get bankIban => 'IBAN Number';

  @override
  String get bankName => 'Bank Name';

  @override
  String get accountHolder => 'Account Holder Name';

  @override
  String get withdrawalRequested => 'Withdrawal Requested';

  @override
  String get commission => 'EVO Commission';

  @override
  String get driverRegistration => 'Driver Registration';

  @override
  String get step1Title => 'Basic Information';

  @override
  String get step2Title => 'Identity Documents';

  @override
  String get step3Title => 'License & Clearance';

  @override
  String get step4Title => 'Vehicle Information';

  @override
  String get step5Title => 'Review & Submit';

  @override
  String get fullName => 'Full Name';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get phone => 'Phone Number';

  @override
  String get email => 'Email (optional)';

  @override
  String get nationalId => 'National ID Number';

  @override
  String get uploadNationalIdFront => 'Upload National ID — Front';

  @override
  String get uploadNationalIdBack => 'Upload National ID — Back';

  @override
  String get uploadSelfie => 'Personal Photo (Selfie)';

  @override
  String get uploadLicense => 'Upload Driving License';

  @override
  String get uploadClearance => 'Upload Criminal Record Clearance';

  @override
  String get uploadCarPhoto => 'Car Photo';

  @override
  String get carModel => 'Car Model';

  @override
  String get carPlate => 'Plate Number';

  @override
  String get carType => 'Car Type';

  @override
  String get batteryCapacity => 'Battery Capacity (kWh)';

  @override
  String get rangeKm => 'Range (km)';

  @override
  String get submitApplication => 'Submit Application';

  @override
  String get pendingApproval => 'Application Under Review';

  @override
  String get pendingApprovalMessage =>
      'Your application will be reviewed and you\'ll be notified within 24-48 hours.';

  @override
  String get applicationApproved => 'Your account is approved! 🎉';

  @override
  String get applicationRejected => 'Your application was rejected';

  @override
  String get moreInfoNeeded => 'Additional information required';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get noDriversAvailable =>
      'No drivers available nearby. Please try again later.';

  @override
  String get searchingForDriver => 'Searching for a driver...';

  @override
  String get rideHistory => 'Ride History';

  @override
  String get noRidesYet => 'No rides yet';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Log Out';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get unknownError => 'An unexpected error occurred. Please try again.';
}
