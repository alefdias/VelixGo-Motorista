class RideModel {
  final String id;
  final String passengerId;
  final String? passengerName;
  final String? passengerPhone;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? driverVehicle;
  final String? driverPlate;
  final double? driverRating;
  final String status; // 'requested', 'accepted', 'arrived', 'in_progress', 'completed', 'cancelled'
  final String vehicleType; // 'car' ou 'motorcycle'
  final String originAddress;
  final double originLat;
  final double originLng;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final double distanceKm;
  final int estimatedDurationMin;
  final double estimatedFare;
  final double? actualFare;
  final String paymentMethod; // 'pix', 'cash', 'card_machine'
  final DateTime? priorityUntil;
  final bool favoriteDriverNotified;
  final DateTime createdAt;

  RideModel({
    required this.id,
    required this.passengerId,
    this.passengerName,
    this.passengerPhone,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverVehicle,
    this.driverPlate,
    this.driverRating,
    required this.status,
    this.vehicleType = 'car',
    required this.originAddress,
    required this.originLat,
    required this.originLng,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.distanceKm,
    required this.estimatedDurationMin,
    required this.estimatedFare,
    this.actualFare,
    required this.paymentMethod,
    this.priorityUntil,
    this.favoriteDriverNotified = false,
    required this.createdAt,
  });

  bool get isRequested => status == 'requested';
  bool get isAccepted => status == 'accepted';
  bool get isArrived => status == 'arrived';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isMotorcycle => vehicleType == 'motorcycle';
  bool get isCar => vehicleType == 'car';

  // Verifica se a prioridade de 15 segundos para favoritos ainda está ativa
  bool get isFavoritePriorityActive {
    if (priorityUntil == null) return false;
    return DateTime.now().isBefore(priorityUntil!);
  }

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] as String,
      passengerId: json['passenger_id'] as String,
      passengerName: json['profiles_passenger']?['full_name'] as String? ?? json['passenger_name'] as String?,
      passengerPhone: json['profiles_passenger']?['phone'] as String? ?? json['passenger_phone'] as String?,
      driverId: json['driver_id'] as String?,
      driverName: json['profiles_driver']?['full_name'] as String? ?? json['driver_name'] as String?,
      driverPhone: json['profiles_driver']?['phone'] as String? ?? json['driver_phone'] as String?,
      driverVehicle: json['drivers']?['vehicle_model'] as String? ?? json['driver_vehicle'] as String?,
      driverPlate: json['drivers']?['vehicle_plate'] as String? ?? json['driver_plate'] as String?,
      driverRating: (json['drivers']?['rating_avg'] as num?)?.toDouble() ?? (json['driver_rating'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'requested',
      vehicleType: json['vehicle_type'] as String? ?? 'car',
      originAddress: json['origin_address'] as String? ?? '',
      originLat: (json['origin_lat'] as num?)?.toDouble() ?? 0.0,
      originLng: (json['origin_lng'] as num?)?.toDouble() ?? 0.0,
      destinationAddress: json['destination_address'] as String? ?? '',
      destinationLat: (json['destination_lat'] as num?)?.toDouble() ?? 0.0,
      destinationLng: (json['destination_lng'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMin: json['estimated_duration_min'] as int? ?? 0,
      estimatedFare: (json['estimated_fare'] as num?)?.toDouble() ?? 0.0,
      actualFare: (json['actual_fare'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String? ?? 'pix',
      priorityUntil: json['priority_until'] != null ? DateTime.parse(json['priority_until']) : null,
      favoriteDriverNotified: json['favorite_driver_notified'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passenger_id': passengerId,
      'driver_id': driverId,
      'status': status,
      'vehicle_type': vehicleType,
      'origin_address': originAddress,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'destination_address': destinationAddress,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
      'distance_km': distanceKm,
      'estimated_duration_min': estimatedDurationMin,
      'estimated_fare': estimatedFare,
      'actual_fare': actualFare ?? estimatedFare,
      'payment_method': paymentMethod,
      'priority_until': priorityUntil?.toIso8601String(),
      'favorite_driver_notified': favoriteDriverNotified,
    };
  }

  RideModel copyWith({
    String? status,
    String? vehicleType,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverVehicle,
    String? driverPlate,
    double? driverRating,
    double? actualFare,
  }) {
    return RideModel(
      id: id,
      passengerId: passengerId,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverVehicle: driverVehicle ?? this.driverVehicle,
      driverPlate: driverPlate ?? this.driverPlate,
      driverRating: driverRating ?? this.driverRating,
      status: status ?? this.status,
      vehicleType: vehicleType ?? this.vehicleType,
      originAddress: originAddress,
      originLat: originLat,
      originLng: originLng,
      destinationAddress: destinationAddress,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      distanceKm: distanceKm,
      estimatedDurationMin: estimatedDurationMin,
      estimatedFare: estimatedFare,
      actualFare: actualFare ?? this.actualFare,
      paymentMethod: paymentMethod,
      priorityUntil: priorityUntil,
      favoriteDriverNotified: favoriteDriverNotified,
      createdAt: createdAt,
    );
  }
}
