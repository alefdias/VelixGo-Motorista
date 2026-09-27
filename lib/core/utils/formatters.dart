import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(dateTime.toLocal());
  }

  static String formatSimpleDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(dateTime.toLocal());
  }

  // Gera código Pix estático para cobrança de taxas do motorista (EMV standard simplificado)
  static String generateMockPix({required String invoiceId, required double amount}) {
    final valueStr = amount.toStringAsFixed(2);
    return '00020126580014BR.GOV.BCB.PIX0136velix-pix-cobranca@velixgo.com.br'
        '520400005303986540$valueStr'
        '5802BR5908VELIX GO6009SAO PAULO62070503$invoiceId 6304ABCD';
  }
}
