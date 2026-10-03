import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// 天气信息（Open-Meteo，免 API Key）
class WeatherInfo {
  final String desc; // 晴 / 多云 / 小雨…
  final IconData icon;
  final Color color;
  final double temp; // 当前气温
  final double? tempMin;
  final double? tempMax;
  const WeatherInfo({
    required this.desc,
    required this.icon,
    required this.color,
    required this.temp,
    this.tempMin,
    this.tempMax,
  });

  String get range => (tempMin != null && tempMax != null)
      ? '${tempMin!.round()}~${tempMax!.round()}°'
      : '';
}

class WeatherService {
  /// 内存缓存 30 分钟，避免频繁请求
  static WeatherInfo? _cache;
  static DateTime _cacheAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// WMO 天气代码 → 文案/图标/配色
  static (String, IconData, Color) _wmo(int code) {
    if (code == 0) return ('晴', Icons.wb_sunny, const Color(0xFFD9AE62));
    if (code <= 2) return ('多云', Icons.wb_cloudy, const Color(0xFF8FA3B8));
    if (code == 3) return ('阴', Icons.cloud, const Color(0xFF847C6D));
    if (code == 45 || code == 48) return ('雾', Icons.blur_on, Colors.grey);
    if (code >= 51 && code <= 57) return ('毛毛雨', Icons.opacity, Colors.blueGrey);
    if (code >= 61 && code <= 67) return ('雨', Icons.opacity, const Color(0xFF33506B));
    if (code >= 71 && code <= 77) return ('雪', Icons.ac_unit, Colors.lightBlue);
    if (code >= 80 && code <= 82) return ('阵雨', Icons.umbrella, Colors.blueGrey);
    if (code >= 95) return ('雷雨', Icons.flash_on, const Color(0xFFB03A2E));
    return ('多云', Icons.wb_cloudy, const Color(0xFF8FA3B8));
  }

  /// 取指定坐标的当日天气；失败返回 null（不抛异常，调用方静默降级）
  static Future<WeatherInfo?> fetch(double lat, double lng) async {
    final now = DateTime.now();
    if (_cache != null && now.difference(_cacheAt).inMinutes < 30) {
      return _cache;
    }
    try {
      final uri = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng'
          '&current=temperature_2m,weather_code'
          '&daily=temperature_2m_max,temperature_2m_min&forecast_days=1'
          '&timezone=auto');
      final resp = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(resp.bodyBytes));
      final cur = body['current'] as Map<String, dynamic>?;
      if (cur == null) return null;
      final (desc, icon, color) = _wmo((cur['weather_code'] as num?)?.toInt() ?? 2);
      final daily = body['daily'] as Map<String, dynamic>?;
      final max = (daily?['temperature_2m_max'] as List?)?.firstOrNull;
      final min = (daily?['temperature_2m_min'] as List?)?.firstOrNull;
      final info = WeatherInfo(
        desc: desc,
        icon: icon,
        color: color,
        temp: (cur['temperature_2m'] as num).toDouble(),
        tempMin: min is num ? min.toDouble() : null,
        tempMax: max is num ? max.toDouble() : null,
      );
      _cache = info;
      _cacheAt = now;
      return info;
    } catch (_) {
      return null;
    }
  }
}
