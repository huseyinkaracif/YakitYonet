import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Handles incoming geo: links and Google Maps share text from Android intents.
class LocationSharingService {
  static const _channel = MethodChannel('com.yakityonet/trip_intent');

  /// Call once on startup to get any location that launched the app.
  static Future<LatLng?> getInitialSharedLocation() async {
    try {
      final data =
          await _channel.invokeMethod<String>('getInitialIntentData');
      return await _parse(data);
    } catch (_) {
      return null;
    }
  }

  /// Set a callback for locations received while the app is already running.
  static void listenForSharedLocations(void Function(LatLng) onLocation) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewIntentData') {
        final loc = await _parse(call.arguments as String?);
        if (loc != null) onLocation(loc);
      }
    });
  }

  /// Parse a geo: URI or Google Maps URL into a [LatLng].
  static Future<LatLng?> _parse(String? data) async {
    if (data == null || data.isEmpty) return null;

    final direct = _parseCoordinates(data);
    if (direct != null) return direct;

    // Kısa linkler (maps.app.goo.gl) koordinat içermez;
    // yönlendirmeyi çözüp son URL'den tekrar dene
    final shortLink = RegExp(r'https?://(?:maps\.app\.goo\.gl|goo\.gl)/\S+')
        .firstMatch(data)
        ?.group(0);
    if (shortLink != null) {
      final resolved = await _resolveRedirect(shortLink);
      if (resolved != null) return _parseCoordinates(resolved);
    }

    return null;
  }

  static LatLng? _parseCoordinates(String data) {
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

  /// Kısa linkin yönlendirmelerini takip edip son URL'i döner.
  /// Başarısızlık veya 3 sn aşımında null döner.
  static Future<String?> _resolveRedirect(String url) async {
    final client = http.Client();
    try {
      return await _followRedirects(client, Uri.parse(url))
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  static Future<String> _followRedirects(http.Client client, Uri start) async {
    var uri = start;
    for (var i = 0; i < 5; i++) {
      final request = http.Request('GET', uri)..followRedirects = false;
      final response = await client.send(request);
      final location = response.headers['location'];
      if (response.statusCode < 300 ||
          response.statusCode >= 400 ||
          location == null) {
        break;
      }
      uri = uri.resolve(location);
    }
    return uri.toString();
  }
}
