import 'package:flutter/material.dart';

import 'package:evo_driver/core/constants/evo_colors.dart';

// ══════════════════════════════════════════════════════════════════
// DRIVER APPROVAL STATUS SCREEN
// Shown after driver submits registration (Step 5)
// Displays: pending / under_review / approved / rejected / more_info
// Polls backend every 30s for status update
// Dark themed (driver app)
// ══════════════════════════════════════════════════════════════════

enum DriverApprovalStatus {
  pending,
  underReview,
  approved,
  rejected,
  moreInfoRequired,
}

class DriverApprovalStatusScreen extends StatefulWidget {
  const DriverApprovalStatusScreen({super.key});

  @override
  State<DriverApprovalStatusScreen> createState() => _DriverApprovalStatusScreenState();
}

class _DriverApprovalStatusScreenState extends State<DriverApprovalStatusScreen>
    with TickerProviderStateMixin {
  // TODO: Read from BLoC — mock for now
  final DriverApprovalStatus _status = DriverApprovalStatus.pending;
  String? _adminNote;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    // TODO: BLoC → poll registration status every 30s
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvoColors.darkBg,
      appBar: AppBar(
        backgroundColor: EvoColors.darkBg,
        title: const Text('حالة طلبك', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: EvoColors.textOnDark)),
        leading: _status == DriverApprovalStatus.rejected
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: EvoColors.textOnDark),
                onPressed: () => Navigator.pushReplacementNamed(context, '/phone-input'),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildStatusIcon(),
              const SizedBox(height: 24),
              _buildStatusTitle(),
              const SizedBox(height: 12),
              _buildStatusSubtitle(),
              if (_adminNote != null) ...[
                const SizedBox(height: 20),
                _buildAdminNote(),
              ],
              const SizedBox(height: 40),
              _buildActionButton(),
              const SizedBox(height: 24),
              _buildProcessSteps(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (_status) {
      case DriverApprovalStatus.pending:
      case DriverApprovalStatus.underReview:
        return AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) => Transform.rotate(
            angle: _rotateController.value * 2 * 3.14159,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: EvoColors.primary,
                  width: 3,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: const Icon(Icons.hourglass_empty_rounded, size: 48, color: EvoColors.primary),
            ),
          ),
        );

      case DriverApprovalStatus.approved:
        return Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: EvoColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: EvoColors.primary, width: 2),
          ),
          child: const Icon(Icons.check_circle_rounded, size: 60, color: EvoColors.primary),
        );

      case DriverApprovalStatus.rejected:
        return Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: EvoColors.error.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: EvoColors.error, width: 2),
          ),
          child: const Icon(Icons.cancel_rounded, size: 60, color: EvoColors.error),
        );

      case DriverApprovalStatus.moreInfoRequired:
        return Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: EvoColors.warning.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: EvoColors.warning, width: 2),
          ),
          child: const Icon(Icons.info_outline_rounded, size: 60, color: EvoColors.warning),
        );
    }
  }

  Widget _buildStatusTitle() {
    final (text, color) = switch (_status) {
      DriverApprovalStatus.pending => ('طلبك قيد الانتظار', EvoColors.textOnDark),
      DriverApprovalStatus.underReview => ('جاري مراجعة طلبك', EvoColors.primary),
      DriverApprovalStatus.approved => ('تهانينا! تمت الموافقة 🎉', EvoColors.primary),
      DriverApprovalStatus.rejected => ('تم رفض الطلب', EvoColors.error),
      DriverApprovalStatus.moreInfoRequired => ('مطلوب معلومات إضافية', EvoColors.warning),
    };

    return Text(
      text,
      style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w800, color: color),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatusSubtitle() {
    final text = switch (_status) {
      DriverApprovalStatus.pending =>
          'تم استلام طلبك بنجاح!\nسيتم مراجعته من قِبَل فريقنا خلال 24-48 ساعة. سيصلك إشعار فور اتخاذ القرار.',
      DriverApprovalStatus.underReview =>
          'يقوم فريقنا الآن بمراجعة وثائقك. هذا يستغرق عادةً 24 ساعة.',
      DriverApprovalStatus.approved =>
          'يمكنك الآن البدء باستقبال الرحلات!\nتأكد من شحن محفظتك مسبقاً للبدء.',
      DriverApprovalStatus.rejected =>
          'للأسف، لم تُوافَق على طلبك في الوقت الحالي. يمكنك إعادة التقديم بعد مراجعة الأسباب.',
      DriverApprovalStatus.moreInfoRequired =>
          'يحتاج فريقنا معلومات إضافية لإكمال مراجعة طلبك.',
    };

    return Text(
      text,
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: EvoColors.textOnDarkSecondary, height: 1.7),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAdminNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EvoColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvoColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.message_outlined, color: EvoColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ملاحظة الإدارة:', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: EvoColors.warning)),
                const SizedBox(height: 4),
                Text(_adminNote!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: EvoColors.textOnDarkSecondary, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    switch (_status) {
      case DriverApprovalStatus.approved:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/driver-home'),
            icon: const Icon(Icons.electric_car),
            label: const Text('ابدأ العمل الآن ⚡', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        );

      case DriverApprovalStatus.moreInfoRequired:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/driver-register/step-1'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('تحديث المعلومات', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: EvoColors.warning,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        );

      case DriverApprovalStatus.rejected:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/driver-register/step-1'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: const Text('إعادة التقديم', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {/* TODO: Contact support */},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: EvoColors.borderDark),
                  foregroundColor: EvoColors.textOnDarkSecondary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('التواصل مع الدعم', style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
              ),
            ),
          ],
        );

      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EvoColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EvoColors.borderDark),
          ),
          child: const Row(
            children: [
              Icon(Icons.notifications_outlined, color: EvoColors.primary, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'سيصلك إشعار فوري على هاتفك عند اتخاذ القرار',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: EvoColors.textOnDarkSecondary),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildProcessSteps() {
    final steps = [
      ('استلام الطلب', Icons.inbox_outlined, true),
      ('مراجعة الوثائق', Icons.document_scanner_outlined, _status != DriverApprovalStatus.pending),
      ('التحقق من السيارة', Icons.electric_car_outlined, _status == DriverApprovalStatus.approved),
      ('الموافقة النهائية', Icons.verified_outlined, _status == DriverApprovalStatus.approved),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('مراحل المراجعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: EvoColors.textOnDark)),
        const SizedBox(height: 12),
        ...steps.map((step) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: step.$3 ? EvoColors.primary.withOpacity(0.15) : EvoColors.darkCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: step.$3 ? EvoColors.primary : EvoColors.borderDark),
                ),
                child: Icon(step.$2, size: 18, color: step.$3 ? EvoColors.primary : EvoColors.textOnDarkSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                step.$1,
                style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 14,
                  color: step.$3 ? EvoColors.textOnDark : EvoColors.textOnDarkSecondary,
                  fontWeight: step.$3 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (step.$3)
                const Icon(Icons.check_circle, color: EvoColors.primary, size: 20),
            ],
          ),
        )),
      ],
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }
}

