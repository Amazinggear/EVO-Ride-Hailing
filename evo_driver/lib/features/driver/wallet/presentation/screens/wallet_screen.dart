import 'package:flutter/material.dart';
import 'package:evo_driver/core/constants/evo_colors.dart';

/// Wallet & Payouts Screen — Driver
/// Matches Screen 5 reference design:
/// - Current balance (large)
/// - This week's earnings, commission paid
/// - Withdraw to Bank button
/// - Transaction list (earnings +, payouts -)

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // In production: fetched from API via BLoC
  final double _balance = 350.50;
  final double _weekEarned = 420.00;
  final double _commission = 69.50;

  final List<_Transaction> _transactions = [
    const _Transaction(
      description: 'رحلة إلى شارع البترا',
      descriptionEn: 'Ride to Petra St.',
      date: 'مايو 10، 2:30 م',
      amount: 12.00,
      isEarning: true,
    ),
    const _Transaction(
      description: 'سحب إلى بنك العرب',
      descriptionEn: 'Payout to Arab Bank',
      date: 'مايو 9، 9:00 ص',
      amount: 100.00,
      isEarning: false,
    ),
    const _Transaction(
      description: 'رحلة إلى وسط البلد',
      descriptionEn: 'Ride to Downtown Amman',
      date: 'مايو 8، 6:15 م',
      amount: 8.50,
      isEarning: true,
    ),
    const _Transaction(
      description: 'رحلة إلى مستشفى الجامعة',
      descriptionEn: 'Ride to University Hospital',
      date: 'مايو 7، 11:00 ص',
      amount: 15.75,
      isEarning: true,
    ),
    const _Transaction(
      description: 'سحب إلى البنك الأردني',
      descriptionEn: 'Payout to Jordan Bank',
      date: 'مايو 5، 10:00 ص',
      amount: 150.00,
      isEarning: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'المحفظة والمدفوعات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: EvoColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ──────────────────────────
            // Balance Card
            // ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: EvoColors.cardShadow,
              ),
              child: Column(
                children: [
                  const Text(
                    'الرصيد الحالي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: EvoColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JOD ${_balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: EvoColors.textPrimary,
                    ),
                  ),
                  const Divider(height: 24),

                  // This week's stats
                  Row(
                    children: [
                      Expanded(
                        child: _WeekStat(
                          label: 'أرباح الأسبوع',
                          value: 'JOD ${_weekEarned.toStringAsFixed(2)}',
                          color: EvoColors.primary,
                        ),
                      ),
                      Container(width: 1, height: 40, color: EvoColors.border),
                      Expanded(
                        child: _WeekStat(
                          label: 'العمولة المدفوعة',
                          value: 'JOD ${_commission.toStringAsFixed(2)}',
                          color: EvoColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ──────────────────────────
            // Withdraw Button
            // ──────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showWithdrawSheet,
                icon: const Icon(Icons.account_balance_rounded),
                label: const Text(
                  '🏦 سحب إلى الحساب البنكي',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ──────────────────────────
            // Transaction List
            // ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'سجل المعاملات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: EvoColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('الكل', style: TextStyle(fontFamily: 'Cairo', color: EvoColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...(_transactions.map((t) => _TransactionTile(transaction: t))),
          ],
        ),
      ),
    );
  }

  void _showWithdrawSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: EvoColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'طلب سحب',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'مبلغ السحب (JOD)',
                prefixIcon: Icon(Icons.attach_money_rounded, color: EvoColors.primary),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'رقم IBAN',
                prefixIcon: Icon(Icons.account_balance, color: EvoColors.primary),
                hintText: 'JO...',
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'اسم البنك',
                prefixIcon: Icon(Icons.business, color: EvoColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم إرسال طلب السحب. سيتم معالجته خلال 1-3 أيام عمل.',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: EvoColors.primary,
                    ),
                  );
                },
                child: const Text(
                  'تأكيد السحب',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _WeekStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: EvoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final _Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: transaction.isEarning
                  ? EvoColors.primarySubtle
                  : EvoColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.isEarning ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: transaction.isEarning ? EvoColors.primary : EvoColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  transaction.date,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: EvoColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.isEarning ? '+' : '-'} JOD ${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: transaction.isEarning ? EvoColors.earningGreen : EvoColors.payoutRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _Transaction {
  final String description;
  final String descriptionEn;
  final String date;
  final double amount;
  final bool isEarning;

  const _Transaction({
    required this.description,
    required this.descriptionEn,
    required this.date,
    required this.amount,
    required this.isEarning,
  });
}

