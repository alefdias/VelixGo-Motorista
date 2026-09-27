import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../driver/controllers/driver_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final driver = Provider.of<DriverController>(context);
    final user = auth.currentUser;
    final profile = driver.driverProfile;

    final vehicleTypeDesc = profile?.isMotorcycle == true ? 'Mototáxi (Moto)' : 'Carro';
    final vehicleIcon = profile?.isMotorcycle == true ? Icons.two_wheeler : Icons.directions_car;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Perfil do Motorista'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.surfaceLight,
                  backgroundImage: NetworkImage(
                    user?.avatarUrl ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user?.fullName ?? 'Motorista Parceiro',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.black),
            ),
          ),
          Center(
            child: Text(
              user?.email ?? 'motorista@velixgo.com.br',
              style: const TextStyle(fontSize: 14, color: AppColors.grey),
            ),
          ),
          const SizedBox(height: 24),

          // Informações da Parceria
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined, color: AppColors.green),
                  title: const Text('Status da Conta'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Parceiro Verificado',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(vehicleIcon, color: AppColors.black),
                  title: const Text('Categoria Veicular'),
                  trailing: Text(
                    vehicleTypeDesc,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.credit_card, color: AppColors.blue),
                  title: const Text('Taxa Velix'),
                  trailing: const Text(
                    'R\$ 0,50 por corrida',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.green),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.black),
                  title: const Text('Saldo Acumulado de Taxas'),
                  trailing: Text(
                    Formatters.formatCurrency(driver.velixBalance),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Informações do App e Suporte
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security, color: AppColors.green),
                  title: const Text('Segurança e Termos do Parceiro'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppColors.blue),
                  title: const Text('Suporte ao Motorista'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            icon: const Icon(Icons.logout, color: AppColors.red),
            label: const Text('Sair da Conta', style: TextStyle(color: AppColors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}
