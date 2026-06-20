import 'package:flutter/material.dart';

import 'package:evo_driver/core/constants/evo_colors.dart';

// ══════════════════════════════════════════════════════════════════
// DRIVER WALLET SCREEN — Prepaid System
// - Shows current balance (recharged by admin, linked to car plate)
// - Transaction history: admin_recharge (+) and commission_deduction (-)
// - Low balance warning
// - ❌ NO vouchers / scratch cards
// - ❌ NO bank withdrawal
// ══════════════════════════════════════════════════════════════════

class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  // Mock data — replaced by BLoC
  final double _balance = 12.50;
  final String _carPlate = '87-12345';
  final String _cliqAlias = '0791234567';
  final int _todayRides = 7;
  final double _todayCommission = 2.34;

  final List<Map<String, dynamic>> _transactions = [
    {
      'type': 'admin_recharge',
      'amount': 20.00,
      'balance_after': 32.50,
      'description_ar': 'شحن رصيد من الإدارة',
      'recharged_by': 'أدمن النظام',
      'created_at': '2026-06-12T09:00:00',
    },
    {
      'type': 'commission_deduction',
      'amount': 0.43,
      'balance_after': 12.07,
      'description_ar': 'عمولة رحلة #1042',
      'ride_pickup': 'عبدالي',
      'ride_dropoff': 'الجامعة الأردنية',
      'created_at': '2026-06-12T14:30:00',
    },
    {
      'type': 'commission_deduction',
      'amount': 0.26,
      'balance_after': 11.81,
      'description_ar': 'عمولة رحلة #1041',
      'created_at': '2026-06-12T12:15:00',
    },
    {
      'type': 'admin_recharge',
      'amount': 15.00,
      'balance_after': 35.00,
      'description_ar': 'شحن رصيد من الإدارة',
      'recharged_by': 'أدمن النظام',
      'created_at': '2026-06-10T10:00:00',
    },
    {
      'type': 'commission_deduction',
      'amount': 0.38,
      'balance_after': 20.00,
      'description_ar': 'عمولة رحلة #1039',
      'created_at': '2026-06-10T16:45:00',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvoColors.darkBg,
      appBar: AppBar(
        title: const Text('محفظتي'),
        backgroundColor: EvoColors.darkBg,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: EvoColors.textOnDarkSecondary),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Balance Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildBalanceCard(),
            ),
          ),

          // Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStatsRow(),
            ),
          ),

          // How it works info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildHowItWorksCard(),
            ),
          ),

          // Transactions Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'سجل المعاملات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: EvoColors.textOnDark,
                ),
              ),
            ),
          ),

          // Transaction List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTransactionTile(_transactions[index]),
                childCount: _transactions.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isLow = _balance < 3.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLow
              ? [EvoColors.warning.withOpacity(0.1), EvoColors.warning.withOpacity(0.05)]
              : [EvoColors.primary.withOpacity(0.12), EvoColors.primaryDark.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLow ? EvoColors.warning.withOpacity(0.5) : EvoColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: EvoColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'الرصيد المتبقي',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: EvoColors.textOnDarkSecondary),
              ),
              const Spacer(),
              if (isLow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: EvoColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '⚠️ رصيد منخفض',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: EvoColors.warning, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _balance.toStringAsFixed(2),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: isLow ? EvoColors.warning : EvoColors.primary,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 6),
                child: Text('د.أ', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: EvoColors.textOnDarkSecondary)),
              ),
            ],
          ),
          const Divider(color: EvoColors.borderDark, height: 24),
          Row(
            children: [
              const Icon(Icons.directions_car_outlined, color: EvoColors.textOnDarkSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                'مربوطة بسيارة: $_carPlate',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.textOnDarkSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.account_balance_outlined, color: EvoColors.textOnDarkSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                'CliQ: $_cliqAlias',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.textOnDarkSecondary),
              ),
            ],
          ),
          if (isLow) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EvoColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.phone_outlined, color: EvoColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تواصل مع الإدارة لشحن رصيدك: ادفع للشركة → الأدمن يشحن محفظتك',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: EvoColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatChip(
          label: 'رحلات اليوم',
          value: '$_todayRides رحلة',
          icon: Icons.directions_car_outlined,
          color: EvoColors.primary,
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          label: 'عمولة اليوم',
          value: '${_todayCommission.toStringAsFixed(2)} د.أ',
          icon: Icons.trending_down_outlined,
          color: EvoColors.payoutRed,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: EvoColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EvoColors.borderDark),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: EvoColors.textOnDarkSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EvoColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EvoColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: EvoColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'كيف يعمل النظام؟',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: EvoColors.textOnDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoStep('1', 'أنت تستلم الأجرة كاشاً (أو كليك) من الزبون مباشرة'),
          _buildInfoStep('2', 'عمولة 13% تُخصم من رصيدك المسبق بعد كل رحلة'),
          _buildInfoStep('3', 'لشحن الرصيد: حوّل للشركة → الأدمن يشحن محفظتك'),
          _buildInfoStep('4', 'رصيد منخفض = لا طلبات تصلك (الحد الأدنى 3 د.أ)'),
        ],
      ),
    );
  }

  Widget _buildInfoStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: EvoColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: EvoColors.primary)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: EvoColors.textOnDarkSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final isRecharge = tx['type'] == 'admin_recharge';
    final amount = (tx['amount'] as double).toStringAsFixed(2);
    final balanceAfter = (tx['balance_after'] as double).toStringAsFixed(2);

    final dateStr = tx['created_at'] as String;
    final date = DateTime.tryParse(dateStr);
    final dateLabel = date != null
        ? '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EvoColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EvoColors.borderDark),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isRecharge
                  ? EvoColors.primary.withOpacity(0.12)
                  : EvoColors.payoutRed.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRecharge ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isRecharge ? EvoColors.primary : EvoColors.payoutRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description_ar'] as String,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: EvoColors.textOnDark),
                ),
                if (isRecharge && tx['recharged_by'] != null)
                  Text(
                    'بواسطة: ${tx['recharged_by']}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: EvoColors.textOnDarkSecondary),
                  ),
                if (!isRecharge && tx['ride_pickup'] != null)
                  Text(
                    '${tx['ride_pickup']} → ${tx['ride_dropoff']}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: EvoColors.textOnDarkSecondary),
                  ),
                Text(dateLabel, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: EvoColors.textOnDarkSecondary)),
              ],
            ),
          ),

          // Amount + Balance After
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isRecharge ? '+' : '-'} $amount د.أ',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isRecharge ? EvoColors.primary : EvoColors.payoutRed,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'الرصيد: $balanceAfter',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: EvoColors.textOnDarkSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: EvoColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('عن المحفظة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: EvoColors.textOnDark)),
        content: const Text(
          'محفظتك مسبقة الدفع ومربوطة برقم سيارتك. الإدارة تشحن رصيدك بعد أن تحوّل لهم.\n\nالعمولة 13% تُخصم تلقائياً بعد كل رحلة.',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: EvoColors.textOnDarkSecondary, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('فهمت', style: TextStyle(fontFamily: 'Cairo', color: EvoColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

