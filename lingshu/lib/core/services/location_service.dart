import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// 定位与地址建议
class LocationResult {
  final double lat;
  final double lng;
  final String label; // 逆地理简述
  final List<String> suggestions; // 附近可能地点（医院等）

  LocationResult({
    required this.lat,
    required this.lng,
    required this.label,
    required this.suggestions,
  });
}

class LocationService {
  Future<bool> ensurePermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  /// 获取位置。
  /// [fresh]=false 时优先返回最后已知位置（瞬时、不注册 GNSS 回调，
  /// 避免 geolocator 在主线程同步注销回调时的 Binder 阻塞 ANR）；
  /// [fresh]=true 走实时定位，带 15s 超时。
  Future<LocationResult?> locate({bool fresh = false}) async {
    if (!await ensurePermission()) return null;
    try {
      Position? pos;
      if (!fresh) {
        pos = await Geolocator.getLastKnownPosition();
      }
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return await reverseGeocode(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<LocationResult> reverseGeocode(double lat, double lng) async {
    var label = '$lat, $lng';
    final suggestions = <String>[];
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        final parts = [
          pm.administrativeArea,
          pm.locality,
          pm.subLocality,
          pm.thoroughfare,
          pm.name,
        ].where((e) => e != null && e.trim().isNotEmpty).toList();
        if (parts.isNotEmpty) label = parts.join(' ');
        // name 常为 POI（医院、诊所、小区），作为医院建议
        for (final pm in placemarks) {
          final n = pm.name?.trim() ?? '';
          if (n.isNotEmpty && !suggestions.contains(n) && n != pm.locality) {
            suggestions.add(n);
          }
        }
        for (final pm in placemarks) {
          final st = pm.thoroughfare?.trim() ?? '';
          if (st.isNotEmpty && !suggestions.contains(st)) suggestions.add(st);
        }
      }
    } catch (_) {}
    return LocationResult(
        lat: lat,
        lng: lng,
        label: label,
        suggestions: suggestions.take(5).toList());
  }
}
