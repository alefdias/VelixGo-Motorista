import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velix_go_driver/main.dart';
import 'package:velix_go_driver/core/constants/app_constants.dart';
import 'package:velix_go_driver/core/utils/formatters.dart';
import 'package:velix_go_driver/core/utils/geo_utils.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Velix Go Core Business Logic Tests', () {
    test('Calcula taxa da plataforma de R\$ 0,50 por corrida', () {
      expect(AppConstants.platformFeePerRide, 0.50);
      expect(AppConstants.autoInvoiceThreshold, 20.00);
      expect(AppConstants.autoInvoiceDaysLimit, 15);
      expect(AppConstants.favoritePrioritySeconds, 15);
    });

    test('Formata valores monetários BRL corretamente', () {
      final formatted = Formatters.formatCurrency(26.50);
      expect(formatted.contains('26,50'), isTrue);
    });

    test('Calcula distância Haversine e tarifas para Carro e Mototáxi', () {
      const p1 = LatLng(-23.5615, -46.6560); // Av. Paulista
      const p2 = LatLng(-23.5874, -46.6576); // Ibirapuera
      final distance = GeoUtils.calculateDistance(p1, p2);
      expect(distance > 2.0 && distance < 4.0, isTrue);

      // Carro
      final minutesCar = GeoUtils.estimateDurationMinutes(distance, vehicleType: 'car');
      final fareCar = GeoUtils.calculateEstimatedFare(distance, minutesCar, vehicleType: 'car');
      expect(fareCar >= AppConstants.minFareCar, isTrue);

      // Mototáxi (Mais econômico)
      final minutesMoto = GeoUtils.estimateDurationMinutes(distance, vehicleType: 'motorcycle');
      final fareMoto = GeoUtils.calculateEstimatedFare(distance, minutesMoto, vehicleType: 'motorcycle');
      expect(fareMoto >= AppConstants.minFareMoto, isTrue);
      expect(fareMoto < fareCar, isTrue); // Mototáxi é mais barato
    });
  });

  group('Velix Go Driver Widget Smoke Tests', () {
    testWidgets('Renderiza VelixGoDriverApp e navega pela Splash', (WidgetTester tester) async {
      await tester.pumpWidget(const VelixGoDriverApp());

      // Avança o tempo além da animação da Splash (1800ms)
      await tester.pump(const Duration(seconds: 3));

      // Confirma que a árvore renderizou com sucesso
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
