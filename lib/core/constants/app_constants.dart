class AppConstants {
  static const String appName = 'Velix Go';
  static const String appTagline = 'Mobilidade Rápida, Justa e Segura';

  // Configuração Supabase Oficial (Conectado)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kidpfkdxlhqzmpkvkjxh.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtpZHBma2R4bGhxem1wa3ZranhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA1NDM2NTUsImV4cCI6MjEwNjExOTY1NX0.ShnHRB4eg7etyJQRvEXMmKzhZhVBT3NgsqUQnddlyxA',
  );

  // Regras de Negócio e Tarifas da Plataforma
  static const double platformFeePerRide = 0.50; // R$ 0,50 por corrida concluída cobrada do motorista
  static const double autoInvoiceThreshold = 20.00; // Cobrança automática ao atingir R$ 20,00
  static const int autoInvoiceDaysLimit = 15; // Ou completar 15 dias da última cobrança
  static const int favoritePrioritySeconds = 15; // 15 segundos de prioridade para motoristas favoritos

  // Tarifas Carro (Velix Carro)
  static const double baseFareCar = 5.00;
  static const double pricePerKmCar = 2.40;
  static const double pricePerMinuteCar = 0.35;
  static const double minFareCar = 8.50;

  // Tarifas Moto / Mototáxi (Velix Moto - Econômico e ágil)
  static const double baseFareMoto = 3.50;
  static const double pricePerKmMoto = 1.60;
  static const double pricePerMinuteMoto = 0.22;
  static const double minFareMoto = 6.00;

  // Google Maps fallback location (São Paulo - Marco Zero / Paulista)
  static const double defaultLat = -23.5615;
  static const double defaultLng = -46.6560;
}
