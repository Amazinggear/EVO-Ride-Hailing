// lib/features/passenger/profile/presentation/screens/passenger_profile_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
// EVO Passenger — Profile Screen
// Shows user info, wallet balance, settings, and logout
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evo_passenger/core/constants/evo_colors.dart';
import 'package:evo_passenger/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:evo_passenger/features/auth/presentation/bloc/auth_event.dart';

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  // In production, fetch from bloc/repo
  String _name = 'مستخدم EVO';
  String _phone = '+962 79 123 4567';
  double _walletBalance = 0.0;
  bool _notificationsEnabled = true;
  bool _arabicLanguage = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // TODO: load from UserRepository
    // For now use placeholder data
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تعديل الاسم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Cairo'),
          decoration: InputDecoration(
            hintText: 'اسمك',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EvoColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: EvoColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              setState(() => _name = controller.text.trim().isNotEmpty ? controller.text.trim() : _name);
              Navigator.pop(ctx);
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        content: const Text('هل أنت متأكد أنك تريد الخروج؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: EvoColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EvoColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(SignOutEvent());
            },
            child: const Text('خروج', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvoColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('حسابي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: EvoColors.textPrimary)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: EvoColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Avatar + Name ──────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [EvoColors.primary, Color(0xFF00897B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [BoxShadow(color: EvoColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Center(
                          child: Text(
                            _name.isNotEmpty ? _name[0] : 'م',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showEditNameDialog,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: EvoColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit, size: 11, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(_name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: EvoColors.textPrimary)),
                            ),
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: EvoColors.textHint), onPressed: _showEditNameDialog, constraints: const BoxConstraints(), padding: EdgeInsets.zero),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_phone, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: EvoColors.textSecondary), textDirection: TextDirection.ltr),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: EvoColors.primarySubtle, borderRadius: BorderRadius.circular(10)),
                          child: const Text('راكب', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: EvoColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Wallet Card ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [EvoColors.primary, Color(0xFF00897B)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: EvoColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('رصيد المحفظة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(
                            '${_walletBalance.toStringAsFixed(2)} د.أ',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          const Text('دفع نقدي — لا رسوم مسبقة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white60)),
                        ],
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Quick Actions ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _QuickAction(icon: Icons.history_rounded, label: 'الرحلات السابقة', color: EvoColors.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _PlaceholderScreen(title: 'الرحلات السابقة'))))),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(icon: Icons.star_rate_rounded, label: 'تقييماتي', color: const Color(0xFFFFC107), onTap: () {})),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(icon: Icons.confirmation_number_outlined, label: 'أكوادي', color: const Color(0xFF7C3AED), onTap: () {})),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Settings Section ───────────────────────────────────────────
            _SectionHeader(title: 'الإعدادات'),
            _SettingsCard(
              children: [
                _SettingsToggle(
                  icon: Icons.notifications_outlined,
                  label: 'الإشعارات',
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                ),
                const Divider(height: 1, color: EvoColors.border),
                _SettingsToggle(
                  icon: Icons.language_outlined,
                  label: 'اللغة العربية',
                  value: _arabicLanguage,
                  onChanged: (v) => setState(() => _arabicLanguage = v),
                ),
              ],
            ),

            const SizedBox(height: 8),
            _SectionHeader(title: 'الحساب'),
            _SettingsCard(
              children: [
                _SettingsTile(icon: Icons.privacy_tip_outlined, label: 'سياسة الخصوصية', onTap: () {}),
                const Divider(height: 1, color: EvoColors.border),
                _SettingsTile(icon: Icons.help_outline_rounded, label: 'الدعم والمساعدة', onTap: () {}),
                const Divider(height: 1, color: EvoColors.border),
                _SettingsTile(icon: Icons.info_outline_rounded, label: 'عن التطبيق — v1.0.0', onTap: () {}),
              ],
            ),

            const SizedBox(height: 8),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EvoColors.error,
                    side: const BorderSide(color: EvoColors.error, width: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15)),
                  onPressed: _handleLogout,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ──────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: EvoColors.cardShadow),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700, color: EvoColors.textHint, letterSpacing: 0.5)),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: EvoColors.cardShadow),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: EvoColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600))),
          Switch(activeColor: EvoColors.primary, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: EvoColors.textSecondary),
      title: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: EvoColors.textHint),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700))),
      body: Center(child: Text('$title — قريباً', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16))),
    );
  }
}
