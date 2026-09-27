import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/driver_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'driver_home_screen.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  String _vehicleType = 'motorcycle'; // 'motorcycle' (Mototáxi) ou 'car' (Carro)
  final _cnhController = TextEditingController(text: '04829104820');
  final _vehicleModelController = TextEditingController(text: 'Honda CG 160 Fan');
  final _plateController = TextEditingController(text: 'BRA2E19');
  final _colorController = TextEditingController(text: 'Preta');
  final _yearController = TextEditingController(text: '2023');

  bool _cnhUploaded = true;
  bool _crlvUploaded = true;

  @override
  void dispose() {
    _cnhController.dispose();
    _vehicleModelController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthController>(context, listen: false);
    final driver = Provider.of<DriverController>(context, listen: false);

    final user = auth.currentUser;
    final driverId = user?.id ?? 'mock-driver-1';

    await driver.registerVehicle(
      driverId: driverId,
      fullName: user?.fullName ?? 'Marcos Silva',
      phone: user?.phone.isNotEmpty == true ? user!.phone : '(11) 99887-1122',
      cnhNumber: _cnhController.text.trim(),
      vehicleType: _vehicleType,
      vehicleModel: _vehicleModelController.text.trim(),
      vehiclePlate: _plateController.text.trim(),
      vehicleColor: _colorController.text.trim(),
      vehicleYear: _yearController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.green,
          content: Text('Cadastro concluído com sucesso! Bem-vindo ao Velix Go.'),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = Provider.of<DriverController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cadastro de Motorista'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.blue.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: AppColors.blue, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Taxa fixa de apenas R\$ 0,50 por corrida. Todo o valor do passageiro é seu!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Documentação do Condutor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cnhController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número da CNH',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => (v == null || v.length < 9) ? 'CNH inválida' : null,
                ),
                const SizedBox(height: 12),
                // Botão de upload de foto CNH
                _UploadCard(
                  title: 'Foto da CNH',
                  isUploaded: _cnhUploaded,
                  onTap: () {
                    setState(() => _cnhUploaded = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Foto da CNH anexada com sucesso.')),
                    );
                  },
                ),

                const SizedBox(height: 24),
                const Text(
                  'Tipo de Veículo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _vehicleType = 'motorcycle';
                            _vehicleModelController.text = 'Honda CG 160 Fan';
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _vehicleType == 'motorcycle' ? AppColors.green.withOpacity(0.12) : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _vehicleType == 'motorcycle' ? AppColors.green : AppColors.borderLight,
                              width: _vehicleType == 'motorcycle' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.two_wheeler_rounded, color: _vehicleType == 'motorcycle' ? AppColors.green : AppColors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Mototáxi / Moto',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _vehicleType == 'motorcycle' ? AppColors.green : AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _vehicleType = 'car';
                            _vehicleModelController.text = 'Toyota Corolla 2.0';
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _vehicleType == 'car' ? AppColors.blue.withOpacity(0.12) : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _vehicleType == 'car' ? AppColors.blue : AppColors.borderLight,
                              width: _vehicleType == 'car' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.directions_car_rounded, color: _vehicleType == 'car' ? AppColors.blue : AppColors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Carro',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _vehicleType == 'car' ? AppColors.blue : AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dados do Veículo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vehicleModelController,
                  decoration: InputDecoration(
                    labelText: _vehicleType == 'motorcycle'
                        ? 'Modelo da Moto (ex: Honda CG 160 Fan, Fazer)'
                        : 'Modelo do Carro (ex: Toyota Corolla, Onix)',
                    prefixIcon: Icon(_vehicleType == 'motorcycle' ? Icons.two_wheeler : Icons.directions_car_outlined),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o modelo' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _plateController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Placa (Mercosul)',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                        validator: (v) => (v == null || v.length < 7) ? 'Placa inválida' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Ano'),
                        validator: (v) => (v == null || v.length != 4) ? 'Ano inválido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    labelText: 'Cor do Veículo',
                    prefixIcon: Icon(Icons.palette_outlined),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe a cor' : null,
                ),
                const SizedBox(height: 12),
                // Upload documento CRLV do veículo
                _UploadCard(
                  title: 'Documento do Veículo (CRLV)',
                  isUploaded: _crlvUploaded,
                  onTap: () {
                    setState(() => _crlvUploaded = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Documento do veículo anexado com sucesso.')),
                    );
                  },
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: driver.isLoading ? null : _submit,
                  child: driver.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Concluir Cadastro & Começar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final String title;
  final bool isUploaded;
  final VoidCallback onTap;

  const _UploadCard({
    required this.title,
    required this.isUploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isUploaded ? AppColors.green.withOpacity(0.08) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded ? AppColors.green : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isUploaded ? Icons.check_circle : Icons.cloud_upload_outlined,
              color: isUploaded ? AppColors.green : AppColors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isUploaded ? AppColors.green : AppColors.black,
                ),
              ),
            ),
            Text(
              isUploaded ? 'Anexado' : 'Enviar Foto',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isUploaded ? AppColors.green : AppColors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
