// lib/features/driver/profile/presentation/screens/driver_profile_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
// EVO Driver — Profile Screen
// Shows driver info, wallet, car details, stats, and settings
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evo_driver/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:evo_driver/features/auth/presentation/bloc/auth_event.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  static const _kGreen = Color(0xFF00C853);
  static const _kDark = Color(0xFF212121);

  // Mock data — to be replaced by BLoC state
  final String _name = 'أحمد الخالدي';
  final String _phone = '+962 79 123 4567';
  final String _carType = 'EV Sedan';
  final String _carPlate = '12-34567';
  final String _carModel = 'Tesla Model 3';
  final String _carYear = '2023';
  final String _cliqAlias = 'ahmed.khaldi';
  final double _walletBalance = 18.50;
  final double _rating = 4.8;
  final int _totalRides = 142;
  final double _totalEarnings = 498.60;
  final bool _isApproved = true;

  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        content: const Text('هل تريد تسجيل الخروج؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF757575)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('الملف الشخصي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: _kDark)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: _kGreen),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Header ──────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  // Avatar + status badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [_kGreen, Color(0xFF00897B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Center(
                          child: Text(
                            _name.isNotEmpty ? _name[0] : 'ك',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      // Approval badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _isApproved ? _kGreen : const Color(0xFFFF8F00),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: Icon(_isApproved ? Icons.verified_rounded : Icons.hourglass_top_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(_name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w800, color: _kDark)),
                  const SizedBox(height: 4),
                  Text(_phone, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Color(0xFF757575)), textDirection: TextDirection.ltr),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isApproved ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isApproved ? _kGreen : const Color(0xFFFF8F00), width: 0.5),
                    ),
                    child: Text(
                      _isApproved ? '✅ كابتن معتمد' : '⏳ قيد المراجعة',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700, color: _isApproved ? _kGreen : const Color(0xFFFF8F00)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Stats Row ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatCard(value: '$_totalRides', label: 'رحلة', icon: '🚗'),
                  const SizedBox(width: 10),
                  _StatCard(value: _rating.toStringAsFixed(1), label: 'تقييم', icon: '⭐'),
                  const SizedBox(width: 10),
                  _StatCard(value: '${_totalEarnings.toStringAsFixed(0)} د.أ', label: 'أرباح', icon: '💰'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Wallet Card ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kGreen, Color(0xFF00897B)], begin: Alignment.topRight, end: Alignment.bottomLeft),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('رصيد المحفظة المسبقة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text('${_walletBalance.toStringAsFixed(2)} د.أ', style: const TextStyle(fontFamily: 'Cairo', fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 4),
                          const Text('حدّ أدنى 3 د.أ لقبول الرحلات', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white60)),
                        ],
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Car Info ──────────────────────────────────────────────────
            _SectionLabel('معلومات المركبة'),
            _InfoCard(
              children: [
                _InfoRow(icon: Icons.electric_car_outlined, label: 'نوع المركبة', value: _carType),
                const Divider(height: 1, color: Color(0xFFF5F5F5)),
                _InfoRow(icon: Icons.confirmation_number_outlined, label: 'رقم اللوحة', value: _carPlate),
                const Divider(height: 1, color: Color(0xFFF5F5F5)),
                _InfoRow(icon: Icons.directions_car_outlined, label: 'الموديل', value: _carModel),
                const Divider(height: 1, color: Color(0xFFF5F5F5)),
                _InfoRow(icon: Icons.calendar_today_outlined, label: 'سنة الصنع', value: _carYear),
              ],
            ),

            const SizedBox(height: 8),
            _SectionLabel('معلومات الدفع'),
            _InfoCard(
              children: [
                _InfoRow(icon: Icons.payment_outlined, label: 'رابط CliQ', value: _cliqAlias),
                const Divider(height: 1, color: Color(0xFFF5F5F5)),
                _InfoRow(icon: Icons.attach_money, label: 'نسبة العمولة', value: '13%'),
              ],
            ),

            // ── Settings ──────────────────────────────────────────────────
            const SizedBox(height: 8),
            _SectionLabel('الإعدادات'),
            _InfoCard(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_outlined, size: 20, color: Color(0xFF757575)),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('الإشعارات', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600))),
                      Switch(activeColor: _kGreen, value: _notificationsEnabled, onChanged: (v) => setState(() => _notificationsEnabled = v)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF5F5F5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_up_outlined, size: 20, color: Color(0xFF757575)),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('الأصوات', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600))),
                      Switch(activeColor: _kGreen, value: _soundEnabled, onChanged: (v) => setState(() => _soundEnabled = v)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            _InfoCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF757575), size: 20),
                  title: const Text('الدعم والمساعدة', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
                  dense: true,
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0xFFF5F5F5)),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF757575), size: 20),
                  title: const Text('عن التطبيق — v1.0.0', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
                  dense: true,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFE53935), width: 0.5),
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

// ── Helper widgets ───────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String icon;

  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
            Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(text, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9E9E9E), letterSpacing: 0.5)),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Color(0xFF757575))),
          const Spacer(),
          Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF212121))),
        ],
      ),
    );
  }
}
