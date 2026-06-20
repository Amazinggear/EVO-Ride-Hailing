// lib/features/passenger/ride_booking/presentation/bloc/booking_state.dart
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';


abstract class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object?> get props => [];
}

class BookingInitialState extends BookingState {}

class BookingSelectingLocationState extends BookingState {}

class BookingEstimatingState extends BookingState {}

class BookingReadyState extends BookingState {
  final LatLng pickup;
  final LatLng dropoff;
  final String pickupAddress;
  final String dropoffAddress;
  final String selectedCarType;
  final String? tariffType; // day or night for EV_TAXI
  final double estimatedFare;
  final double distanceKm;
  final double co2Saved;

  const BookingReadyState({
    required this.pickup,
    required this.dropoff,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.selectedCarType,
    this.tariffType,
    required this.estimatedFare,
    required this.distanceKm,
    required this.co2Saved,
  });

  @override
  List<Object?> get props => [
    pickup, dropoff, pickupAddress, dropoffAddress, 
    selectedCarType, tariffType, estimatedFare, distanceKm, co2Saved
  ];
}

class BookingRequestingState extends BookingState {}

class RideMatchedState extends BookingState {
  final Map<String, dynamic> rideData;
  const RideMatchedState(this.rideData);
  @override
  List<Object?> get props => [rideData];
}

class BookingErrorState extends BookingState {
  final String message;
  const BookingErrorState(this.message);
  @override
  List<Object?> get props => [message];
}
