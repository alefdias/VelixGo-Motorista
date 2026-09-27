import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../controllers/driver_controller.dart';

class DriverActiveRideScreen extends StatefulWidget {
  const DriverActiveRideScreen({super.key});

  @override
  State<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  GoogleMapController? _mapController;

  void _callPassenger(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _messagePassenger(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('sms:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = Provider.of<DriverController>(context);
    final ride = driver.activeRide;

    if (ride == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Nenhuma corrida ativa'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar para Home'),
              ),
            ],
          ),
        ),
      );
    }

    final pickupPos = LatLng(ride.originLat, ride.originLng);
    final dropoffPos = LatLng(ride.destinationLat, ride.destinationLng);

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickupPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Passageiro (Embarque)'),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: dropoffPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destino Final'),
      ),
    };

    final polylinePoints = GeoUtils.createRoutePolyline(pickupPos, dropoffPos);
    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('driver_route'),
        points: polylinePoints,
        color: AppColors.green,
        width: 5,
      ),
    };

    return Scaffold(
      body: Stack(
        children: [
          // Mapa com Navegação
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pickupPos,
              zoom: 15,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (ctrl) => _mapController = ctrl,
          ),

          // Top Header com Botão Waze/Google Maps Externo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.navigation, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _getStepLabel(ride.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botão Centralizar GPS
          Positioned(
            bottom: 270,
            right: 16,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.my_location, color: AppColors.black),
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(driver.currentLocation),
                    );
                  },
                ),
              ),
            ),
          ),

          // Bottom Sheet de Navegação do Motorista
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Informações do Passageiro
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.surfaceLight,
                        child: const Icon(Icons.person, color: AppColors.black, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.passengerName ?? 'Carlos Mendes',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Forma de pagamento: ${ride.paymentMethod.toUpperCase()}',
                              style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.call),
                        onPressed: () => _callPassenger(ride.passengerPhone ?? '(11) 98765-4321'),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline),
                        onPressed: () => _messagePassenger(ride.passengerPhone ?? '(11) 98765-4321'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 8),

                  // Endereço de destino e valor
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Destino da Corrida', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                            Text(
                              ride.destinationAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Valor a receber', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                          Text(
                            Formatters.formatCurrency(ride.estimatedFare),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Alerta da regra de recebimento direto e taxa R$ 0,50
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Receba ${Formatters.formatCurrency(ride.estimatedFare)} direto do passageiro via ${ride.paymentMethod.toUpperCase()}. Taxa de R\$ 0,50 vai para o Saldo Velix.',
                            style: const TextStyle(fontSize: 11, color: AppColors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Botão de Avanço do Fluxo (Cheguei -> Iniciar -> Finalizar)
                  ElevatedButton(
                    onPressed: () async {
                      final isFinishing = ride.status == 'in_progress';
                      await driver.advanceRideStatus();
                      if (isFinishing && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.green,
                            content: Text(
                              'Corrida finalizada! R\$ 0,50 adicionado ao seu Saldo Velix.',
                            ),
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getActionButtonColor(ride.status),
                    ),
                    child: Text(_getActionButtonText(ride.status)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Navegando até o passageiro';
      case 'arrived':
        return 'Aguardando embarque';
      case 'in_progress':
        return 'Em rota até o destino';
      default:
        return 'Navegação';
    }
  }

  String _getActionButtonText(String status) {
    switch (status) {
      case 'accepted':
        return 'Cheguei no Ponto de Embarque';
      case 'arrived':
        return 'Iniciar Viagem';
      case 'in_progress':
        return 'Finalizar Corrida e Confirmar Pagamento';
      default:
        return 'Avançar';
    }
  }

  Color _getActionButtonColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.blue;
      case 'arrived':
        return AppColors.yellow;
      case 'in_progress':
        return AppColors.green;
      default:
        return AppColors.blue;
    }
  }
}
