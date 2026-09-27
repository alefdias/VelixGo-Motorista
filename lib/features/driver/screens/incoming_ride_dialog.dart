import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/ride_model.dart';
import '../../../core/utils/formatters.dart';

class IncomingRideDialog extends StatefulWidget {
  final RideModel ride;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingRideDialog({
    super.key,
    required this.ride,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<IncomingRideDialog> createState() => _IncomingRideDialogState();
}

class _IncomingRideDialogState extends State<IncomingRideDialog> {
  int _secondsLeft = 15;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        widget.onDecline();
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho com Alerta de Nova Corrida e Contador
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.ride.isMotorcycle ? AppColors.green.withOpacity(0.15) : AppColors.blue.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.ride.isMotorcycle ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
                        color: widget.ride.isMotorcycle ? AppColors.green : AppColors.blue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ride.isMotorcycle ? 'Novo Mototáxi!' : 'Nova Corrida Carro!',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          widget.ride.isMotorcycle ? 'Categoria: Moto' : 'Categoria: Carro',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.ride.isMotorcycle ? AppColors.green : AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(
                        value: _secondsLeft / 15,
                        strokeWidth: 3,
                        color: _secondsLeft <= 5 ? AppColors.red : AppColors.blue,
                        backgroundColor: AppColors.surfaceLight,
                      ),
                    ),
                    Text(
                      '$_secondsLeft',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _secondsLeft <= 5 ? AppColors.red : AppColors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Valor Estimado para o Motorista
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  const Text('Valor da Viagem (100% seu)', style: TextStyle(color: AppColors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCurrency(widget.ride.estimatedFare),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Recebimento via ${widget.ride.paymentMethod.toUpperCase()}',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Taxa Velix: R\$ 0,50',
                        style: TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Dados da Corrida (Origem e Destino)
            Row(
              children: [
                const Icon(Icons.circle, color: AppColors.green, size: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.ride.originAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4, top: 4, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 14,
                  child: VerticalDivider(color: AppColors.borderLight, thickness: 1.5),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.blue, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.ride.destinationAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.straighten, size: 16, color: AppColors.grey),
                const SizedBox(width: 4),
                Text(
                  Formatters.formatDistance(widget.ride.distanceKm),
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
                const SizedBox(width: 14),
                Icon(Icons.schedule, size: 16, color: AppColors.grey),
                const SizedBox(width: 4),
                Text(
                  Formatters.formatDuration(widget.ride.estimatedDurationMin),
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Botões Recusar e Aceitar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _timer?.cancel();
                      widget.onDecline();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                    ),
                    child: const Text('Recusar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _timer?.cancel();
                      widget.onAccept();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                    ),
                    child: const Text('Aceitar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
