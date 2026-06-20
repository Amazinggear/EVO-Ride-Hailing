// lib/features/passenger/ride_booking/presentation/bloc/booking_event.dart
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';


abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

class UpdateLocationsEvent extends BookingEvent {
  final LatLng pickup;
  final LatLng dropoff;
  final String pickupAddress;
  final String dropoffAddress;

  const UpdateLocationsEvent({
    required this.pickup,
    required this.dropoff,
    required this.pickupAddress,
    required this.dropoffAddress,
  });

  @override
  List<Object?> get props => [pickup, dropoff, pickupAddress, dropoffAddress];
}

class SelectCarTypeEvent extends BookingEvent {
  final String carType;
  const SelectCarTypeEvent(this.carType);
  @override
  List<Object?> get props => [carType];
}

class ToggleEvTaxiTypeEvent extends BookingEvent {
  final String tariffType; // 'day' or 'night'
  const ToggleEvTaxiTypeEvent(this.tariffType);
  @override
  List<Object?> get props => [tariffType];
}

class EstimateFareEvent extends BookingEvent {}

class RequestRideEvent extends BookingEvent {
  final String paymentMethod;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String carType;
  final double estimatedFare;
  final String pickupAddress;
  final String dropoffAddress;

  const RequestRideEvent({
    this.paymentMethod = 'cash',
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.carType,
    required this.estimatedFare,
    required this.pickupAddress,
    required this.dropoffAddress,
  });

  @override
  List<Object?> get props => [
    paymentMethod, pickupLat, pickupLng, dropoffLat, dropoffLng,
    carType, estimatedFare, pickupAddress, dropoffAddress
  ];
}


class CancelRideEvent extends BookingEvent {
  final String rideId;
  const CancelRideEvent(this.rideId);
  @override
  List<Object?> get props => [rideId];
}
