class DriverModel {
  final String id;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final String cnhNumber;
  final String vehicleType; // 'car' ou 'motorcycle'
  final String vehicleModel;
  final String vehiclePlate;
  final String vehicleColor;
  final String vehicleYear;
  final String? cnhDocUrl;
  final String? vehicleDocUrl;
  final bool isVerified;
  final bool isOnline;
  final double currentBalance; // Saldo devedor de taxas (R$ 0,50 / corrida)
  final DateTime lastBilledAt;
  final double ratingAvg;
  final int totalRides;

  DriverModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    required this.cnhNumber,
    this.vehicleType = 'car',
    required this.vehicleModel,
    required this.vehiclePlate,
    required this.vehicleColor,
    required this.vehicleYear,
    this.cnhDocUrl,
    this.vehicleDocUrl,
    this.isVerified = false,
    this.isOnline = false,
    this.currentBalance = 0.0,
    required this.lastBilledAt,
    this.ratingAvg = 5.0,
    this.totalRides = 0,
  });

  bool get isMotorcycle => vehicleType == 'motorcycle';
  bool get isCar => vehicleType == 'car';

  factory DriverModel.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? profileJson}) {
    return DriverModel(
      id: json['id'] as String,
      fullName: profileJson?['full_name'] as String? ?? json['full_name'] as String? ?? 'Motorista Velix',
      phone: profileJson?['phone'] as String? ?? json['phone'] as String? ?? '',
      avatarUrl: profileJson?['avatar_url'] as String? ?? json['avatar_url'] as String?,
      cnhNumber: json['cnh_number'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? 'car',
      vehicleModel: json['vehicle_model'] as String? ?? '',
      vehiclePlate: json['vehicle_plate'] as String? ?? '',
      vehicleColor: json['vehicle_color'] as String? ?? '',
      vehicleYear: json['vehicle_year'] as String? ?? '',
      cnhDocUrl: json['cnh_doc_url'] as String?,
      vehicleDocUrl: json['vehicle_doc_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      lastBilledAt: json['last_billed_at'] != null
          ? DateTime.parse(json['last_billed_at'])
          : DateTime.now(),
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 5.0,
      totalRides: json['total_rides'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cnh_number': cnhNumber,
      'vehicle_type': vehicleType,
      'vehicle_model': vehicleModel,
      'vehicle_plate': vehiclePlate,
      'vehicle_color': vehicleColor,
      'vehicle_year': vehicleYear,
      'cnh_doc_url': cnhDocUrl,
      'vehicle_doc_url': vehicleDocUrl,
      'is_verified': isVerified,
      'is_online': isOnline,
      'current_balance': currentBalance,
      'last_billed_at': lastBilledAt.toIso8601String(),
      'rating_avg': ratingAvg,
      'total_rides': totalRides,
    };
  }

  DriverModel copyWith({
    String? vehicleType,
    String? vehicleModel,
    String? vehiclePlate,
    String? vehicleColor,
    String? vehicleYear,
    bool? isOnline,
    double? currentBalance,
    DateTime? lastBilledAt,
    double? ratingAvg,
    int? totalRides,
    bool? isVerified,
  }) {
    return DriverModel(
      id: id,
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
      cnhNumber: cnhNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      cnhDocUrl: cnhDocUrl,
      vehicleDocUrl: vehicleDocUrl,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      currentBalance: currentBalance ?? this.currentBalance,
      lastBilledAt: lastBilledAt ?? this.lastBilledAt,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      totalRides: totalRides ?? this.totalRides,
    );
  }
}
