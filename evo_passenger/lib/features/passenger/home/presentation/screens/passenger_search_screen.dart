import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import 'package:evo_passenger/core/constants/evo_colors.dart';

// ══════════════════════════════════════════════════════════════════
// PASSENGER GOOGLE PLACES SEARCH SCREEN
// Auto-complete search using Google Places API (Restricted to Jordan)
// Returns selected LatLng & Address to Home Screen
// ══════════════════════════════════════════════════════════════════

class PassengerSearchScreen extends StatefulWidget {
  final bool isPickup;
  const PassengerSearchScreen({super.key, this.isPickup = false});

  @override
  State<PassengerSearchScreen> createState() => _PassengerSearchScreenState();
}

class _PassengerSearchScreenState extends State<PassengerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();
  
  // Replace with real Google Maps API Key
  final String _googleApiKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
  
  List<dynamic> _placesList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_searchController.text.length > 2) {
      _getPlaces(_searchController.text);
    } else {
      setState(() => _placesList = []);
    }
  }

  Future<void> _getPlaces(String input) async {
    if (_googleApiKey.isEmpty) {
      // Mock data if no API key is provided
      setState(() {
        _placesList = [
          {'description': 'العبدلي مول, عمان', 'place_id': 'mock1'},
          {'description': 'جامعة العلوم التطبيقية, شفا بدران', 'place_id': 'mock2'},
          {'description': 'مطار الملكة علياء الدولي', 'place_id': 'mock3'},
          {'description': 'سيتي مول, شارع الملك عبدالله الثاني', 'place_id': 'mock4'},
          {'description': 'تاج مول, عبدون', 'place_id': 'mock5'},
        ];
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&language=ar&components=country:jo';
      final response = await _dio.get(url);
      
      if (response.data['status'] == 'OK') {
        setState(() {
          _placesList = response.data['predictions'];
        });
      }
    } catch (e) {
      debugPrint('Places Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getPlaceDetails(String placeId, String description) async {
    if (_googleApiKey.isEmpty) {
      // Mock coordinates
      double lat = 31.9539;
      double lng = 35.9106;
      if (placeId == 'mock2') { lat = 32.0326; lng = 35.8821; }
      else if (placeId == 'mock3') { lat = 31.7226; lng = 35.9932; }

      context.pop({
        'address': description,
        'lat': lat,
        'lng': lng,
      });
      return;
    }

    try {
      final String url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey&language=ar';
      final response = await _dio.get(url);
      
      if (response.data['status'] == 'OK') {
        final location = response.data['result']['geometry']['location'];
        context.pop({
          'address': description,
          'lat': location['lat'],
          'lng': location['lng'],
        });
      }
    } catch (e) {
      debugPrint('Place Details Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isPickup ? 'أين موقعك؟' : 'إلى أين؟';
    
    return Scaffold(
      backgroundColor: EvoColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: EvoColors.darkCard,
                border: Border(bottom: BorderSide(color: EvoColors.borderDark)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: EvoColors.textOnDark),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: EvoColors.darkBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: EvoColors.primary.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.isPickup ? Icons.my_location : Icons.search,
                            color: EvoColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: EvoColors.textOnDark,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: title,
                                hintStyle: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: EvoColors.textOnDarkSecondary,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close, color: EvoColors.textOnDarkSecondary, size: 20),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Loading Indicator
            if (_isLoading)
              const LinearProgressIndicator(color: EvoColors.primary, backgroundColor: EvoColors.darkCard),
            
            // List of Places
            Expanded(
              child: ListView.separated(
                itemCount: _placesList.length,
                separatorBuilder: (context, index) => const Divider(color: EvoColors.borderDark, indent: 56),
                itemBuilder: (context, index) {
                  final place = _placesList[index];
                  final description = place['description'] as String;
                  final mainText = description.split(',').first;
                  final secondaryText = description.contains(',') 
                      ? description.substring(description.indexOf(',') + 1).trim() 
                      : '';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: EvoColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: EvoColors.primary, size: 20),
                    ),
                    title: Text(
                      mainText,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: EvoColors.textOnDark,
                      ),
                    ),
                    subtitle: secondaryText.isNotEmpty ? Text(
                      secondaryText,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: EvoColors.textOnDarkSecondary,
                      ),
                    ) : null,
                    onTap: () => _getPlaceDetails(place['place_id'], description),
                  );
                },
              ),
            ),
            
            // Default "Choose on Map" option
            if (_placesList.isEmpty && !_isLoading)
              InkWell(
                onTap: () {
                  // Logic to select on map
                  context.pop('choose_on_map');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: EvoColors.borderDark)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EvoColors.darkCard,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.map_outlined, color: EvoColors.textOnDarkSecondary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'تحديد الموقع على الخريطة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: EvoColors.textOnDark,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, color: EvoColors.textOnDarkSecondary, size: 14),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dio.close();
    super.dispose();
  }
}

