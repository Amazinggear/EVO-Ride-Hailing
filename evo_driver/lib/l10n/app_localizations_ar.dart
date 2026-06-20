// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'EVO';

  @override
  String get whereToTitle => 'إلى أين؟';

  @override
  String get whereToHint => 'ابحث عن وجهتك...';

  @override
  String get currentLocation => 'موقعك الحالي';

  @override
  String get destinationLabel => 'الوجهة';

  @override
  String get confirmBooking => 'تأكيد الحجز';

  @override
  String get bookingConfirmed => 'تم تأكيد الحجز';

  @override
  String get evBasic => 'كهربائية عادية';

  @override
  String get evLuxury => 'كهربائية فاخرة';

  @override
  String get evSuv => 'كهربائية دفع رباعي';

  @override
  String co2Saved(double kg) {
    final intl.NumberFormat kgNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String kgString = kgNumberFormat.format(kg);

    return 'وفّرت $kgString كجم CO₂';
  }

  @override
  String get estimatedArrival => 'وقت الوصول التقديري';

  @override
  String minutes(int count) {
    return '$count دقيقة';
  }

  @override
  String get driverArriving => 'الكابتن في الطريق إليك';

  @override
  String get driverArrived => 'وصل الكابتن! 📍';

  @override
  String get rideStarted => 'الرحلة بدأت';

  @override
  String get rideCompleted => 'اكتملت رحلتك ✅';

  @override
  String get rideCancelled => 'تم إلغاء الرحلة';

  @override
  String get totalFare => 'المجموع';

  @override
  String get subtotal => 'المجموع قبل الخصم';

  @override
  String get discount => 'الخصم';

  @override
  String get jod => 'دينار';

  @override
  String get payWithCash => 'الدفع نقداً';

  @override
  String get payWithCard => 'الدفع بالبطاقة';

  @override
  String get cardNumber => 'رقم البطاقة';

  @override
  String get expiryDate => 'تاريخ الانتهاء';

  @override
  String get cvv => 'CVV';

  @override
  String get saveCard => 'حفظ البطاقة';

  @override
  String get addNewCard => 'إضافة بطاقة جديدة';

  @override
  String get promoCodeHint => 'أدخل كود الخصم';

  @override
  String get promoApply => 'تطبيق';

  @override
  String promoApplied(double amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'تم تطبيق الكود! خصم $amountString دينار';
  }

  @override
  String get promoInvalid => 'الكود غير صالح أو منتهي الصلاحية';

  @override
  String get goOnline => 'ابدأ العمل';

  @override
  String get goOffline => 'إيقاف العمل';

  @override
  String get youAreOnline => 'أنت متاح';

  @override
  String get youAreOffline => 'أنت غير متاح';

  @override
  String get dailyEarnings => 'أرباح اليوم';

  @override
  String get weeklyEarnings => 'أرباح الأسبوع';

  @override
  String get totalRides => 'إجمالي الرحلات';

  @override
  String get carbonOffset => 'CO₂ الموفّر';

  @override
  String get nearbyChargingStations => '⚡ محطات شحن قريبة';

  @override
  String get navigate => 'اتجاهات';

  @override
  String get available => 'متاح';

  @override
  String get unavailable => 'غير متاح';

  @override
  String get level2Charger => 'شاحن Level 2';

  @override
  String get dcFastCharger => 'شاحن DC سريع';

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get withdrawToBank => 'سحب إلى الحساب البنكي';

  @override
  String get withdrawAmount => 'مبلغ السحب';

  @override
  String get bankIban => 'رقم IBAN';

  @override
  String get bankName => 'اسم البنك';

  @override
  String get accountHolder => 'اسم صاحب الحساب';

  @override
  String get withdrawalRequested => 'تم إرسال طلب السحب';

  @override
  String get commission => 'عمولة EVO';

  @override
  String get driverRegistration => 'تسجيل كابتن';

  @override
  String get step1Title => 'معلوماتك الأساسية';

  @override
  String get step2Title => 'وثائق الهوية';

  @override
  String get step3Title => 'الرخصة والسوابق';

  @override
  String get step4Title => 'معلومات السيارة';

  @override
  String get step5Title => 'مراجعة وإرسال';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get email => 'البريد الإلكتروني (اختياري)';

  @override
  String get nationalId => 'رقم الهوية الوطنية';

  @override
  String get uploadNationalIdFront => 'ارفع صورة الهوية — الوجه الأمامي';

  @override
  String get uploadNationalIdBack => 'ارفع صورة الهوية — الوجه الخلفي';

  @override
  String get uploadSelfie => 'صورة شخصية (سيلفي)';

  @override
  String get uploadLicense => 'ارفع صورة رخصة القيادة';

  @override
  String get uploadClearance => 'ارفع شهادة عدم المحكومية';

  @override
  String get uploadCarPhoto => 'صورة السيارة';

  @override
  String get carModel => 'موديل السيارة';

  @override
  String get carPlate => 'رقم اللوحة';

  @override
  String get carType => 'نوع السيارة';

  @override
  String get batteryCapacity => 'سعة البطاريات (kWh)';

  @override
  String get rangeKm => 'المدى الزمني (كم)';

  @override
  String get submitApplication => 'إرسال الطلب';

  @override
  String get pendingApproval => 'طلبك قيد المراجعة';

  @override
  String get pendingApprovalMessage =>
      'سيتم مراجعة طلبك وإشعارك خلال 24-48 ساعة.';

  @override
  String get applicationApproved => 'تم اعتماد حسابك! 🎉';

  @override
  String get applicationRejected => 'تم رفض طلبك';

  @override
  String get moreInfoNeeded => 'نحتاج منك معلومات إضافية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get noDriversAvailable =>
      'لا يوجد كباتن متاحون الآن. يرجى المحاولة لاحقاً.';

  @override
  String get searchingForDriver => 'جارٍ البحث عن كابتن...';

  @override
  String get rideHistory => 'سجل الرحلات';

  @override
  String get noRidesYet => 'لا يوجد رحلات بعد';

  @override
  String get settings => 'الإعدادات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String get done => 'تم';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get error => 'حدث خطأ';

  @override
  String get unknownError => 'حدث خطأ غير متوقع. يرجى المحاولة مجدداً.';
}
