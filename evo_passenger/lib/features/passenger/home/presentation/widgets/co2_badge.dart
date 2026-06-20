import 'package:flutter/material.dart';
import 'package:evo_passenger/core/constants/evo_colors.dart';

/// CO₂ Saved Badge
/// Green badge showing how much carbon is saved vs a petrol car
/// Based on reference design: "1.2 kg CO₂ Saved!" with leaf icon
class Co2Badge extends StatelessWidget {
  final double kg;

  const Co2Badge({super.key, required this.kg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: EvoColors.ecoBadgeBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EvoColors.ecoIcon.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.eco_rounded,
            size: 10,
            color: EvoColors.ecoIcon,
          ),
          const SizedBox(width: 2),
          Text(
            '${kg.toStringAsFixed(1)} كجم',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: EvoColors.ecoBadgeText,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

