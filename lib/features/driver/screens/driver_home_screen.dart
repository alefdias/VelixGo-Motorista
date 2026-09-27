import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/ride_model.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/driver_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/screens/profile_screen.dart';
import 'incoming_ride_dialog.dart';
import 'driver_active_ride_screen.dart';
import 'earnings_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final driver = Provider.of<DriverController>(context, listen: false);
      driver.initialize(auth.currentUser?.id ?? 'mock-driver-1');
    });
  }

  void _showIncomingRide(RideModel ride) {
    final driver = Provider.of<DriverController>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomingRideDialog(
        ride: ride,
        onAccept: () async {
          await driver.acceptRide(ride);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverActiveRideScreen()),
            );
          }
        },
        onDecline: () {
          driver.declineRide(ride);
        },
      ),
    );
  }

  // Simula recebimento de uma corrida em tempo real para testes rápidos
  void _simulateIncomingRide() {
    final driver = Provider.of<DriverController>(context, listen: false);
    final simulated = RideModel(
      id: 'ride-sim-${DateTime.now().millisecondsSinceEpoch}',
      passengerId: 'mock-passenger-2',
      passengerName: 'Camila Rocha',
      passengerPhone: '(11) 97766-3322',
      status: 'requested',
      originAddress: 'Rua Bela Cintra, 890 - Consolação',
      originLat: driver.currentLocation.latitude + 0.004,
      originLng: driver.currentLocation.longitude + 0.003,
      destinationAddress: 'Av. Brigadeiro Faria Lima, 2200 - Pinheiros',
      destinationLat: driver.currentLocation.latitude - 0.015,
      destinationLng: driver.currentLocation.longitude - 0.012,
      distanceKm: 5.4,
      estimatedDurationMin: 14,
      estimatedFare: 21.50,
      paymentMethod: 'pix',
      createdAt: DateTime.now(),
    );

    _showIncomingRide(simulated);
  }

  @override
  Widget build(BuildContext context) {
    final driver = Provider.of<DriverController>(context);
    final auth = Provider.of<AuthController>(context);

    // Se houver corrida pendente na fila em tempo real, exibe o modal
    if (driver.pendingRides.isNotEmpty) {
      final nextRide = driver.pendingRides.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIncomingRide(nextRide);
      });
    }

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('driver_pos'),
        position: driver.currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          driver.isOnline ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: driver.isOnline ? 'Você está Online' : 'Você está Offline',
        ),
      ),
    };

    return Scaffold(
      drawer: _buildDrawer(context, auth, driver),
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: driver.currentLocation,
              zoom: 15,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (ctrl) => _mapController = ctrl,
          ),

          // Header Superior com Menu e Card de Ganhos / Saldo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Builder(
                        builder: (ctx) => Material(
                          elevation: 4,
                          shape: const CircleBorder(),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.menu, color: AppColors.black),
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Card Resumo de Ganhos Hoje e Saldo Velix
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EarningsScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.black,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Hoje', style: TextStyle(color: AppColors.greyLight, fontSize: 10)),
                                    Text(
                                      Formatters.formatCurrency(driver.earningsToday),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(height: 20, width: 1, color: AppColors.borderDark),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Saldo Velix', style: TextStyle(color: AppColors.greyLight, fontSize: 10)),
                                    Text(
                                      Formatters.formatCurrency(driver.velixBalance),
                                      style: TextStyle(
                                        color: driver.velixBalance > 15 ? AppColors.red : AppColors.green,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Alerta de Fatura Pendente se houver
                  if (driver.pendingInvoice != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EarningsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: AppColors.red.withOpacity(0.3), blurRadius: 8),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fatura Pix de ${Formatters.formatCurrency(driver.pendingInvoice!.amount)} pendente. Pagar agora.',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Se tiver corrida ativa em andamento, card flutuante para voltar à navegação
          if (driver.activeRide != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 140,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DriverActiveRideScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.green.withOpacity(0.4), blurRadius: 12),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.navigation, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Corrida em andamento com ${driver.activeRide?.passengerName ?? 'Passageiro'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ),

          // Botão Centralizar GPS Motorista
          Positioned(
            right: 16,
            bottom: 160,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.black,
              elevation: 4,
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: driver.currentLocation, zoom: 15),
                  ),
                );
              },
              child: const Icon(Icons.my_location),
            ),
          ),

          // Painel Inferior: Chave Online / Offline e Botão de Simulação
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.isOnline ? '🟢 Você está Online' : '🔴 Você está Offline',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: driver.isOnline ? AppColors.green : AppColors.red,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            driver.isOnline
                                ? 'Pronto para receber chamadas de passageiros'
                                : 'Ative para começar a faturar',
                            style: const TextStyle(fontSize: 13, color: AppColors.grey),
                          ),
                        ],
                      ),
                      Switch(
                        value: driver.isOnline,
                        activeColor: AppColors.green,
                        onChanged: (_) {
                          driver.toggleOnline(auth.currentUser?.id ?? 'mock-driver-1');
                        },
                      ),
                    ],
                  ),

                  // Botão de Teste / Simulação de Corrida Recebida
                  if (driver.isOnline) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _simulateIncomingRide,
                      icon: const Icon(Icons.play_circle_outline, color: AppColors.blue, size: 20),
                      label: const Text('Simular Nova Corrida Recebida'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        side: const BorderSide(color: AppColors.blue),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthController auth, DriverController driver) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.black),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
              ),
            ),
            accountName: Text(
              driver.driverProfile?.fullName ?? 'Marcos Silva',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            accountEmail: Text(
              '${driver.driverProfile?.vehicleModel ?? 'Toyota Corolla'} • ${driver.driverProfile?.vehiclePlate ?? 'BRA2E19'}',
              style: const TextStyle(color: AppColors.greyLight, fontSize: 13),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.green),
            title: const Text('Ganhos & Saldo Velix', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Saldo devedor: ${Formatters.formatCurrency(driver.velixBalance)}', style: const TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.black),
            title: const Text('Meu Perfil & Veículo', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.red),
            title: const Text('Sair da Conta', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
