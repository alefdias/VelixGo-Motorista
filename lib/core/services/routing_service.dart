import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../utils/geo_utils.dart';

class RouteInstruction {
  final String instruction;
  final String streetName;
  final double distanceMeters;
  final double durationSeconds;
  final String modifier;
  final String type;

  const RouteInstruction({
    required this.instruction,
    required this.streetName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.modifier,
    required this.type,
  });
}

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final List<RouteInstruction> instructions;
  final bool isFromRoadNetwork;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    this.instructions = const [],
    this.isFromRoadNetwork = true,
  });
}

class RoutingService {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Obtém a rota real pelas ruas via OSRM (Open Source Routing Machine).
  /// Se houver falha de rede, faz fallback suave para interpolação viária.
  static Future<RouteResult> getDrivingRoute(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        '$_osrmBaseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final points = coordinates.map<LatLng>((coord) {
            final lng = (coord[0] as num).toDouble();
            final lat = (coord[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          final double distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final double durationSec = (route['duration'] as num?)?.toDouble() ?? 0.0;
          final double distanceKm = distanceMeters / 1000.0;
          final int durationMinutes = (durationSec / 60.0).ceil();

          // Extração das instruções passo a passo
          final instructions = <RouteInstruction>[];
          if (route['legs'] != null && (route['legs'] as List).isNotEmpty) {
            final steps = route['legs'][0]['steps'] as List?;
            if (steps != null) {
              for (final step in steps) {
                final name = (step['name'] as String?)?.trim() ?? '';
                final dist = (step['distance'] as num?)?.toDouble() ?? 0.0;
                final dur = (step['duration'] as num?)?.toDouble() ?? 0.0;
                final maneuver = step['maneuver'] as Map<String, dynamic>? ?? {};
                final type = maneuver['type'] as String? ?? '';
                final modifier = maneuver['modifier'] as String? ?? '';

                String text = _buildManeuverText(type, modifier, name);
                if (text.isNotEmpty) {
                  instructions.add(
                    RouteInstruction(
                      instruction: text,
                      streetName: name,
                      distanceMeters: dist,
                      durationSeconds: dur,
                      modifier: modifier,
                      type: type,
                    ),
                  );
                }
              }
            }
          }

          return RouteResult(
            points: points,
            distanceKm: distanceKm,
            durationMinutes: durationMinutes > 0 ? durationMinutes : 1,
            instructions: instructions,
            isFromRoadNetwork: true,
          );
        }
      }
    } catch (_) {
      // Falha silenciosa para fallback
    }

    // Fallback viário inteligente caso a API esteja temporariamente instável
    final fallbackPoints = GeoUtils.createRoutePolyline(origin, destination);
    final fallbackDist = GeoUtils.calculateDistance(origin, destination);
    final fallbackDuration = GeoUtils.estimateDurationMinutes(fallbackDist);

    return RouteResult(
      points: fallbackPoints,
      distanceKm: fallbackDist,
      durationMinutes: fallbackDuration,
      isFromRoadNetwork: false,
    );
  }

  static String _buildManeuverText(String type, String modifier, String street) {
    String action = 'Siga em frente';
    switch (type) {
      case 'turn':
        if (modifier.contains('left')) {
          action = 'Vire à esquerda';
        } else if (modifier.contains('right')) {
          action = 'Vire à direita';
        }
        break;
      case 'new name':
      case 'continue':
        action = 'Continue';
        break;
      case 'roundabout':
        action = 'Na rotatória';
        break;
      case 'depart':
        action = 'Inicie o trajeto';
        break;
      case 'arrive':
        action = 'Você chegará ao destino';
        break;
    }

    if (street.isNotEmpty && type != 'arrive') {
      return '$action na $street';
    }
    return action;
  }
}
