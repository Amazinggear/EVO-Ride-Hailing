import 'package:evo_passenger/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:evo_passenger/features/auth/presentation/bloc/auth_event.dart';
import 'package:evo_passenger/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:evo_passenger/core/constants/evo_colors.dart';

/// Name Input Screen — shown only to NEW passengers after their first OTP
/// verification, before they reach the home map.
///
/// Route: /name-input
class PassengerNameInputScreen extends StatefulWidget {
  const PassengerNameInputScreen({super.key});

  @override
  State<PassengerNameInputScreen> createState() =>
      _PassengerNameInputScreenState();
}

class _PassengerNameInputScreenState
    extends State<PassengerNameInputScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccessState && !state.isNewUser) {
            context.go('/passenger-home');
          } else if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: EvoColors.error,
              ),
            );
          }
          setState(() => _isLoading = state is AuthLoadingState);
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Icon
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: EvoColors.primarySubtle,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: EvoColors.primary,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    'ما اسمك؟',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: EvoColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سنستخدم اسمك لمخاطبتك داخل التطبيق',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      color: EvoColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'الاسم الكامل',
                      hintStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        color: EvoColors.textHint,
                      ),
                      filled: true,
                      fillColor: EvoColors.lightBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: EvoColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: EvoColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: EvoColors.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: EvoColors.error),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال اسمك';
                      }
                      if (value.trim().length < 2) {
                        return 'الاسم قصير جداً';
                      }
                      return null;
                    },
                  ),

                  const Spacer(),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EvoColors.primary,
                        disabledBackgroundColor:
                            EvoColors.primary.withOpacity(0.5),
                        padding:
                            const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
                              'متابعة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveName() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          SaveNameEvent(fullName: _nameController.text.trim()),
        );
  }
}



