import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';


import 'package:evo_passenger/core/constants/evo_colors.dart';

// ══════════════════════════════════════════════════════════════════
// SEARCH BAR WIDGET
// Floating search bar for passenger home screen.
// Navigates to PassengerSearchScreen and calls callbacks with results.
// ══════════════════════════════════════════════════════════════════

class SearchBarWidget extends StatelessWidget {
  final String hint;
  final LatLng? currentLocation;
  final Function(LatLng, String) onPickupSelected;
  final Function(LatLng, String) onDestinationSelected;

  const SearchBarWidget({
    super.key,
    required this.hint,
    this.currentLocation,
    required this.onPickupSelected,
    required this.onDestinationSelected,
  });

  Future<void> _openSearch(BuildContext context, bool isPickup) async {
    final result = await context.pushNamed<Map<String, dynamic>?>(
      'passenger-search',
      queryParameters: {'isPickup': isPickup.toString()},
    );

    if (result != null) {
      if (result.containsKey('lat') && result.containsKey('lng')) {
        final latLng = LatLng(result['lat'] as double, result['lng'] as double);
        final address = result['address'] as String;

        if (isPickup) {
          onPickupSelected(latLng, address);
        } else {
          onDestinationSelected(latLng, address);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _openSearch(context, false), // Default to dropoff search
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: EvoColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hint,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      color: EvoColors.textSecondary,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: EvoColors.border,
                ),
                const SizedBox(width: 12),
                // Button to change pickup location
                InkWell(
                  onTap: () => _openSearch(context, true),
                  child: const Row(
                    children: [
                      Icon(Icons.schedule, color: EvoColors.textSecondary, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'الآن',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: EvoColors.textSecondary, size: 20),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

