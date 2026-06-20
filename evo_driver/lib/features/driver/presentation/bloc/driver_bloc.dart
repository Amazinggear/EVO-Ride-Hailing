// lib/features/driver/bloc/driver_bloc.dart
// ══════════════════════════════════════════════════════════
// EVO Driver — DriverBloc
//
// Manages:
//   1. Online/Offline toggle (via Socket.io → backend Redis)
//   2. GPS location broadcasting every 5s (idle) / 3s (in-ride)
//   3. Incoming ride request handling (15s timer)
//   4. Ride lifecycle: accept → arriving → arrived → in_progress → completed
//   5. Wallet balance polling
// ══════════════════════════════════════════════════════════

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ─────────────────────────────────────────────────────────
// EVENTS
// ─────────────────────────────────────────────────────────
abstract class DriverEvent extends Equatable {
  const DriverEvent();
  @override
  List<Object?> get props => [];
}

class DriverInitializeEvent extends DriverEvent {
  final String jwt;
  const DriverInitializeEvent({required this.jwt});
  @override
  List<Object?> get props => [jwt];
}

class DriverGoOnlineEvent extends DriverEvent {
  final String carType;
  const DriverGoOnlineEvent({required this.carType});
  @override
  List<Object?> get props => [carType];
}

class DriverGoOfflineEvent extends DriverEvent {}

class DriverLocationUpdatedEvent extends DriverEvent {
  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  const DriverLocationUpdatedEvent({
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
  });
  @override
  List<Object?> get props => [lat, lng, heading, speed];
}

class RideRequestReceivedEvent extends DriverEvent {
  final Map<String, dynamic> rideData;
  const RideRequestReceivedEvent({required this.rideData});
  @override
  List<Object?> get props => [rideData];
}

class RideRequestTimeoutEvent extends DriverEvent {}

class AcceptRideEvent extends DriverEvent {
  final String rideId;
  const AcceptRideEvent({required this.rideId});
  @override
  List<Object?> get props => [rideId];
}

class DeclineRideEvent extends DriverEvent {
  final String rideId;
  const DeclineRideEvent({required this.rideId});
  @override
  List<Object?> get props => [rideId];
}

class MarkArrivedEvent extends DriverEvent {
  final String rideId;
  const MarkArrivedEvent({required this.rideId});
  @override
  List<Object?> get props => [rideId];
}

class StartRideEvent extends DriverEvent {
  final String rideId;
  const StartRideEvent({required this.rideId});
  @override
  List<Object?> get props => [rideId];
}

class CompleteRideEvent extends DriverEvent {
  final String rideId;
  const CompleteRideEvent({required this.rideId});
  @override
  List<Object?> get props => [rideId];
}

class WalletRefreshEvent extends DriverEvent {}

class DriverDisconnectEvent extends DriverEvent {}

// ─────────────────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────────────────
abstract class DriverState extends Equatable {
  const DriverState();
  @override
  List<Object?> get props => [];
}

class DriverInitialState extends DriverState {}

class DriverOfflineState extends DriverState {
  final double walletBalance;
  final String carType;
  const DriverOfflineState({required this.walletBalance, required this.carType});
  @override
  List<Object?> get props => [walletBalance, carType];
}

class DriverOnlineState extends DriverState {
  final double walletBalance;
  final String carType;
  final double? currentLat;
  final double? currentLng;
  const DriverOnlineState({
    required this.walletBalance,
    required this.carType,
    this.currentLat,
    this.currentLng,
  });
  @override
  List<Object?> get props => [walletBalance, carType, currentLat, currentLng];
}

class IncomingRideState extends DriverState {
  final Map<String, dynamic> rideData;
  final int secondsLeft;
  const IncomingRideState({required this.rideData, required this.secondsLeft});
  @override
  List<Object?> get props => [rideData, secondsLeft];
}

class RideAcceptedState extends DriverState {
  final String rideId;
  final String status; // arriving | arrived | in_progress | completed
  final Map<String, dynamic> rideData;
  const RideAcceptedState({
    required this.rideId,
    required this.status,
    required this.rideData,
  });
  @override
  List<Object?> get props => [rideId, status];
}

class RideCompletedState extends DriverState {
  final double totalFare;
  final double commission;
  final double newWalletBalance;
  const RideCompletedState({
    required this.totalFare,
    required this.commission,
    required this.newWalletBalance,
  });
  @override
  List<Object?> get props => [totalFare, commission, newWalletBalance];
}

class DriverErrorState extends DriverState {
  final String message;
  const DriverErrorState({required this.message});
  @override
  List<Object?> get props => [message];
}

class LowBalanceState extends DriverState {
  final double balance;
  const LowBalanceState({required this.balance});
  @override
  List<Object?> get props => [balance];
}

// ─────────────────────────────────────────────────────────
// BLOC
// ─────────────────────────────────────────────────────────
class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final Dio _dio;
  final String _socketUrl;

  IO.Socket? _socket;
  Timer? _locationTimer;
  Timer? _rideRequestTimer;
  StreamSubscription<Position>? _positionSubscription;

  double _walletBalance = 0.0;
  String _carType = 'ev_mini';
  String? _activeRideId;
  bool _isOnline = false;

  static const double _lowBalanceThreshold = 3.0;
  static const int _rideRequestTimeoutSecs = 15;

  DriverBloc({required Dio dio, required String socketUrl})
      : _dio = dio,
        _socketUrl = socketUrl,
        super(DriverInitialState()) {
    on<DriverInitializeEvent>(_onInitialize);
    on<DriverGoOnlineEvent>(_onGoOnline);
    on<DriverGoOfflineEvent>(_onGoOffline);
    on<DriverLocationUpdatedEvent>(_onLocationUpdated);
    on<RideRequestReceivedEvent>(_onRideRequestReceived);
    on<RideRequestTimeoutEvent>(_onRideRequestTimeout);
    on<AcceptRideEvent>(_onAcceptRide);
    on<DeclineRideEvent>(_onDeclineRide);
    on<MarkArrivedEvent>(_onMarkArrived);
    on<StartRideEvent>(_onStartRide);
    on<CompleteRideEvent>(_onCompleteRide);
    on<WalletRefreshEvent>(_onWalletRefresh);
    on<DriverDisconnectEvent>(_onDisconnect);
  }

  // ── Initialize: connect Socket.io + fetch wallet ────────────────
  Future<void> _onInitialize(
    DriverInitializeEvent event,
    Emitter<DriverState> emit,
  ) async {
    try {
      // Fetch wallet balance
      final walletResponse = await _dio.get('/api/v1/wallet/balance');
      _walletBalance = double.tryParse(
            walletResponse.data['walletBalance']?.toString() ?? '0',
          ) ?? 0.0;
      _carType = walletResponse.data['carType']?.toString() ?? 'ev_mini';

      // Connect Socket.io with JWT auth
      _socket = IO.io(
        _socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': event.jwt})
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket!.connect();

      // Listen for ride requests
      _socket!.on('ride:new-request', (data) {
        final rideData = Map<String, dynamic>.from(data as Map);
        add(RideRequestReceivedEvent(rideData: rideData));
      });

      // Listen for ride status changes
      _socket!.on('ride:status-changed', (data) {
        final payload = Map<String, dynamic>.from(data as Map);
        final status = payload['status']?.toString() ?? '';
        final rideId = payload['rideId']?.toString() ?? _activeRideId ?? '';
        if (_activeRideId != null && rideId == _activeRideId) {
          emit(RideAcceptedState(
            rideId: rideId,
            status: status,
            rideData: payload,
          ));
        }
      });

      _socket!.on('connect', (_) {
        // Re-emit online status if was online before reconnect
      });

      if (_walletBalance < _lowBalanceThreshold) {
        emit(LowBalanceState(balance: _walletBalance));
      } else {
        emit(DriverOfflineState(walletBalance: _walletBalance, carType: _carType));
      }
    } on DioException catch (e) {
      emit(DriverErrorState(
        message: e.response?.data?['error']?.toString() ?? 'خطأ في الاتصال بالخادم',
      ));
    } catch (e) {
      emit(DriverErrorState(message: 'خطأ غير متوقع: ${e.toString()}'));
    }
  }

  // ── Go Online ──────────────────────────────────────────────────
  Future<void> _onGoOnline(
    DriverGoOnlineEvent event,
    Emitter<DriverState> emit,
  ) async {
    if (_walletBalance < _lowBalanceThreshold) {
      emit(LowBalanceState(balance: _walletBalance));
      return;
    }

    _carType = event.carType;
    _isOnline = true;
    _socket?.emit('driver:go-online', {'carType': event.carType});

    // Start GPS location broadcasting
    _startLocationBroadcast();

    emit(DriverOnlineState(
      walletBalance: _walletBalance,
      carType: event.carType,
    ));
  }

  // ── Go Offline ─────────────────────────────────────────────────
  Future<void> _onGoOffline(
    DriverGoOfflineEvent event,
    Emitter<DriverState> emit,
  ) async {
    _isOnline = false;
    _socket?.emit('driver:go-offline');
    _stopLocationBroadcast();
    emit(DriverOfflineState(walletBalance: _walletBalance, carType: _carType));
  }

  // ── Location Update ────────────────────────────────────────────
  Future<void> _onLocationUpdated(
    DriverLocationUpdatedEvent event,
    Emitter<DriverState> emit,
  ) async {
    if (!_isOnline) return;

    _socket?.emit('driver:location-update', {
      'lat': event.lat,
      'lng': event.lng,
      'heading': event.heading ?? 0,
      'speed': event.speed ?? 0,
      if (_activeRideId != null) 'rideId': _activeRideId,
    });

    if (state is DriverOnlineState) {
      emit(DriverOnlineState(
        walletBalance: _walletBalance,
        carType: _carType,
        currentLat: event.lat,
        currentLng: event.lng,
      ));
    }
  }

  // ── Incoming Ride Request ───────────────────────────────────────
  Future<void> _onRideRequestReceived(
    RideRequestReceivedEvent event,
    Emitter<DriverState> emit,
  ) async {
    _rideRequestTimer?.cancel();

    // 15-second countdown
    int secondsLeft = _rideRequestTimeoutSecs;
    emit(IncomingRideState(rideData: event.rideData, secondsLeft: secondsLeft));

    _rideRequestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft--;
      if (secondsLeft <= 0) {
        timer.cancel();
        add(RideRequestTimeoutEvent());
      } else {
        add(RideRequestReceivedEvent(rideData: event.rideData));
      }
    });
  }

  Future<void> _onRideRequestTimeout(
    RideRequestTimeoutEvent event,
    Emitter<DriverState> emit,
  ) async {
    _rideRequestTimer?.cancel();
    emit(DriverOnlineState(
      walletBalance: _walletBalance,
      carType: _carType,
    ));
  }

  // ── Accept Ride ────────────────────────────────────────────────
  Future<void> _onAcceptRide(
    AcceptRideEvent event,
    Emitter<DriverState> emit,
  ) async {
    _rideRequestTimer?.cancel();
    try {
      final response = await _dio.patch('/api/v1/rides/${event.rideId}/accept');
      if (response.statusCode == 200) {
        _activeRideId = event.rideId;
        // Increase location update frequency to every 3s
        _stopLocationBroadcast();
        _startLocationBroadcast(intervalSeconds: 3);

        emit(RideAcceptedState(
          rideId: event.rideId,
          status: 'arriving',
          rideData: Map<String, dynamic>.from(response.data as Map? ?? {}),
        ));
      }
    } on DioException catch (e) {
      emit(DriverErrorState(
        message: e.response?.data?['error']?.toString() ?? 'فشل قبول الرحلة',
      ));
    }
  }

  // ── Decline Ride ───────────────────────────────────────────────
  Future<void> _onDeclineRide(
    DeclineRideEvent event,
    Emitter<DriverState> emit,
  ) async {
    _rideRequestTimer?.cancel();
    emit(DriverOnlineState(
      walletBalance: _walletBalance,
      carType: _carType,
    ));
  }

  // ── Mark Arrived ───────────────────────────────────────────────
  Future<void> _onMarkArrived(
    MarkArrivedEvent event,
    Emitter<DriverState> emit,
  ) async {
    try {
      await _dio.patch('/api/v1/rides/${event.rideId}/arrived');
      emit(RideAcceptedState(
        rideId: event.rideId,
        status: 'arrived',
        rideData: {'rideId': event.rideId},
      ));
    } on DioException catch (e) {
      emit(DriverErrorState(
        message: e.response?.data?['error']?.toString() ?? 'خطأ في تأكيد الوصول',
      ));
    }
  }

  // ── Start Ride ─────────────────────────────────────────────────
  Future<void> _onStartRide(
    StartRideEvent event,
    Emitter<DriverState> emit,
  ) async {
    try {
      await _dio.patch('/api/v1/rides/${event.rideId}/start');
      emit(RideAcceptedState(
        rideId: event.rideId,
        status: 'in_progress',
        rideData: {'rideId': event.rideId},
      ));
    } on DioException catch (e) {
      emit(DriverErrorState(
        message: e.response?.data?['error']?.toString() ?? 'خطأ في بدء الرحلة',
      ));
    }
  }

  // ── Complete Ride ──────────────────────────────────────────────
  Future<void> _onCompleteRide(
    CompleteRideEvent event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final response = await _dio.patch('/api/v1/rides/${event.rideId}/complete');
      final data = Map<String, dynamic>.from(response.data as Map? ?? {});

      final totalFare = double.tryParse(data['totalFare']?.toString() ?? '0') ?? 0.0;
      final commission = double.tryParse(data['commission']?.toString() ?? '0') ?? 0.0;
      final newBalance = double.tryParse(data['newWalletBalance']?.toString() ?? '0') ?? 0.0;

      _walletBalance = newBalance;
      _activeRideId = null;

      // Return to slower location update interval
      _stopLocationBroadcast();
      _startLocationBroadcast();

      emit(RideCompletedState(
        totalFare: totalFare,
        commission: commission,
        newWalletBalance: newBalance,
      ));
    } on DioException catch (e) {
      emit(DriverErrorState(
        message: e.response?.data?['error']?.toString() ?? 'خطأ في إنهاء الرحلة',
      ));
    }
  }

  // ── Wallet Refresh ─────────────────────────────────────────────
  Future<void> _onWalletRefresh(
    WalletRefreshEvent event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final response = await _dio.get('/api/v1/wallet/balance');
      _walletBalance = double.tryParse(
            response.data['walletBalance']?.toString() ?? '0',
          ) ?? 0.0;
      if (_walletBalance < _lowBalanceThreshold && _isOnline) {
        _isOnline = false;
        _socket?.emit('driver:go-offline');
        _stopLocationBroadcast();
        emit(LowBalanceState(balance: _walletBalance));
      }
    } catch (_) {
      // Silent fail for wallet refresh
    }
  }

  // ── Disconnect ─────────────────────────────────────────────────
  Future<void> _onDisconnect(
    DriverDisconnectEvent event,
    Emitter<DriverState> emit,
  ) async {
    _isOnline = false;
    _socket?.emit('driver:go-offline');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _stopLocationBroadcast();
    _rideRequestTimer?.cancel();
    emit(DriverInitialState());
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────
  void _startLocationBroadcast({int intervalSeconds = 5}) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) async {
        try {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            return;
          }

          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          add(DriverLocationUpdatedEvent(
            lat: position.latitude,
            lng: position.longitude,
            heading: position.heading,
            speed: position.speed,
          ));
        } catch (_) {
          // GPS unavailable — silent fail
        }
      },
    );
  }

  void _stopLocationBroadcast() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  @override
  Future<void> close() {
    _locationTimer?.cancel();
    _rideRequestTimer?.cancel();
    _positionSubscription?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    return super.close();
  }
}

