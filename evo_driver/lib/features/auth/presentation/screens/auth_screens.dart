// lib/features/auth/presentation/screens/auth_screens.dart
// ══════════════════════════════════════════════════════════
// EVO Driver — Phone Input + OTP Verification Screens
//
// Design: Dark mode (EvoColors.darkBg, darkCard, textOnDark)
// Font:   Cairo throughout
// Auth:   Fires AuthBloc events, listens to state changes
// ══════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:evo_driver/core/constants/evo_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

// ══════════════════════════════════════════════════════════
// PHONE INPUT SCREEN
// ══════════════════════════════════════════════════════════
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Jordan country code hardcoded for driver app
  static const String _countryCode = '+962';

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber {
    final raw = _phoneController.text.trim().replaceAll(' ', '');
    // If user typed leading 0, strip it (e.g. 0791234567 → 791234567)
    final normalized = raw.startsWith('0') ? raw.substring(1) : raw;
    return '$_countryCode$normalized';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(SendOtpEvent(phoneNumber: _fullPhoneNumber));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSentState) {
          context.push('/verify-otp', extra: {
            'verificationId': state.verificationId,
            'phoneNumber': state.phoneNumber,
          });
        } else if (state is AuthErrorState) {
          _showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: EvoColors.darkBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // ── EVO Logo + Brand ───────────────────────
                  _EvoCaptainLogo(glowAnimation: _glowAnimation),
                  const SizedBox(height: 48),

                  // ── Heading ────────────────────────────────
                  const Text(
                    'مرحباً بك كابتن! 🚗⚡',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: EvoColors.textOnDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أدخل رقم هاتفك للبدء — سنرسل لك رمز التحقق',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: EvoColors.textOnDarkSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Phone Field ────────────────────────────
                  const Text(
                    'رقم الهاتف',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: EvoColors.textOnDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: EvoColors.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _phoneFocus.hasFocus
                            ? EvoColors.primary
                            : EvoColors.borderDark,
                        width: _phoneFocus.hasFocus ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Country code prefix
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: EvoColors.borderDark,
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                '🇯🇴',
                                style: TextStyle(fontSize: 20),
                              ),
                              SizedBox(width: 6),
                              Text(
                                _countryCode,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: EvoColors.textOnDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Phone number field
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            inputFormatters: [
                              _PhoneNumberFormatter(),
                            ],
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: EvoColors.textOnDark,
                              letterSpacing: 2,
                            ),
                            decoration: const InputDecoration(
                              hintText: '079 123 4567',
                              hintStyle: TextStyle(
                                fontFamily: 'Cairo',
                                color: EvoColors.textOnDarkSecondary,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              errorStyle: TextStyle(height: 0),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              final digits = value?.replaceAll(' ', '') ?? '';
                              if (digits.isEmpty) return 'أدخل رقم الهاتف';
                              if (digits.length < 9) {
                                return 'رقم الهاتف يجب أن يكون 9 أرقام';
                              }
                              return null;
                            },
                          ),
                        ),
                        // Clear button
                        if (_phoneController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _phoneController.clear();
                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(14),
                              child: Icon(
                                Icons.cancel_rounded,
                                color: EvoColors.textOnDarkSecondary,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Inline validation error
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _phoneController.text.replaceAll(' ', '').isNotEmpty
                        && _phoneController.text.replaceAll(' ', '').length < 9
                        ? const Padding(
                            padding: EdgeInsets.only(top: 4, right: 4),
                            child: Text(
                              'يجب إدخال 9 أرقام على الأقل',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: EvoColors.error,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 36),

                  // ── Submit Button ──────────────────────────
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoadingState;
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EvoColors.primary,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor:
                                EvoColors.primary.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'إرسال رمز التحقق',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Terms Note ─────────────────────────────
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: EvoColors.textOnDarkSecondary,
                          height: 1.8,
                        ),
                        children: [
                          TextSpan(text: 'بالتسجيل، أنت توافق على '),
                          TextSpan(
                            text: 'شروط الخدمة',
                            style: TextStyle(
                              color: EvoColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: EvoColors.primary,
                            ),
                          ),
                          TextSpan(text: ' و'),
                          TextSpan(
                            text: 'سياسة الخصوصية',
                            style: TextStyle(
                              color: EvoColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: EvoColors.primary,
                            ),
                          ),
                          TextSpan(text: ' الخاصة بـ EVO'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Driver-only notice ─────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EvoColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EvoColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.electric_bolt_rounded,
                          color: EvoColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'هذا التطبيق مخصص للكباتن فقط.\nإذا كنت زبوناً، حمّل تطبيق EVO للركاب.',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: EvoColors.textOnDarkSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// OTP VERIFICATION SCREEN
// ══════════════════════════════════════════════════════════
class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _otpLength = 6;
  static const int _resendCooldownSeconds = 60;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  int _resendTimer = _resendCooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNodes[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = _resendCooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendTimer--);
      }
    });
  }

  String get _otpValue =>
      _controllers.map((c) => c.text).join();

  bool get _isComplete => _otpValue.length == _otpLength;

  void _onDigitEntered(int index, String value) {
    if (value.length == 1) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-submit when last digit entered
        if (_isComplete) _submit();
      }
    } else if (value.isEmpty && index > 0) {
      // Backspace — go to previous field
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _onPaste(String pasted) {
    final digits = pasted.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= _otpLength) {
      for (int i = 0; i < _otpLength; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes.last.unfocus();
      setState(() {});
      if (_isComplete) _submit();
    }
  }

  void _submit() {
    if (!_isComplete) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(VerifyOtpEvent(
          verificationId: widget.verificationId,
          otpCode: _otpValue,
        ));
  }

  void _resend() {
    if (_resendTimer > 0) return;
    // Clear OTP boxes
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    _startResendTimer();

    final phoneFromState = widget.phoneNumber;
    context.read<AuthBloc>().add(SendOtpEvent(phoneNumber: phoneFromState));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccessState) {
          // Router's redirect guard will handle navigation
        } else if (state is AuthErrorState) {
          // Clear boxes on error
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
          setState(() {});
          _showError(context, state.message);
        } else if (state is AuthOtpSentState) {
          // OTP resent successfully
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم إرسال رمز جديد',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: EvoColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: EvoColors.darkBg,
        appBar: AppBar(
          backgroundColor: EvoColors.darkBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: EvoColors.textOnDark,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'التحقق من الرقم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: EvoColors.textOnDark,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // ── Icon ──────────────────────────────────────
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: EvoColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: EvoColors.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.sms_outlined,
                    color: EvoColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Heading ───────────────────────────────────
                const Text(
                  'رمز التحقق',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: EvoColors.textOnDark,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: EvoColors.textOnDarkSecondary,
                      height: 1.7,
                    ),
                    children: [
                      const TextSpan(text: 'أرسلنا رمزاً مكوّناً من 6 أرقام إلى\n'),
                      TextSpan(
                        text: widget.phoneNumber,
                        style: const TextStyle(
                          color: EvoColors.textOnDark,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── OTP Boxes ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_otpLength, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < _otpLength - 1 ? 10 : 0,
                      ),
                      child: _OtpBox(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        onChanged: (value) => _onDigitEntered(index, value),
                        onPaste: _onPaste,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),

                // ── Verify Button ─────────────────────────────
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoadingState;
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading || !_isComplete ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EvoColors.primary,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor:
                              EvoColors.primary.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : const Text(
                                'تحقق من الرمز',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // ── Resend Row ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'لم يصلك الرمز؟ ',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: EvoColors.textOnDarkSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _resendTimer <= 0 ? _resend : null,
                      child: Text(
                        _resendTimer > 0
                            ? 'إعادة الإرسال ($_resendTimer ث)'
                            : 'إعادة الإرسال',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _resendTimer > 0
                              ? EvoColors.textOnDarkSecondary
                              : EvoColors.primary,
                          decoration: _resendTimer <= 0
                              ? TextDecoration.underline
                              : null,
                          decorationColor: EvoColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ── Security note ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: EvoColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EvoColors.borderDark),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: EvoColors.textOnDarkSecondary,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'رمز OTP سري لا تشاركه مع أحد. لن يطلبه منك فريق EVO أبداً.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: EvoColors.textOnDarkSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// OTP BOX WIDGET
// ══════════════════════════════════════════════════════════
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onPaste;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = controller.text.isNotEmpty;
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 58,
      decoration: BoxDecoration(
        color: isFilled
            ? EvoColors.primary.withOpacity(0.1)
            : EvoColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? EvoColors.primary
              : isFilled
                  ? EvoColors.primary.withOpacity(0.5)
                  : EvoColors.borderDark,
          width: isFocused ? 2 : 1.5,
        ),
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (RawKeyEvent event) {
          // Handle paste via Ctrl+V / Cmd+V
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.keyV &&
              (event.isControlPressed || event.isMetaPressed)) {
            Clipboard.getData(Clipboard.kTextPlain).then((data) {
              if (data?.text != null) onPaste(data!.text!);
            });
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: EvoColors.textOnDark,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            counterText: '',
          ),
          onChanged: onChanged,
          maxLength: 1,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// EVO CAPTAIN LOGO WIDGET
// ══════════════════════════════════════════════════════════
class _EvoCaptainLogo extends StatelessWidget {
  final Animation<double> glowAnimation;

  const _EvoCaptainLogo({required this.glowAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        return Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: EvoColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: EvoColors.primary.withOpacity(glowAnimation.value * 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        EvoColors.primary.withOpacity(glowAnimation.value * 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.electric_bolt_rounded,
                color: EvoColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EVO',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: EvoColors.textOnDark,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'كابتن',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: EvoColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
// PHONE NUMBER TEXT INPUT FORMATTER
// Groups digits as "079 123 4567"
// ══════════════════════════════════════════════════════════
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }
    
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ══════════════════════════════════════════════════════════
// SHARED HELPER — Show error snackbar
// ══════════════════════════════════════════════════════════
void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: EvoColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ),
  );
}

