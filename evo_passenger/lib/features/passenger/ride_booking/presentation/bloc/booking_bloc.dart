// lib/features/passenger/ride_booking/presentation/bloc/booking_bloc.dart
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  // Local state storage
  String _selectedCarType = 'ev_mini'; // default 
  String _tariffType = 'day';
  
  double? _lastDistanceKm;
  double? _lastEstimatedFare;
  double? _lastCo2Saved;

  BookingBloc({required Dio dio, required FlutterSecureStorage storage})
      : _dio = dio,
        _storage = storage,
        super(BookingInitialState()) {
    on<UpdateLocationsEvent>(_onUpdateLocations);
    on<SelectCarTypeEvent>(_onSelectCarType);
    on<ToggleEvTaxiTypeEvent>(_onToggleEvTaxiType);
    on<EstimateFareEvent>(_onEstimateFare);
    on<RequestRideEvent>(_onRequestRide);
  }

  void _onUpdateLocations(UpdateLocationsEvent event, Emitter<BookingState> emit) {
    // Simple Haversine to calculate distance locally
    double haversine(double lat1, double lon1, double lat2, double lon2) {
      const p = 0.017453292519943295;
      final a = 0.5 - cos((lat2 - lat1) * p)/2 + 
                cos(lat1 * p) * cos(lat2 * p) * 
                (1 - cos((lon2 - lon1) * p))/2;
      return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
    }

    final distanceKm = haversine(
      event.pickup.latitude, event.pickup.longitude,
      event.dropoff.latitude, event.dropoff.longitude,
    );

    _lastDistanceKm = distanceKm;
    _lastCo2Saved = distanceKm * 0.21; // ~0.21kg CO2 saved per km

    add(EstimateFareEvent());

    emit(BookingReadyState(
      pickup: event.pickup,
      dropoff: event.dropoff,
      pickupAddress: event.pickupAddress,
      dropoffAddress: event.dropoffAddress,
      selectedCarType: _selectedCarType,
      tariffType: _selectedCarType == 'ev_taxi' ? _tariffType : null,
      estimatedFare: _lastEstimatedFare ?? 0.0,
      distanceKm: distanceKm,
      co2Saved: _lastCo2Saved ?? 0.0,
    ));
  }

  void _onSelectCarType(SelectCarTypeEvent event, Emitter<BookingState> emit) {
    _selectedCarType = event.carType;
    add(EstimateFareEvent());
  }

  void _onToggleEvTaxiType(ToggleEvTaxiTypeEvent event, Emitter<BookingState> emit) {
    _tariffType = event.tariffType;
    if (_selectedCarType == 'ev_taxi') {
      add(EstimateFareEvent());
    }
  }

  void _onEstimateFare(EstimateFareEvent event, Emitter<BookingState> emit) {
    if (_lastDistanceKm == null) return;

    // Simple client-side estimation mirroring backend defaults
    double base = 0.48;
    double perKm = 0.34;
    double minFare = 1.20;

    switch (_selectedCarType) {
      case 'ev_mini':
        base = 0.48; perKm = 0.34; minFare = 1.20; break;
      case 'ev_taxi':
        if (_tariffType == 'night') {
          base = 0.462; perKm = 0.389; minFare = 1.20;
        } else {
          base = 0.450; perKm = 0.316; minFare = 1.20;
        }
        break;
      case 'ev_sedan':
        base = 0.48; perKm = 0.34; minFare = 1.30; break;
      case 'ev_suv':
        base = 0.49; perKm = 0.35; minFare = 1.50; break;
      case 'ev_luxury':
        base = 0.50; perKm = 0.36; minFare = 1.75; break;
    }

    double fare = base + (_lastDistanceKm! * perKm);
    if (fare < minFare) fare = minFare;

    _lastEstimatedFare = double.parse(fare.toStringAsFixed(2));

    if (state is BookingReadyState) {
      final currentState = state as BookingReadyState;
      emit(BookingReadyState(
        pickup: currentState.pickup,
        dropoff: currentState.dropoff,
        pickupAddress: currentState.pickupAddress,
        dropoffAddress: currentState.dropoffAddress,
        selectedCarType: _selectedCarType,
        tariffType: _selectedCarType == 'ev_taxi' ? _tariffType : null,
        estimatedFare: _lastEstimatedFare!,
        distanceKm: _lastDistanceKm!,
        co2Saved: _lastCo2Saved!,
      ));
    }
  }

  Future<void> _onRequestRide(RequestRideEvent event, Emitter<BookingState> emit) async {
    if (state is! BookingReadyState) return;
    
    final currentState = state as BookingReadyState;
    emit(BookingRequestingState());

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await _dio.post(
        '/api/v1/rides',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {
          'pickup_address': currentState.pickupAddress,
          'dropoff_address': currentState.dropoffAddress,
          'pickup_lat': currentState.pickup.latitude,
          'pickup_lng': currentState.pickup.longitude,
          'dropoff_lat': currentState.dropoff.latitude,
          'dropoff_lng': currentState.dropoff.longitude,
          'car_type': _selectedCarType,
          'payment_method': 'cash',
        },
      );

      // Successfully requested
      emit(RideMatchedState(response.data));
    } on DioException catch (e) {
      emit(BookingErrorState(e.response?.data?['error'] ?? 'فشل طلب الرحلة. يرجى المحاولة مرة أخرى.'));
      // Return to ready state after error
      emit(currentState);
    } catch (e) {
      emit(const BookingErrorState('حدث خطأ غير متوقع.'));
      emit(currentState);
    }
  }
}
