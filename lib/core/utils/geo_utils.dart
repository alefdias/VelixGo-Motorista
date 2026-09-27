import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';

class GeoUtils {
  // Fórmula de Haversine para cálculo preciso de distância entre coordenadas
  static double calculateDistance(LatLng start, LatLng end) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _deg2rad(end.latitude - start.latitude);
    final double dLng = _deg2rad(end.longitude - start.longitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(start.latitude)) *
            math.cos(_deg2rad(end.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);

  // Estimativa de tempo (Mototáxi é ~20% mais rápido em corredores urbanos)
  static int estimateDurationMinutes(double distanceKm, {String vehicleType = 'car'}) {
    final double speedKmH = vehicleType == 'motorcycle' ? 32.0 : 25.0;
    final double hours = distanceKm / speedKmH;
    final int minutes = (hours * 60).round() + (vehicleType == 'motorcycle' ? 2 : 3);
    return math.max(minutes, vehicleType == 'motorcycle' ? 3 : 4);
  }

  // Cálculo da tarifa estimada para o passageiro conforme categoria (Carro vs Mototáxi)
  static double calculateEstimatedFare(
    double distanceKm,
    int durationMinutes, {
    String vehicleType = 'car',
  }) {
    if (vehicleType == 'motorcycle') {
      final double fare = AppConstants.baseFareMoto +
          (distanceKm * AppConstants.pricePerKmMoto) +
          (durationMinutes * AppConstants.pricePerMinuteMoto);
      return math.max(fare, AppConstants.minFareMoto);
    } else {
      final double fare = AppConstants.baseFareCar +
          (distanceKm * AppConstants.pricePerKmCar) +
          (durationMinutes * AppConstants.pricePerMinuteCar);
      return math.max(fare, AppConstants.minFareCar);
    }
  }

  // Gera uma rota suave interpolada entre origem e destino para o Polyline
  static List<LatLng> createRoutePolyline(LatLng origin, LatLng destination) {
    final List<LatLng> points = [origin];
    const int segments = 12;

    for (int i = 1; i < segments; i++) {
      final double fraction = i / segments;
      final double lat = origin.latitude + (destination.latitude - origin.latitude) * fraction;
      final double lng = origin.longitude + (destination.longitude - origin.longitude) * fraction;
      
      final double offset = math.sin(fraction * math.pi) * 0.0018;
      points.add(LatLng(lat + offset, lng - offset / 2));
    }

    points.add(destination);
    return points;
  }

  // Gera veículos simulados próximos para demonstração no mapa (misturando motos e carros)
  static List<LatLng> getNearbySimulatedDrivers(LatLng center) {
    return [
      LatLng(center.latitude + 0.0035, center.longitude + 0.0028),
      LatLng(center.latitude - 0.0042, center.longitude - 0.0031),
      LatLng(center.latitude + 0.0021, center.longitude - 0.0045),
      LatLng(center.latitude - 0.0038, center.longitude + 0.0040),
    ];
  }
}
