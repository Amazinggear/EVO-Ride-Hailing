import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'EVO'**
  String get appName;

  /// No description provided for @whereToTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلى أين؟'**
  String get whereToTitle;

  /// No description provided for @whereToHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن وجهتك...'**
  String get whereToHint;

  /// No description provided for @currentLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقعك الحالي'**
  String get currentLocation;

  /// No description provided for @destinationLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوجهة'**
  String get destinationLabel;

  /// No description provided for @confirmBooking.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحجز'**
  String get confirmBooking;

  /// No description provided for @bookingConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد الحجز'**
  String get bookingConfirmed;

  /// No description provided for @evBasic.
  ///
  /// In ar, this message translates to:
  /// **'كهربائية عادية'**
  String get evBasic;

  /// No description provided for @evLuxury.
  ///
  /// In ar, this message translates to:
  /// **'كهربائية فاخرة'**
  String get evLuxury;

  /// No description provided for @evSuv.
  ///
  /// In ar, this message translates to:
  /// **'كهربائية دفع رباعي'**
  String get evSuv;

  /// No description provided for @co2Saved.
  ///
  /// In ar, this message translates to:
  /// **'وفّرت {kg} كجم CO₂'**
  String co2Saved(double kg);

  /// No description provided for @estimatedArrival.
  ///
  /// In ar, this message translates to:
  /// **'وقت الوصول التقديري'**
  String get estimatedArrival;

  /// No description provided for @minutes.
  ///
  /// In ar, this message translates to:
  /// **'{count} دقيقة'**
  String minutes(int count);

  /// No description provided for @driverArriving.
  ///
  /// In ar, this message translates to:
  /// **'الكابتن في الطريق إليك'**
  String get driverArriving;

  /// No description provided for @driverArrived.
  ///
  /// In ar, this message translates to:
  /// **'وصل الكابتن! 📍'**
  String get driverArrived;

  /// No description provided for @rideStarted.
  ///
  /// In ar, this message translates to:
  /// **'الرحلة بدأت'**
  String get rideStarted;

  /// No description provided for @rideCompleted.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت رحلتك ✅'**
  String get rideCompleted;

  /// No description provided for @rideCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الرحلة'**
  String get rideCancelled;

  /// No description provided for @totalFare.
  ///
  /// In ar, this message translates to:
  /// **'المجموع'**
  String get totalFare;

  /// No description provided for @subtotal.
  ///
  /// In ar, this message translates to:
  /// **'المجموع قبل الخصم'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In ar, this message translates to:
  /// **'الخصم'**
  String get discount;

  /// No description provided for @jod.
  ///
  /// In ar, this message translates to:
  /// **'دينار'**
  String get jod;

  /// No description provided for @payWithCash.
  ///
  /// In ar, this message translates to:
  /// **'الدفع نقداً'**
  String get payWithCash;

  /// No description provided for @payWithCard.
  ///
  /// In ar, this message translates to:
  /// **'الدفع بالبطاقة'**
  String get payWithCard;

  /// No description provided for @cardNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم البطاقة'**
  String get cardNumber;

  /// No description provided for @expiryDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانتهاء'**
  String get expiryDate;

  /// No description provided for @cvv.
  ///
  /// In ar, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @saveCard.
  ///
  /// In ar, this message translates to:
  /// **'حفظ البطاقة'**
  String get saveCard;

  /// No description provided for @addNewCard.
  ///
  /// In ar, this message translates to:
  /// **'إضافة بطاقة جديدة'**
  String get addNewCard;

  /// No description provided for @promoCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كود الخصم'**
  String get promoCodeHint;

  /// No description provided for @promoApply.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get promoApply;

  /// No description provided for @promoApplied.
  ///
  /// In ar, this message translates to:
  /// **'تم تطبيق الكود! خصم {amount} دينار'**
  String promoApplied(double amount);

  /// No description provided for @promoInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الكود غير صالح أو منتهي الصلاحية'**
  String get promoInvalid;

  /// No description provided for @goOnline.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ العمل'**
  String get goOnline;

  /// No description provided for @goOffline.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف العمل'**
  String get goOffline;

  /// No description provided for @youAreOnline.
  ///
  /// In ar, this message translates to:
  /// **'أنت متاح'**
  String get youAreOnline;

  /// No description provided for @youAreOffline.
  ///
  /// In ar, this message translates to:
  /// **'أنت غير متاح'**
  String get youAreOffline;

  /// No description provided for @dailyEarnings.
  ///
  /// In ar, this message translates to:
  /// **'أرباح اليوم'**
  String get dailyEarnings;

  /// No description provided for @weeklyEarnings.
  ///
  /// In ar, this message translates to:
  /// **'أرباح الأسبوع'**
  String get weeklyEarnings;

  /// No description provided for @totalRides.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الرحلات'**
  String get totalRides;

  /// No description provided for @carbonOffset.
  ///
  /// In ar, this message translates to:
  /// **'CO₂ الموفّر'**
  String get carbonOffset;

  /// No description provided for @nearbyChargingStations.
  ///
  /// In ar, this message translates to:
  /// **'⚡ محطات شحن قريبة'**
  String get nearbyChargingStations;

  /// No description provided for @navigate.
  ///
  /// In ar, this message translates to:
  /// **'اتجاهات'**
  String get navigate;

  /// No description provided for @available.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get unavailable;

  /// No description provided for @level2Charger.
  ///
  /// In ar, this message translates to:
  /// **'شاحن Level 2'**
  String get level2Charger;

  /// No description provided for @dcFastCharger.
  ///
  /// In ar, this message translates to:
  /// **'شاحن DC سريع'**
  String get dcFastCharger;

  /// No description provided for @currentBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد الحالي'**
  String get currentBalance;

  /// No description provided for @withdrawToBank.
  ///
  /// In ar, this message translates to:
  /// **'سحب إلى الحساب البنكي'**
  String get withdrawToBank;

  /// No description provided for @withdrawAmount.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ السحب'**
  String get withdrawAmount;

  /// No description provided for @bankIban.
  ///
  /// In ar, this message translates to:
  /// **'رقم IBAN'**
  String get bankIban;

  /// No description provided for @bankName.
  ///
  /// In ar, this message translates to:
  /// **'اسم البنك'**
  String get bankName;

  /// No description provided for @accountHolder.
  ///
  /// In ar, this message translates to:
  /// **'اسم صاحب الحساب'**
  String get accountHolder;

  /// No description provided for @withdrawalRequested.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب السحب'**
  String get withdrawalRequested;

  /// No description provided for @commission.
  ///
  /// In ar, this message translates to:
  /// **'عمولة EVO'**
  String get commission;

  /// No description provided for @driverRegistration.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل كابتن'**
  String get driverRegistration;

  /// No description provided for @step1Title.
  ///
  /// In ar, this message translates to:
  /// **'معلوماتك الأساسية'**
  String get step1Title;

  /// No description provided for @step2Title.
  ///
  /// In ar, this message translates to:
  /// **'وثائق الهوية'**
  String get step2Title;

  /// No description provided for @step3Title.
  ///
  /// In ar, this message translates to:
  /// **'الرخصة والسوابق'**
  String get step3Title;

  /// No description provided for @step4Title.
  ///
  /// In ar, this message translates to:
  /// **'معلومات السيارة'**
  String get step4Title;

  /// No description provided for @step5Title.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة وإرسال'**
  String get step5Title;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @dateOfBirth.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد'**
  String get dateOfBirth;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني (اختياري)'**
  String get email;

  /// No description provided for @nationalId.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهوية الوطنية'**
  String get nationalId;

  /// No description provided for @uploadNationalIdFront.
  ///
  /// In ar, this message translates to:
  /// **'ارفع صورة الهوية — الوجه الأمامي'**
  String get uploadNationalIdFront;

  /// No description provided for @uploadNationalIdBack.
  ///
  /// In ar, this message translates to:
  /// **'ارفع صورة الهوية — الوجه الخلفي'**
  String get uploadNationalIdBack;

  /// No description provided for @uploadSelfie.
  ///
  /// In ar, this message translates to:
  /// **'صورة شخصية (سيلفي)'**
  String get uploadSelfie;

  /// No description provided for @uploadLicense.
  ///
  /// In ar, this message translates to:
  /// **'ارفع صورة رخصة القيادة'**
  String get uploadLicense;

  /// No description provided for @uploadClearance.
  ///
  /// In ar, this message translates to:
  /// **'ارفع شهادة عدم المحكومية'**
  String get uploadClearance;

  /// No description provided for @uploadCarPhoto.
  ///
  /// In ar, this message translates to:
  /// **'صورة السيارة'**
  String get uploadCarPhoto;

  /// No description provided for @carModel.
  ///
  /// In ar, this message translates to:
  /// **'موديل السيارة'**
  String get carModel;

  /// No description provided for @carPlate.
  ///
  /// In ar, this message translates to:
  /// **'رقم اللوحة'**
  String get carPlate;

  /// No description provided for @carType.
  ///
  /// In ar, this message translates to:
  /// **'نوع السيارة'**
  String get carType;

  /// No description provided for @batteryCapacity.
  ///
  /// In ar, this message translates to:
  /// **'سعة البطاريات (kWh)'**
  String get batteryCapacity;

  /// No description provided for @rangeKm.
  ///
  /// In ar, this message translates to:
  /// **'المدى الزمني (كم)'**
  String get rangeKm;

  /// No description provided for @submitApplication.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get submitApplication;

  /// No description provided for @pendingApproval.
  ///
  /// In ar, this message translates to:
  /// **'طلبك قيد المراجعة'**
  String get pendingApproval;

  /// No description provided for @pendingApprovalMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيتم مراجعة طلبك وإشعارك خلال 24-48 ساعة.'**
  String get pendingApprovalMessage;

  /// No description provided for @applicationApproved.
  ///
  /// In ar, this message translates to:
  /// **'تم اعتماد حسابك! 🎉'**
  String get applicationApproved;

  /// No description provided for @applicationRejected.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض طلبك'**
  String get applicationRejected;

  /// No description provided for @moreInfoNeeded.
  ///
  /// In ar, this message translates to:
  /// **'نحتاج منك معلومات إضافية'**
  String get moreInfoNeeded;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @selectLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اختر اللغة'**
  String get selectLanguage;

  /// No description provided for @noDriversAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد كباتن متاحون الآن. يرجى المحاولة لاحقاً.'**
  String get noDriversAvailable;

  /// No description provided for @searchingForDriver.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ البحث عن كابتن...'**
  String get searchingForDriver;

  /// No description provided for @rideHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل الرحلات'**
  String get rideHistory;

  /// No description provided for @noRidesYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد رحلات بعد'**
  String get noRidesYet;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get error;

  /// No description provided for @unknownError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. يرجى المحاولة مجدداً.'**
  String get unknownError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
