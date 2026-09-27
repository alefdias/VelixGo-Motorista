class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String role; // 'passenger', 'driver', 'unselected'
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
  });

  bool get isPassenger => role == 'passenger';
  bool get isDriver => role == 'driver';
  bool get hasSelectedRole => role == 'passenger' || role == 'driver';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Usuário',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'unselected',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? role,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}
