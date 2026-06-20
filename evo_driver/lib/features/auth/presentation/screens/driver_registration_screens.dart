import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:evo_driver/core/constants/evo_colors.dart';
import '../bloc/registration_bloc.dart';
import '../bloc/registration_event.dart';
import '../bloc/registration_state.dart';

// ══════════════════════════════════════════════════════════════════
// DRIVER REGISTRATION FLOW — 5 Steps
// Step 1: Basic Info (Name, DOB, CliQ alias — إجباري)
// Step 2: Identity (National ID front/back, selfie)
// Step 3: License + Criminal Clearance
// Step 4: Vehicle Info (car type: 5 options)
// Step 5: Confirmation/Status
// ══════════════════════════════════════════════════════════════════

/// ════════════════════════════════════════
/// Progress Indicator (shared across steps)
/// ════════════════════════════════════════
class _RegistrationProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _RegistrationProgress({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep - 1;
            final isActive = index == currentStep - 1;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isCompleted || isActive
                      ? EvoColors.primary
                      : EvoColors.borderDark,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'الخطوة $currentStep من $totalSteps',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: EvoColors.textOnDarkSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// ════════════════════════════════════════
/// STEP 1: Basic Info
/// Name, DOB, CliQ Alias (MANDATORY)
/// ════════════════════════════════════════
class DriverStep1Screen extends StatefulWidget {
  const DriverStep1Screen({super.key});

  @override
  State<DriverStep1Screen> createState() => _DriverStep1ScreenState();
}

class _DriverStep1ScreenState extends State<DriverStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _cliqController = TextEditingController();
  DateTime? _selectedDob;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvoColors.darkBg,
      appBar: AppBar(
        title: const Text('تسجيل كابتن جديد'),
        backgroundColor: EvoColors.darkBg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _RegistrationProgress(currentStep: 1, totalSteps: 5),
              const SizedBox(height: 32),

              // Title
              const Text(
                'المعلومات الأساسية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: EvoColors.textOnDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'أدخل بياناتك الشخصية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: EvoColors.textOnDarkSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Full Name
              _buildLabel('الاسم الكامل'),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: EvoColors.textOnDark, fontFamily: 'Cairo'),
                decoration: _inputDecoration('محمد أحمد العبدالله', Icons.person_outline),
                validator: (v) => v == null || v.trim().length < 3 ? 'يرجى إدخال الاسم الكامل' : null,
              ),
              const SizedBox(height: 20),

              // Date of Birth
              _buildLabel('تاريخ الميلاد'),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                style: const TextStyle(color: EvoColors.textOnDark, fontFamily: 'Cairo'),
                decoration: _inputDecoration('DD/MM/YYYY', Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1995),
                    firstDate: DateTime(1960),
                    lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                    builder: (context, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(primary: EvoColors.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDob = picked;
                      _dobController.text =
                          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                    });
                  }
                },
                validator: (_) => _selectedDob == null ? 'يرجى اختيار تاريخ الميلاد' : null,
              ),
              const SizedBox(height: 20),

              // CliQ Alias — MANDATORY
              _buildLabel('محفظة كليك (CliQ Alias)', required: true, isImportant: true),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EvoColors.primary.withOpacity(0.4), width: 1.5),
                ),
                child: TextFormField(
                  controller: _cliqController,
                  style: const TextStyle(color: EvoColors.textOnDark, fontFamily: 'Cairo'),
                  decoration: _inputDecoration(
                    'مثال: 0791234567 أو اسم المستخدم',
                    Icons.account_balance_wallet_outlined,
                  ).copyWith(
                    fillColor: EvoColors.primary.withOpacity(0.05),
                    border: InputBorder.none,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'محفظة كليك إجبارية — الزبائن يمكنهم الدفع عبر كليك'
                      : null,
                ),
              ),

              // CliQ info box
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EvoColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EvoColors.primary.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: EvoColors.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ملاحظة: الزبون ممكن يدفع كليك مباشرة لك — لذلك محفظة كليك إجبارية لقبول طلبك',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: EvoColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onNext,
                  child: const Text('التالي ←'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool required = false, bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: EvoColors.textOnDark,
            ),
          ),
          if (isImportant) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: EvoColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'إجباري',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: EvoColors.textOnDarkSecondary, fontFamily: 'Cairo'),
      prefixIcon: Icon(icon, color: EvoColors.textOnDarkSecondary, size: 20),
      filled: true,
      fillColor: EvoColors.darkCard,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EvoColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EvoColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EvoColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EvoColors.error, width: 2),
      ),
    );
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      context.read<RegistrationBloc>().add(RegistrationStep1Submitted(
        fullName: _nameController.text.trim(),
        dob: _selectedDob!,
        cliqAlias: _cliqController.text.trim(),
      ));
      context.go('/driver-register/step-2');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _cliqController.dispose();
    super.dispose();
  }
}

/// ════════════════════════════════════════
/// STEP 2: Identity Documents
/// National ID (front/back) + Selfie
/// ════════════════════════════════════════
class DriverStep2Screen extends StatefulWidget {
  final Map<String, dynamic> stepData;
  const DriverStep2Screen({super.key, required this.stepData});

  @override
  State<DriverStep2Screen> createState() => _DriverStep2ScreenState();
}

class _DriverStep2ScreenState extends State<DriverStep2Screen> {
  final _idNumberController = TextEditingController();
  File? _idFront, _idBack, _selfie;
  final _picker = ImagePicker();

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        final file = File(image.path);
        if (type == 'front') _idFront = file;
        if (type == 'back') _idBack = file;
        if (type == 'selfie') _selfie = file;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvoColors.darkBg,
      appBar: AppBar(
        title: const Text('الهوية الشخصية'),
        backgroundColor: EvoColors.darkBg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _RegistrationProgress(currentStep: 2, totalSteps: 5),
            const SizedBox(height: 32),

            const Text(
              'وثائق الهوية',
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 24,
                fontWeight: FontWeight.w800, color: EvoColors.textOnDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ارفع صور الهوية الوطنية وصورة شخصية',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: EvoColors.textOnDarkSecondary),
            ),
            const SizedBox(height: 32),

            // National ID Number
            const Text(
              'رقم الهوية الوطنية',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: EvoColors.textOnDark),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _idNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              style: const TextStyle(color: EvoColors.textOnDark, fontFamily: 'Cairo', letterSpacing: 2),
              decoration: InputDecoration(
                hintText: '1234567890',
                hintStyle: const TextStyle(color: EvoColors.textOnDarkSecondary, fontFamily: 'Cairo'),
                prefixIcon: const Icon(Icons.badge_outlined, color: EvoColors.textOnDarkSecondary),
                filled: true,
                fillColor: EvoColors.darkCard,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: EvoColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: EvoColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Photo Upload Cards
            _buildUploadCard(
              label: 'الهوية — الوجه الأمامي',
              icon: Icons.credit_card,
              file: _idFront,
              onTap: () => _pickImage('front'),
            ),
            const SizedBox(height: 12),
            _buildUploadCard(
              label: 'الهوية — الوجه الخلفي',
              icon: Icons.credit_card_outlined,
              file: _idBack,
              onTap: () => _pickImage('back'),
            ),
            const SizedBox(height: 12),
            _buildUploadCard(
              label: 'صورة شخصية (Selfie)',
              icon: Icons.person_outline,
              file: _selfie,
              onTap: () async {
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  preferredCameraDevice: CameraDevice.front,
                );
                if (image != null) setState(() => _selfie = File(image.path));
              },
              hint: 'التقط صورة من الكاميرا الأمامية',
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canProceed() ? _onNext : null,
                child: const Text('التالي ←'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() =>
      _idNumberController.text.trim().length >= 9 &&
      _idFront != null &&
      _idBack != null &&
      _selfie != null;

  Widget _buildUploadCard({
    required String label,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
    String? hint,
  }) {
    final hasFile = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: hasFile ? EvoColors.primary.withOpacity(0.1) : EvoColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile ? EvoColors.primary : EvoColors.borderDark,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: hasFile
            ? Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      bottomLeft: Radius.circular(13),
                    ),
                    child: Image.file(file, width: 90, height: 90, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Cairo', fontSize: 14,
                        fontWeight: FontWeight.w600, color: EvoColors.primary,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.check_circle, color: EvoColors.primary, size: 28),
                  ),
                ],
              )
            : Row(
                children: [
                  const SizedBox(width: 20),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: EvoColors.borderDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: EvoColors.textOnDarkSecondary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'Cairo', fontSize: 14,
                            fontWeight: FontWeight.w600, color: EvoColors.textOnDark,
                          ),
                        ),
                        if (hint != null)
                          Text(hint, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: EvoColors.textOnDarkSecondary)),
                        if (hint == null)
                          const Text('انقر لاختيار صورة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: EvoColors.textOnDarkSecondary)),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.upload_outlined, color: EvoColors.textOnDarkSecondary),
                  ),
                ],
              ),
      ),
    );
  }

  void _onNext() {
    context.read<RegistrationBloc>().add(RegistrationStep2Submitted(
      idNumber: _idNumberController.text.trim(),
      idFrontFile: _idFront!,
      idBackFile: _idBack!,
      selfieFile: _selfie!,
    ));
    context.go('/driver-register/step-3');
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }
}

/// ════════════════════════════════════════
/// STEP 3: License + Criminal Clearance
/// ════════════════════════════════════════
class DriverStep3Screen extends StatefulWidget {
  final Map<String, dynamic> stepData;
  const DriverStep3Screen({super.key, required this.stepData});

  @override
  State<DriverStep3Screen> createState() => _DriverStep3ScreenState();
}

class _DriverStep3ScreenState extends State<DriverStep3Screen> {
  final _licenseNumberController = TextEditingController();
  File? _licensePhoto;
  File? _criminalClearance;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, maxWidth: 1920, imageQuality: 85,
    );
    if (image != null) setState(() => _licensePhoto = File(image.path));
  }

  Future<void> _pickCriminalDoc() async {
    // Allow PDF or image
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _criminalClearance = File(result.files.single.path!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvoColors.darkBg,
      appBar: AppBar(title: const Text('الرخصة والسجل العدلي'), backgroundColor: EvoColors.darkBg),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _RegistrationProgress(currentStep: 3, totalSteps: 5),
            const SizedBox(height: 32),

            const Text(
              'رخصة القيادة والسجل العدلي',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w800, color: EvoColors.textOnDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'ارفع رخصة القيادة وشهادة حسن السيرة والسلوك',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: EvoColors.textOnDarkSecondary),
            ),
            const SizedBox(height: 32),

            // License Number
            const Text('رقم الرخصة', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: EvoColors.textOnDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _licenseNumberController,
              style: const TextStyle(color: EvoColors.textOnDark, fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'أدخل رقم الرخصة',
                hintStyle: const TextStyle(color: EvoColors.textOnDarkSecondary, fontFamily: 'Cairo'),
                prefixIcon: const Icon(Icons.drive_eta_outlined, color: EvoColors.textOnDarkSecondary),
                filled: true, fillColor: EvoColors.darkCard,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: EvoColors.borderDark)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: EvoColors.primary, width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            _buildDocumentCard(
              label: 'صورة رخصة القيادة',
              icon: Icons.drive_eta,
              file: _licensePhoto,
              onTap: _pickImage,
              accept: 'صورة',
            ),
            const SizedBox(height: 12),
            _buildDocumentCard(
              label: 'شهادة حسن السيرة والسلوك',
              icon: Icons.verified_user_outlined,
              file: _criminalClearance,
              onTap: _pickCriminalDoc,
              accept: 'PDF أو صورة',
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canProceed() ? _onNext : null,
                child: const Text('التالي ←'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String label,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
    required String accept,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: file != null ? EvoColors.primary.withOpacity(0.08) : EvoColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: file != null ? EvoColors.primary : EvoColors.borderDark,
            width: file != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: file != null ? EvoColors.primary.withOpacity(0.2) : EvoColors.borderDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                file != null ? Icons.check_circle_outline : icon,
                color: file != null ? EvoColors.primary : EvoColors.textOnDarkSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600,
                    color: file != null ? EvoColors.primary : EvoColors.textOnDark,
                  )),
                  const SizedBox(height: 2),
                  Text(
                    file != null ? 'تم الرفع ✓' : 'اقبل: $accept',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.textOnDarkSecondary),
                  ),
                ],
              ),
            ),
            Icon(file != null ? Icons.edit_outlined : Icons.upload_file_outlined,
                color: EvoColors.textOnDarkSecondary),
          ],
        ),
      ),
    );
  }

  bool _canProceed() =>
      _licenseNumberController.text.trim().isNotEmpty &&
      _licensePhoto != null &&
      _criminalClearance != null;

  void _onNext() {
    context.read<RegistrationBloc>().add(RegistrationStep3Submitted(
      licenseNumber: _licenseNumberController.text.trim(),
      licenseFile: _licensePhoto!,
      clearanceFile: _criminalClearance!,
    ));
    context.go('/driver-register/step-4');
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    super.dispose();
  }
}

/// ════════════════════════════════════════
/// STEP 4: Vehicle Info
/// Car type: 5 options (MINI, TAXI, SEDAN, SUV, Luxury)
/// ════════════════════════════════════════
class DriverStep4Screen extends StatefulWidget {
  final Map<String, dynamic> stepData;
  const DriverStep4Screen({super.key, required this.stepData});

  @override
  State<DriverStep4Screen> createState() => _DriverStep4ScreenState();
}

class _DriverStep4ScreenState extends State<DriverStep4Screen> {
  final _carModelController = TextEditingController();
  final _carPlateController = TextEditingController();
  final _batteryController = TextEditingController();
  final _rangeController = TextEditingController();
  String? _selectedCarType;

  // 5 car types per the new blueprint
  static const _carTypes = [
    {'id': 'ev_mini', 'label': 'EV MINI', 'desc': 'سيارة اقتصادية صغيرة', 'icon': '🚗'},
    {'id': 'ev_taxi', 'label': 'EV TAXI', 'desc': 'تاكسي كهربائي بالعداد', 'icon': '🚕'},
    {'id': 'ev_sedan', 'label': 'EV SEDAN', 'desc': 'سيدان مريحة', 'icon': '🚙'},
    {'id': 'ev_suv', 'label': 'EV SUV', 'desc': 'سيارة عائلية واسعة', 'icon': '🚐'},
    {'id': 'ev_luxury', 'label': 'EV Luxury', 'desc': 'سيارة فاخرة', 'icon': '🏎️'},
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistrationBloc, RegistrationState>(
      listenWhen: (prev, curr) =>
          curr is RegistrationSuccessState ||
          curr is RegistrationErrorState ||
          curr is RegistrationLoadingState,
      listener: (context, state) {
        if (state is RegistrationSuccessState) {
          context.go('/driver-register/step-5');
        } else if (state is RegistrationErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: EvoColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is RegistrationLoadingState;
        return Stack(
          children: [
            Scaffold(
      backgroundColor: EvoColors.darkBg,
      appBar: AppBar(title: const Text('معلومات السيارة'), backgroundColor: EvoColors.darkBg),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _RegistrationProgress(currentStep: 4, totalSteps: 5),
            const SizedBox(height: 32),

            const Text(
              'معلومات السيارة الكهربائية',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w800, color: EvoColors.textOnDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'أدخل تفاصيل سيارتك الكهربائية',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: EvoColors.textOnDarkSecondary),
            ),
            const SizedBox(height: 32),

            // Car Model
            _buildFieldLabel('موديل السيارة'),
            TextField(
              controller: _carModelController,
              style: const TextStyle(color: EvoColors.textOnDark, fontFamily: 'Cairo'),
              decoration: _inputDec('مثال: Nissan Leaf 2024', Icons.directions_car_outlined),
            ),
            const SizedBox(height: 16),

            // Plate Number
            _buildFieldLabel('رقم اللوحة'),
            TextField(
              controller: _carPlateController,
              style: const TextStyle(color: EvoColors.textOnDark, fontFamily: 'Cairo', letterSpacing: 2),
              decoration: _inputDec('مثال: 87-12345', Icons.pin_outlined),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),

            // Car Type Selection
            _buildFieldLabel('نوع السيارة ⚡'),
            const SizedBox(height: 12),
            ...List.generate(_carTypes.length, (i) {
              final type = _carTypes[i];
              final isSelected = _selectedCarType == type['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCarType = type['id']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? EvoColors.primary.withOpacity(0.12) : EvoColors.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? EvoColors.primary : EvoColors.borderDark,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(type['icon']!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type['label']!,
                              style: TextStyle(
                                fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700,
                                color: isSelected ? EvoColors.primary : EvoColors.textOnDark,
                              ),
                            ),
                            Text(
                              type['desc']!,
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.textOnDarkSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: EvoColors.primary, size: 24),
                    ],
                  ),
                ),
              );
            }),

            // EV TAXI note
            if (_selectedCarType == 'ev_taxi')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EvoColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EvoColors.warning.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: EvoColors.warning, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'EV TAXI يعمل بنظام العداد (نهاري/ليلي) — الأجرة تُحسب بالكيلومتر والوقت',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.warning),
                      ),
                    ),
                  ],
                ),
              ),

            // Optional: Battery + Range
            const SizedBox(height: 8),
            const Text(
              'اختياري',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.textOnDarkSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _batteryController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: EvoColors.textOnDark, fontFamily: 'Cairo'),
                    decoration: _inputDec('سعة البطارية (kWh)', Icons.battery_charging_full_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _rangeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: EvoColors.textOnDark, fontFamily: 'Cairo'),
                    decoration: _inputDec('المدى (كم)', Icons.speed_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_canProceed() && !isLoading) ? _onSubmit : null,
                child: isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text('إرسال الطلب ✓'),
              ),
            ),
          ],
        ),
      ),
    ),
            // ── Loading overlay ──────────────────────────────
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.45),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(EvoColors.primary),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'جاري رفع بياناتك...',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label, style: const TextStyle(
          fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: EvoColors.textOnDark,
        )),
      );

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: EvoColors.textOnDarkSecondary, fontFamily: 'Cairo'),
        prefixIcon: Icon(icon, color: EvoColors.textOnDarkSecondary, size: 20),
        filled: true, fillColor: EvoColors.darkCard,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: EvoColors.borderDark)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: EvoColors.primary, width: 2)),
      );

  bool _canProceed() =>
      _carModelController.text.trim().isNotEmpty &&
      _carPlateController.text.trim().isNotEmpty &&
      _selectedCarType != null;

  void _onSubmit() {
    context.read<RegistrationBloc>().add(RegistrationStep4Submitted(
      carType: _selectedCarType!,
      carModel: _carModelController.text.trim(),
      carPlate: _carPlateController.text.trim().toUpperCase(),
      batteryCapacity: _batteryController.text.trim().isEmpty
          ? null
          : _batteryController.text.trim(),
      rangeKm: _rangeController.text.trim().isEmpty
          ? null
          : _rangeController.text.trim(),
    ));
    context.read<RegistrationBloc>().add(const RegistrationSubmitFinalEvent());
  }

  @override
  void dispose() {
    _carModelController.dispose();
    _carPlateController.dispose();
    _batteryController.dispose();
    _rangeController.dispose();
    super.dispose();
  }
}

/// ════════════════════════════════════════
/// STEP 5: Confirmation / Pending Status
/// ════════════════════════════════════════
class DriverStep5Screen extends StatefulWidget {
  final Map<String, dynamic> stepData;
  const DriverStep5Screen({super.key, required this.stepData});

  @override
  State<DriverStep5Screen> createState() => _DriverStep5ScreenState();
}

class _DriverStep5ScreenState extends State<DriverStep5Screen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _checkController;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _submitApplication();
  }

  Future<void> _submitApplication() async {
    setState(() => _isSubmitting = true);
    // TODO: Submit via BLoC/API
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });
    _checkController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvoColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const _RegistrationProgress(currentStep: 5, totalSteps: 5),
              const Spacer(),

              // Icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: EvoColors.primary.withOpacity(
                        _isSubmitted ? 0.15 : 0.08 + (_pulseController.value * 0.07),
                      ),
                      border: Border.all(
                        color: EvoColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isSubmitted ? Icons.check_circle : Icons.hourglass_top_rounded,
                      color: EvoColors.primary,
                      size: 56,
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              Text(
                _isSubmitting
                    ? 'جاري إرسال طلبك...'
                    : 'تم إرسال طلبك بنجاح! 🎉',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: EvoColors.textOnDark,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              if (_isSubmitted) ...[
                const Text(
                  'سيتم مراجعة طلبك من قِبَل فريق EVO خلال 24-48 ساعة.\nستصلك إشعار عند اتخاذ القرار.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    color: EvoColors.textOnDarkSecondary,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: EvoColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: EvoColors.warning.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, color: EvoColors.warning, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '⏳ قيد المراجعة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: EvoColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Info Cards
                _buildInfoCard(
                  icon: Icons.notifications_outlined,
                  title: 'إشعار فوري',
                  desc: 'ستصلك رسالة عند القبول أو الرفض',
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'محفظة كليك',
                  desc: 'ستُفعَّل محفظتك عند قبول طلبك',
                ),
              ],

              const Spacer(),

              if (_isSubmitted)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/driver-home'),
                    child: const Text('تابع الطلب من الشاشة الرئيسية'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EvoColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvoColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: EvoColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: EvoColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: EvoColors.textOnDark)),
                Text(desc, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.textOnDarkSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }
}

/// ════════════════════════════════════════
/// APPROVAL STATUS SCREEN
/// Shows while driver waits for approval
/// ════════════════════════════════════════
class DriverApprovalStatusScreen extends StatelessWidget {
  final String status; // 'pending' | 'approved' | 'rejected' | 'more_info_needed'
  final String? notes;

  const DriverApprovalStatusScreen({
    super.key,
    required this.status,
    this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Scaffold(
      backgroundColor: EvoColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (config['color'] as Color).withOpacity(0.12),
                  border: Border.all(color: (config['color'] as Color).withOpacity(0.3), width: 2),
                ),
                child: Icon(config['icon'] as IconData, color: config['color'] as Color, size: 56),
              ),
              const SizedBox(height: 32),
              Text(
                config['title'] as String,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w800, color: EvoColors.textOnDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                config['message'] as String,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, color: EvoColors.textOnDarkSecondary, height: 1.7),
                textAlign: TextAlign.center,
              ),
              if (notes != null && notes!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EvoColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EvoColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ملاحظة الإدارة:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: EvoColors.textOnDark)),
                      const SizedBox(height: 6),
                      Text(notes!, style: const TextStyle(fontFamily: 'Cairo', color: EvoColors.textOnDarkSecondary)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              if (status == 'more_info_needed')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/driver-register/step-1'),
                    child: const Text('إعادة إرسال المستندات'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'approved':
        return {
          'icon': Icons.check_circle,
          'color': EvoColors.success,
          'title': 'تم قبول طلبك! 🎉',
          'message': 'مرحباً بك في EVO! يمكنك الآن البدء باستقبال الطلبات.',
        };
      case 'rejected':
        return {
          'icon': Icons.cancel,
          'color': EvoColors.error,
          'title': 'تم رفض طلبك',
          'message': 'نأسف، لم نتمكن من قبول طلبك. يمكنك التواصل مع الدعم لمزيد من المعلومات.',
        };
      case 'more_info_needed':
        return {
          'icon': Icons.info_outline,
          'color': EvoColors.warning,
          'title': 'نحتاج معلومات إضافية',
          'message': 'يرجى مراجعة الملاحظة أدناه وإعادة إرسال المستندات المطلوبة.',
        };
      default: // pending
        return {
          'icon': Icons.hourglass_top_rounded,
          'color': EvoColors.warning,
          'title': 'طلبك قيد المراجعة',
          'message': 'سيتم مراجعة طلبك خلال 24-48 ساعة. سنرسل لك إشعاراً فور اتخاذ القرار.',
        };
    }
  }
}

