import 'package:flutter/material.dart';


import 'package:evo_passenger/core/constants/evo_colors.dart';
import 'package:evo_passenger/features/passenger/ride_booking/domain/models/ev_type_option.dart';
import 'co2_badge.dart';

/// EV Type Selector — Horizontal scroll with fare estimate
/// Based on Screen 1 reference design:
/// Card: image, CO₂ badge, price, ETA
class EvTypeSelector extends StatelessWidget {
  final String selectedType;
  final double distanceKm;
  final int durationMin;
  final void Function(String carType, double fare) onVehicleSelected;

  const EvTypeSelector({
    super.key,
    required this.selectedType,
    required this.distanceKm,
    required this.durationMin,
    required this.onVehicleSelected,
  });


  // EV options — 5 types per final blueprint (v3.2)
  // Base fares: MINI 0.48, TAXI metered, SEDAN 0.48, SUV 0.49, Luxury 0.50
  // Min fares:  MINI 1.20, TAXI 1.00, SEDAN 1.30, SUV 1.50, Luxury 1.75
  static const List<EvTypeOption> _evOptions = [
    EvTypeOption(
      type: 'ev_mini',
      nameAr: 'EV MINI',
      nameEn: 'EV MINI',
      defaultPrice: 1.20, // Min fare
      etaMin: 12,
      co2SavedKg: 1.0,
      imageAsset: 'assets/images/ev_mini.png',
    ),
    EvTypeOption(
      type: 'ev_taxi',
      nameAr: 'EV TAXI',
      nameEn: 'EV TAXI',
      defaultPrice: 1.00, // Metered — starts at 1.00 JOD min
      etaMin: 8,
      co2SavedKg: 1.0,
      imageAsset: 'assets/images/ev_taxi.png',
    ),
    EvTypeOption(
      type: 'ev_sedan',
      nameAr: 'EV SEDAN',
      nameEn: 'EV SEDAN',
      defaultPrice: 1.30,
      etaMin: 10,
      co2SavedKg: 1.2,
      imageAsset: 'assets/images/ev_sedan.png',
    ),
    EvTypeOption(
      type: 'ev_suv',
      nameAr: 'EV SUV',
      nameEn: 'EV SUV',
      defaultPrice: 1.50,
      etaMin: 14,
      co2SavedKg: 1.5,
      imageAsset: 'assets/images/ev_suv.png',
    ),
    EvTypeOption(
      type: 'ev_luxury',
      nameAr: 'EV Luxury',
      nameEn: 'EV Luxury',
      defaultPrice: 1.75,
      etaMin: 12,
      co2SavedKg: 2.0,
      imageAsset: 'assets/images/ev_luxury.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _evOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final opt = _evOptions[i];
          // Calculate actual fare from distance
          final calculatedFare = distanceKm > 0
              ? (distanceKm * opt.defaultPrice).clamp(opt.defaultPrice, 999.0)
              : opt.defaultPrice;
          return _EvTypeCard(
            option: opt,
            isSelected: selectedType == opt.type,
            fare: calculatedFare,
            durationMin: durationMin,
            onTap: () => onVehicleSelected(opt.type, calculatedFare),
          );
        },
      ),
    );
  }
}


class _EvTypeCard extends StatelessWidget {
  final EvTypeOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final double fare;
  final int durationMin;

  const _EvTypeCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.fare,
    required this.durationMin,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final name = isRtl ? option.nameAr : option.nameEn;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? EvoColors.primarySubtle : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? EvoColors.primary : EvoColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? EvoColors.cardShadow : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Car Image + CO₂ Badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  option.imageAsset,
                  width: 70,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.electric_car,
                    size: 40,
                    color: EvoColors.primary,
                  ),
                ),
                Co2Badge(kg: option.co2SavedKg),
              ],
            ),

            // Name + Price + ETA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? EvoColors.primaryDark : EvoColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      '${durationMin > 0 ? durationMin : option.etaMin} دقيقة',
                      style: const TextStyle(
                        fontSize: 11,
                        color: EvoColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                Text(
                  '${fare.toStringAsFixed(2)} JOD',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? EvoColors.primary : EvoColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}




