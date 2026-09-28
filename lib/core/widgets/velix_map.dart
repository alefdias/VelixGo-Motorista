import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';

class VelixMapMarker {
  final LatLng point;
  final Widget child;
  final double width;
  final double height;
  final Alignment alignment;

  const VelixMapMarker({
    required this.point,
    required this.child,
    this.width = 44,
    this.height = 44,
    this.alignment = Alignment.center,
  });
}

class VelixMap extends StatefulWidget {
  final LatLng center;
  final double initialZoom;
  final List<VelixMapMarker> markers;
  final List<LatLng>? routePoints;
  final Color routeColor;
  final double routeWidth;
  final Function(MapController)? onMapReady;
  final VoidCallback? onRecenter;
  final bool showRecenterButton;
  final EdgeInsets? padding;

  const VelixMap({
    super.key,
    required this.center,
    this.initialZoom = 15.5,
    this.markers = const [],
    this.routePoints,
    this.routeColor = AppColors.blue,
    this.routeWidth = 5.0,
    this.onMapReady,
    this.onRecenter,
    this.showRecenterButton = true,
    this.padding,
  });

  @override
  State<VelixMap> createState() => _VelixMapState();
}

class _VelixMapState extends State<VelixMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    widget.onMapReady?.call(_mapController);
  }

  @override
  void didUpdateWidget(covariant VelixMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center != widget.center) {
      try {
        _mapController.move(widget.center, _mapController.camera.zoom);
      } catch (_) {}
    }
  }

  void _recenter() {
    try {
      _mapController.move(widget.center, 16.0);
      widget.onRecenter?.call();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final polylines = <Polyline>[];
    if (widget.routePoints != null && widget.routePoints!.length >= 2) {
      polylines.add(
        Polyline(
          points: widget.routePoints!,
          strokeWidth: widget.routeWidth,
          color: widget.routeColor,
          borderStrokeWidth: 2.0,
          borderColor: Colors.white,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    final flutterMarkers = widget.markers.map((m) {
      return Marker(
        point: m.point,
        width: m.width,
        height: m.height,
        alignment: m.alignment,
        child: m.child,
      );
    }).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.initialZoom,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
              fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.velixgo.driver',
              maxZoom: 19,
            ),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            if (flutterMarkers.isNotEmpty) MarkerLayer(markers: flutterMarkers),
          ],
        ),

        if (widget.showRecenterButton)
          Positioned(
            right: 16,
            bottom: widget.padding?.bottom ?? 180,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Colors.white,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _recenter,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: AppColors.blue,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Marcadores pré-estilizados de alta qualidade
class PassengerLocationMarker extends StatelessWidget {
  final String? label;

  const PassengerLocationMarker({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 4),
              ],
            ),
            child: Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 2),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.person_pin_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class DriverVehicleMarker extends StatelessWidget {
  final String vehicleType; // 'car' ou 'motorcycle'
  final String? label;
  final double heading;

  const DriverVehicleMarker({
    super.key,
    this.vehicleType = 'car',
    this.label,
    this.heading = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isMoto = vehicleType == 'motorcycle';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 4),
              ],
            ),
            child: Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 2),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isMoto ? AppColors.green : AppColors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Center(
            child: Icon(
              isMoto ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class DestinationMarker extends StatelessWidget {
  final String? title;

  const DestinationMarker({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 4),
              ],
            ),
            child: Text(
              title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const Icon(
          Icons.location_on_rounded,
          color: AppColors.red,
          size: 38,
          shadows: [
            Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
      ],
    );
  }
}
