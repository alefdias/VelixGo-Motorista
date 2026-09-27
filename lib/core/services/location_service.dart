import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';

class LocationService {
  static Future<LatLng> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
    }
  }

  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Atualiza a cada 5 metros
      ),
    );
  }
}
