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
  final bool show3DToggle;
  final bool showDarkModeToggle;
  final bool? isDarkMode;
  final bool initial3DMode;
  final double? heading;
  final int? speedKmH;
  final bool showSpeedometer;
  final ValueChanged<bool>? onToggle3D;
  final EdgeInsets? padding;

  const VelixMap({
    super.key,
    required this.center,
    this.initialZoom = 15.5,
    this.markers = const [],
    this.routePoints,
    this.routeColor = AppColors.green,
    this.routeWidth = 5.0,
    this.onMapReady,
    this.onRecenter,
    this.showRecenterButton = true,
    this.show3DToggle = true,
    this.showDarkModeToggle = true,
    this.isDarkMode,
    this.initial3DMode = false,
    this.heading,
    this.speedKmH,
    this.showSpeedometer = false,
    this.onToggle3D,
    this.padding,
  });

  @override
  State<VelixMap> createState() => _VelixMapState();
}

class _VelixMapState extends State<VelixMap> {
  late final MapController _mapController;
  late bool _is3D;
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _is3D = widget.initial3DMode;
    final currentHour = DateTime.now().hour;
    _isDark = widget.isDarkMode ?? (currentHour >= 18 || currentHour < 6);
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
    if (widget.heading != null && widget.heading != oldWidget.heading && _is3D) {
      try {
        _mapController.rotate(-widget.heading!);
      } catch (_) {}
    }
    if (oldWidget.initial3DMode != widget.initial3DMode) {
      setState(() => _is3D = widget.initial3DMode);
    }
    if (widget.isDarkMode != null && widget.isDarkMode != oldWidget.isDarkMode) {
      setState(() => _isDark = widget.isDarkMode!);
    }
  }

  void _recenter() {
    try {
      final targetZoom = _is3D ? 17.5 : 16.0;
      _mapController.move(widget.center, targetZoom);
      if (_is3D && widget.heading != null) {
        _mapController.rotate(-widget.heading!);
      } else if (!_is3D) {
        _mapController.rotate(0.0);
      }
      widget.onRecenter?.call();
    } catch (_) {}
  }

  void _toggle3D() {
    setState(() {
      _is3D = !_is3D;
    });
    try {
      if (_is3D) {
        _mapController.move(widget.center, 17.5);
        if (widget.heading != null) {
          _mapController.rotate(-widget.heading!);
        }
      } else {
        _mapController.move(widget.center, 15.5);
        _mapController.rotate(0.0);
      }
    } catch (_) {}
    widget.onToggle3D?.call(_is3D);
  }

  void _toggleDarkMode() {
    setState(() {
      _isDark = !_isDark;
    });
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
          borderStrokeWidth: 2.5,
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

    Widget tileLayer = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      fallbackUrl: 'https://a.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.velixgo.driver',
      maxZoom: 19,
    );

    // Efeito Dark Mode Noturno sem necessidade de chave de API externa
    if (_isDark) {
      tileLayer = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -0.78, 0, 0, 0, 230,
          0, -0.78, 0, 0, 230,
          0, 0, -0.78, 0, 230,
          0, 0, 0, 1, 0,
        ]),
        child: tileLayer,
      );
    }

    Widget mapWidget = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: _is3D ? 17.5 : widget.initialZoom,
        initialRotation: (_is3D && widget.heading != null) ? -widget.heading! : 0.0,
        minZoom: 3,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        tileLayer,
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        if (flutterMarkers.isNotEmpty) MarkerLayer(markers: flutterMarkers),
      ],
    );

    final double bottomOffset = widget.padding?.bottom ?? 180;

    return Stack(
      children: [
        mapWidget,

        // Velocímetro Digital no Canto Inferior Esquerdo
        if (widget.showSpeedometer && widget.speedKmH != null)
          Positioned(
            left: 16,
            bottom: bottomOffset,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.88),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (widget.speedKmH! > 60) ? AppColors.red : widget.routeColor,
                  width: 3,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.speedKmH}',
                    style: TextStyle(
                      color: (widget.speedKmH! > 60) ? AppColors.red : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      height: 1.1,
                    ),
                  ),
                  const Text(
                    'km/h',
                    style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        // Botão flutuante Dark Mode (☀️ / 🌙)
        if (widget.showDarkModeToggle)
          Positioned(
            right: 16,
            bottom: bottomOffset + 110,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Colors.white,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _toggleDarkMode,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    _isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: _isDark ? Colors.amber[700] : AppColors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

        // Botão flutuante 3D / 2D
        if (widget.show3DToggle)
          Positioned(
            right: 16,
            bottom: bottomOffset + 56,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: _is3D ? widget.routeColor : Colors.white,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _toggle3D,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    _is3D ? '3D' : '2D',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: _is3D ? Colors.white : AppColors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Botão flutuante para recentralizar no GPS atual
        if (widget.showRecenterButton)
          Positioned(
            right: 16,
            bottom: bottomOffset,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Colors.white,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _recenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: widget.routeColor,
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

    return Center(
      child: Transform.rotate(
        angle: heading * (3.141592653589793 / 180),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isMoto ? AppColors.green : AppColors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isMoto ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class DestinationMarker extends StatelessWidget {
  final String title;

  const DestinationMarker({
    super.key,
    this.title = 'Destino',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.flag_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}
