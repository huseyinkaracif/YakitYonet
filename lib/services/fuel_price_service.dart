import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FuelPrices {
  final double benzin;
  final double dizel;
  final double lpg;
  final double elektrik;
  final DateTime updatedAt;

  const FuelPrices({
    required this.benzin,
    required this.dizel,
    required this.lpg,
    required this.elektrik,
    required this.updatedAt,
  });

  factory FuelPrices.fromJson(Map<String, dynamic> json) {
    return FuelPrices(
      benzin: (json['benzin'] as num).toDouble(),
      dizel: (json['dizel'] as num).toDouble(),
      lpg: (json['lpg'] as num).toDouble(),
      elektrik: (json['elektrik'] as num?)?.toDouble() ?? 15.90,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'benzin': benzin,
        'dizel': dizel,
        'lpg': lpg,
        'elektrik': elektrik,
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Araç yakıt türüne göre litre/kWh fiyatı döner. Bilinmiyorsa null.
  double? priceFor(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'benzin':
        return benzin;
      case 'dizel':
        return dizel;
      case 'lpg':
        return lpg;
      case 'elektrik':
        return elektrik;
      default:
        return null;
    }
  }
}

class FuelPriceService {
  FuelPriceService._();
  static final FuelPriceService instance = FuelPriceService._();

  static const _cacheJsonKey = 'fuel_cache_json';
  static const _cacheTimestampKey = 'fuel_cache_timestamp';
  static const _cacheTtlHours = 6;

  /// Cache geçerliyse cache'den, değilse Supabase REST API'den çeker.
  /// Hata durumunda son başarılı cache'e fallback yapar.
  Future<FuelPrices?> getPrices() async {
    final cached = await _loadFromCache();
    if (cached != null) return cached;
    return _fetchFromApi();
  }

  /// Cache geçerlilik kontrolü: 6 saat içi VE aynı takvim günü
  Future<FuelPrices?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cacheJsonKey);
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (json == null || timestamp == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final elapsed = now.difference(cachedAt);
    final sameDay = cachedAt.year == now.year &&
        cachedAt.month == now.month &&
        cachedAt.day == now.day;

    if (!sameDay || elapsed.inHours >= _cacheTtlHours) return null;

    try {
      return FuelPrices.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<FuelPrices?> _fetchFromApi() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || anonKey == null) return null;

    try {
      final uri = Uri.parse(
        '$url/rest/v1/prices?select=*&order=date.desc&limit=1',
      );
      final response = await http.get(uri, headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return _fallbackFromCache();

      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isEmpty) return _fallbackFromCache();

      final prices = FuelPrices.fromJson(list[0] as Map<String, dynamic>);
      await _saveToCache(prices);
      return prices;
    } catch (_) {
      return _fallbackFromCache();
    }
  }

  /// İnternet yoksa veya hata varsa son başarılı cache'i döner (tarihe bakmadan).
  Future<FuelPrices?> _fallbackFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cacheJsonKey);
    if (json == null) return null;
    try {
      return FuelPrices.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(FuelPrices prices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheJsonKey, jsonEncode(prices.toJson()));
    await prefs.setInt(
        _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }
}
