import 'package:evo_passenger/features/auth/presentation/bloc/auth_event.dart';
import 'package:evo_passenger/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';

import 'package:evo_passenger/core/constants/evo_colors.dart';
import '../bloc/auth_bloc.dart';

/// Phone Input Screen — Step 1 of passenger auth
/// User enters +962 Jordanian number
class PhoneInputScreen extends StatefulWidget {
  final bool isDriver;
  const PhoneInputScreen({super.key, this.isDriver = false});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSentState) {
            Navigator.pushNamed(context, '/verify-otp', arguments: {
              'verificationId': state.verificationId,
              'phone': _phoneController.text,
              'isDriver': widget.isDriver,
            });
          } else if (state is AuthErrorState) {
            setState(() => _errorText = state.message);
          }
          setState(() => _isLoading = state is AuthLoadingState);
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // EVO Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: EvoColors.primarySubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'EVO',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: EvoColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  widget.isDriver ? 'انضم كـ كابتن' : 'اهلاً بك في EVO',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: EvoColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أدخل رقم هاتفك للمتابعة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: EvoColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // Phone Field
                Container(
                  decoration: BoxDecoration(
                    color: EvoColors.lightBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _errorText != null ? EvoColors.error : EvoColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Country Code
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: EvoColors.border),
                          ),
                        ),
                        child: const Text(
                          '🇯🇴 +962',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: EvoColors.textPrimary,
                          ),
                        ),
                      ),

                      // Phone Number Input
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                          decoration: const InputDecoration(
                            hintText: '7XXXXXXXX',
                            hintStyle: TextStyle(color: EvoColors.textHint, letterSpacing: 1),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onChanged: (_) => setState(() => _errorText = null),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    style: const TextStyle(
                      color: EvoColors.error,
                      fontFamily: 'Cairo',
                      fontSize: 13,
                    ),
                  ),
                ],

                const Spacer(),

                // Send OTP Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'إرسال رمز التحقق',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Terms
                const Center(
                  child: Text(
                    'بالمتابعة، أنت توافق على شروط الخدمة وسياسة الخصوصية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: EvoColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      setState(() => _errorText = 'يرجى إدخال رقم هاتف صالح');
      return;
    }

    context.read<AuthBloc>().add(
      SendOtpEvent(phoneNumber: '+962$phone'),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}

/// OTP Verification Screen — Step 2
class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phone;
  final bool isDriver;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phone,
    required this.isDriver,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendTimer = 30;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        fontFamily: 'Cairo',
        color: EvoColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: EvoColors.lightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvoColors.border),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: EvoColors.primary, width: 2),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('رمز التحقق'),
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccessState) {
            if (widget.isDriver) {
              Navigator.pushReplacementNamed(context, '/driver-registration');
            } else if (state.isNewUser) {
              Navigator.pushReplacementNamed(context, '/name-input');
            } else {
              Navigator.pushReplacementNamed(context, '/passenger-home');
            }
          } else if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          setState(() => _isLoading = state is AuthLoadingState);
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.lock_outline_rounded, size: 64, color: EvoColors.primary),
              const SizedBox(height: 24),
              const Text(
                'أدخل الرمز المرسل إلى',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: EvoColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.phone,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: EvoColors.textPrimary,
                ),
              ),
              const SizedBox(height: 40),

              // 6-digit OTP input (Pinput package)
              Pinput(
                length: 6,
                controller: _otpController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                onCompleted: (code) => _verifyOtp(code),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // Resend Timer
              _resendTimer > 0
                  ? Text(
                      'إعادة الإرسال بعد $_resendTimer ثانية',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: EvoColors.textSecondary,
                      ),
                    )
                  : TextButton(
                      onPressed: () {
                        setState(() => _resendTimer = 30);
                        _startResendTimer();
                        context.read<AuthBloc>().add(
                          SendOtpEvent(phoneNumber: widget.phone),
                        );
                      },
                      child: const Text(
                        'إعادة إرسال الرمز',
                        style: TextStyle(fontFamily: 'Cairo', color: EvoColors.primary),
                      ),
                    ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _verifyOtp(_otpController.text),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text('تحقق', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyOtp(String code) {
    if (code.length != 6) return;
    context.read<AuthBloc>().add(
      VerifyOtpEvent(
        verificationId: widget.verificationId,
        smsCode: code,
        isDriver: widget.isDriver,
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}




