import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Handles incoming geo: links and Google Maps share text from Android intents.
class LocationSharingService {
  static const _channel = MethodChannel('com.yakityonet/trip_intent');

  /// Call once on startup to get any location that launched the app.
  static Future<LatLng?> getInitialSharedLocation() async {
    try {
      final data =
          await _channel.invokeMethod<String>('getInitialIntentData');
      return _parse(data);
    } catch (_) {
      return null;
    }
  }

  /// Set a callback for locations received while the app is already running.
  static void listenForSharedLocations(void Function(LatLng) onLocation) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewIntentData') {
        final loc = _parse(call.arguments as String?);
        if (loc != null) onLocation(loc);
      }
    });
  }

  /// Parse a geo: URI or Google Maps URL into a [LatLng].
  static LatLng? _parse(String? data) {
    if (data == null || data.isEmpty) return null;

    // geo:lat,lng or geo:lat,lng?q=...
    if (data.startsWith('geo:')) {
      final coords = data.substring(4).split('?')[0].split(',');
      if (coords.length >= 2) {
        final lat = double.tryParse(coords[0]);
        final lng = double.tryParse(coords[1].split('&')[0]);
        if (lat != null && lng != null) return LatLng(lat, lng);
      }
    }

    // ?q=lat,lng or &q=lat,lng (Google Maps query param)
    final qMatch =
        RegExp(r'[?&]q=(-?\d+\.?\d*),(-?\d+\.?\d*)').firstMatch(data);
    if (qMatch != null) {
      return LatLng(
        double.parse(qMatch.group(1)!),
        double.parse(qMatch.group(2)!),
      );
    }

    // ?center=lat,lng
    final centerMatch =
        RegExp(r'center=(-?\d+\.?\d*),(-?\d+\.?\d*)').firstMatch(data);
    if (centerMatch != null) {
      return LatLng(
        double.parse(centerMatch.group(1)!),
        double.parse(centerMatch.group(2)!),
      );
    }

    // @lat,lng in URL path (Google Maps embed links)
    final atMatch =
        RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)').firstMatch(data);
    if (atMatch != null) {
      return LatLng(
        double.parse(atMatch.group(1)!),
        double.parse(atMatch.group(2)!),
      );
    }

    return null;
  }
}
