import 'package:evo_driver/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:evo_driver/core/constants/evo_colors.dart';
import 'core/theme/evo_dark_theme.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/registration_bloc.dart';
import 'features/driver/presentation/bloc/driver_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation — web doesn't support this API
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: EvoColors.darkBg,
    ));
  }

  // Firebase — web needs explicit FirebaseOptions
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'dummy_key',
        appId: 'dummy_id',
        messagingSenderId: 'dummy_sender',
        projectId: 'dummy_project',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // OneSignal — mobile only, not supported on web
  if (!kIsWeb) {
    OneSignal.initialize(const String.fromEnvironment('ONESIGNAL_APP_ID'));
    OneSignal.Notifications.requestPermission(true);
  }

  await initDependencies();

  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('preferred_language') ?? 'ar';

  runApp(EvoDriverApp(initialLocale: Locale(savedLang)));
}

class EvoDriverApp extends StatelessWidget {
  final Locale initialLocale;
  const EvoDriverApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()..add(const CheckAuthStatusEvent())),
        BlocProvider(create: (_) => sl<RegistrationBloc>()),
        BlocProvider(create: (_) => sl<DriverBloc>()),
      ],
      child: _AppContent(initialLocale: initialLocale),
    );
  }
}

class _AppContent extends StatefulWidget {
  final Locale initialLocale;
  const _AppContent({required this.initialLocale});

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  void _changeLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    final router = createDriverRouter(context);
    return MaterialApp.router(
      title: 'EVO Captain',
      debugShowCheckedModeBanner: false,
      theme: EvoDarkTheme.theme,
      routerConfig: router,
      locale: _locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      // ✅ Full localization delegates — required for Arabic RTL + Material widgets
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return _LocaleProvider(
          locale: _locale,
          onLocaleChange: _changeLocale,
          child: child!,
        );
      },
    );
  }
}

class _LocaleProvider extends InheritedWidget {
  final Locale locale;
  final void Function(Locale) onLocaleChange;

  const _LocaleProvider({
    required this.locale,
    required this.onLocaleChange,
    required super.child,
  });

  static _LocaleProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LocaleProvider>();

  @override
  bool updateShouldNotify(_LocaleProvider old) => old.locale != locale;
}

void changeDriverLanguage(BuildContext context, String langCode) async {
  _LocaleProvider.of(context)?.onLocaleChange(Locale(langCode));
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('preferred_language', langCode);
}
