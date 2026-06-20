import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';


/// Anti-Jitter Smooth Driver Marker Animator
///
/// Instead of teleporting the driver marker (GPS jumps),
/// we smoothly animate it from old position to new position
/// over 4.5 seconds (just under the 5-second update interval).
///
/// This creates a continuous movement illusion — zero visible lag.
class DriverMarkerAnimator {
  AnimationController? _animationController;
  Animation<double>? _latAnimation;
  Animation<double>? _lngAnimation;

  void animateMarker({
    required TickerProvider vsync,
    required LatLng from,
    required LatLng to,
    required double heading,
    required void Function(LatLng position) onUpdate,
  }) {
    // Cancel any in-progress animation
    _animationController?.stop();
    _animationController?.dispose();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 4500), // Just under 5s update interval
      vsync: vsync,
    );

    final curve = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );

    _latAnimation = Tween<double>(
      begin: from.latitude,
      end: to.latitude,
    ).animate(curve);

    _lngAnimation = Tween<double>(
      begin: from.longitude,
      end: to.longitude,
    ).animate(curve);

    _animationController!.addListener(() {
      if (_latAnimation != null && _lngAnimation != null) {
        onUpdate(LatLng(
          _latAnimation!.value,
          _lngAnimation!.value,
        ));
      }
    });

    _animationController!.forward();
  }

  void dispose() {
    _animationController?.stop();
    _animationController?.dispose();
  }
}
