import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../models/user_profile.dart';
import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../models/invoice_model.dart';
import '../utils/formatters.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _isLive = false;

  bool get isLive => _isLive;
  SupabaseClient get client => _client ?? Supabase.instance.client;

  // Mock State para modo desenvolvimento / demonstração offline
  UserProfile? _mockCurrentUser;
  DriverModel? _mockDriver;
  final List<RideModel> _mockRides = [];
  final List<String> _mockFavoriteDriverIds = [];
  final List<InvoiceModel> _mockInvoices = [];
  final StreamController<RideModel> _activeRideController = StreamController<RideModel>.broadcast();
  final StreamController<List<RideModel>> _pendingRidesController = StreamController<List<RideModel>>.broadcast();

  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _isLive = true;
    } catch (_) {
      // Se não houver credenciais remotas conectadas, opera em modo resiliente local
      _isLive = false;
      _initMockData();
    }
  }

  void _initMockData() {
    _mockCurrentUser = UserProfile(
      id: 'mock-user-1',
      fullName: 'Carlos Mendes',
      email: 'carlos@velixgo.com.br',
      phone: '(11) 98765-4321',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      role: 'driver',
      createdAt: DateTime.now(),
    );

    _mockDriver = DriverModel(
      id: 'mock-driver-1',
      fullName: 'Marcos Silva',
      phone: '(11) 99887-1122',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      cnhNumber: '12345678900',
      vehicleModel: 'Toyota Corolla 2.0',
      vehiclePlate: 'BRA2E19',
      vehicleColor: 'Prata',
      vehicleYear: '2023',
      isVerified: true,
      isOnline: false,
      currentBalance: 12.50, // R$ 12,50 acumulados de corridas anteriores
      lastBilledAt: DateTime.now().subtract(const Duration(days: 8)),
      ratingAvg: 4.94,
      totalRides: 48,
    );

    // Inserção de uma fatura de exemplo anterior
    _mockInvoices.add(
      InvoiceModel(
        id: 'inv-prev-001',
        driverId: 'mock-driver-1',
        amount: 20.00,
        status: 'paid',
        pixCopyPaste: Formatters.generateMockPix(invoiceId: 'inv-prev-001', amount: 20.00),
        dueDate: DateTime.now().subtract(const Duration(days: 9)),
        paidAt: DateTime.now().subtract(const Duration(days: 8)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AUTH & PROFILE
  // ---------------------------------------------------------------------------

  Future<UserProfile?> getCurrentUser() async {
    if (_isLive) {
      final user = client.auth.currentUser;
      if (user == null) {
        return null;
      }

      final name = user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String? ??
          user.email?.split('@').first ??
          'Motorista Parceiro';
      final avatar = user.userMetadata?['avatar_url'] as String? ??
          user.userMetadata?['picture'] as String?;

      final realProfile = UserProfile(
        id: user.id,
        fullName: name,
        email: user.email ?? '',
        phone: user.phone ?? '',
        avatarUrl: avatar,
        role: 'driver',
        createdAt: DateTime.now(),
      );

      // Sincroniza o perfil real no banco do Supabase
      try {
        await client.from('profiles').upsert({
          'id': user.id,
          'full_name': name,
          'email': user.email,
          'avatar_url': avatar,
          'role': 'driver',
          'updated_at': DateTime.now().toIso8601String(),
        });
        await client.from('drivers').upsert({
          'id': user.id,
          'full_name': name,
          'avatar_url': avatar,
          'phone': user.phone ?? '',
          'is_online': false,
        });
      } catch (e) {
        debugPrint('Erro ao sincronizar motorista com Supabase: $e');
      }

      return realProfile;
    }
    return _mockCurrentUser;
  }

  Future<UserProfile> signInWithEmail(String email, String password) async {
    if (_isLive) {
      try {
        final res = await client.auth.signInWithPassword(email: email, password: password);
        if (res.user != null) {
          final profile = await getCurrentUser();
          if (profile != null) return profile;
        }
      } catch (_) {}
    }

    _mockCurrentUser = UserProfile(
      id: '00000000-0000-0000-0000-000000000002',
      fullName: email.split('@').first,
      email: email,
      phone: '(11) 97123-9988',
      role: 'driver',
      createdAt: DateTime.now(),
    );
    return _mockCurrentUser!;
  }

  Future<UserProfile> signUpWithEmail(String email, String password, String name) async {
    if (_isLive) {
      try {
        final res = await client.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': name, 'role': 'driver'},
        );
        if (res.user != null) {
          return UserProfile(
            id: res.user!.id,
            fullName: name,
            email: email,
            phone: '',
            role: 'driver',
            createdAt: DateTime.now(),
          );
        }
      } catch (_) {}
    }

    _mockCurrentUser = UserProfile(
      id: '00000000-0000-0000-0000-000000000002',
      fullName: name,
      email: email,
      phone: '',
      role: 'driver',
      createdAt: DateTime.now(),
    );
    return _mockCurrentUser!;
  }

  Future<bool> signInSocial(String provider, {String redirectScheme = 'com.velixgo.driver'}) async {
    if (_isLive) {
      try {
        final oAuthProvider = provider.toLowerCase() == 'google'
            ? OAuthProvider.google
            : OAuthProvider.apple;

        return await client.auth.signInWithOAuth(
          oAuthProvider,
          redirectTo: '$redirectScheme://login-callback',
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Erro ao iniciar OAuth motorista $provider: $e');
        return false;
      }
    }
    return false;
  }

  Future<void> updateRole(String role) async {
    if (_isLive && client.auth.currentUser != null) {
      try {
        await client.from('profiles').update({'role': role}).eq('id', client.auth.currentUser!.id);
      } catch (_) {}
    }
    if (_mockCurrentUser != null) {
      _mockCurrentUser = _mockCurrentUser!.copyWith(role: role);
    }
  }

  Future<void> signOut() async {
    if (_isLive) {
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
    _mockCurrentUser = null;
  }

  // ---------------------------------------------------------------------------
  // PASSENGER ACTIONS & FAVORITE DRIVERS
  // ---------------------------------------------------------------------------

  Future<List<String>> getFavoriteDriverIds(String passengerId) async {
    if (_isLive) {
      try {
        final res = await client
            .from('favorite_drivers')
            .select('driver_id')
            .eq('passenger_id', passengerId);
        return (res as List).map((e) => e['driver_id'] as String).toList();
      } catch (_) {}
    }
    return List.from(_mockFavoriteDriverIds);
  }

  Future<bool> toggleFavoriteDriver(String passengerId, String driverId) async {
    if (_isLive) {
      try {
        final exists = await client
            .from('favorite_drivers')
            .select()
            .eq('passenger_id', passengerId)
            .eq('driver_id', driverId)
            .maybeSingle();

        if (exists != null) {
          await client
              .from('favorite_drivers')
              .delete()
              .eq('passenger_id', passengerId)
              .eq('driver_id', driverId);
          return false;
        } else {
          await client.from('favorite_drivers').insert({
            'passenger_id': passengerId,
            'driver_id': driverId,
          });
          return true;
        }
      } catch (_) {}
    }

    if (_mockFavoriteDriverIds.contains(driverId)) {
      _mockFavoriteDriverIds.remove(driverId);
      return false;
    } else {
      _mockFavoriteDriverIds.add(driverId);
      return true;
    }
  }

  // Solicitar Corrida com regra de prioridade de 15 segundos para motoristas favoritos
  Future<RideModel> requestRide(RideModel ride) async {
    // Define prioridade de 15 segundos
    final priorityWindow = DateTime.now().add(const Duration(seconds: AppConstants.favoritePrioritySeconds));
    final rideWithPriority = RideModel(
      id: ride.id.isEmpty ? 'ride-${DateTime.now().millisecondsSinceEpoch}' : ride.id,
      passengerId: ride.passengerId,
      passengerName: _mockCurrentUser?.fullName ?? 'Carlos Mendes',
      passengerPhone: _mockCurrentUser?.phone ?? '(11) 98765-4321',
      status: 'requested',
      originAddress: ride.originAddress,
      originLat: ride.originLat,
      originLng: ride.originLng,
      destinationAddress: ride.destinationAddress,
      destinationLat: ride.destinationLat,
      destinationLng: ride.destinationLng,
      distanceKm: ride.distanceKm,
      estimatedDurationMin: ride.estimatedDurationMin,
      estimatedFare: ride.estimatedFare,
      paymentMethod: ride.paymentMethod,
      priorityUntil: priorityWindow,
      favoriteDriverNotified: true,
      createdAt: DateTime.now(),
    );

    if (_isLive) {
      try {
        final res = await client.from('rides').insert(rideWithPriority.toJson()).select().single();
        return RideModel.fromJson(res);
      } catch (_) {}
    }

    _mockRides.add(rideWithPriority);
    _activeRideController.add(rideWithPriority);
    _pendingRidesController.add([rideWithPriority]);

    return rideWithPriority;
  }

  Stream<RideModel> streamRide(String rideId) {
    if (_isLive) {
      return client
          .from('rides')
          .stream(primaryKey: ['id'])
          .eq('id', rideId)
          .map((rows) => RideModel.fromJson(rows.first));
    }
    return _activeRideController.stream.where((r) => r.id == rideId);
  }

  Future<void> submitRating({
    required String rideId,
    required String passengerId,
    required String driverId,
    required int score,
    String? comment,
  }) async {
    if (_isLive) {
      try {
        await client.from('ratings').insert({
          'ride_id': rideId,
          'passenger_id': passengerId,
          'driver_id': driverId,
          'score': score,
          'comment': comment,
        });
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // DRIVER ACTIONS, REALTIME DISPATCH & SALDO VELIX
  // ---------------------------------------------------------------------------

  Future<DriverModel?> getDriverProfile(String driverId) async {
    if (_isLive) {
      try {
        final data = await client.from('drivers').select().eq('id', driverId).maybeSingle();
        if (data != null) return DriverModel.fromJson(data);
      } catch (_) {}

      final user = client.auth.currentUser;
      if (user != null && user.id == driverId) {
        final name = user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String? ??
            user.email?.split('@').first ??
            'Motorista Parceiro';
        final avatar = user.userMetadata?['avatar_url'] as String? ??
            user.userMetadata?['picture'] as String?;

        return DriverModel(
          id: user.id,
          fullName: name,
          phone: user.phone ?? '(11) 99887-1122',
          avatarUrl: avatar,
          cnhNumber: '12345678900',
          vehicleModel: 'Veículo Cadastrado',
          vehiclePlate: 'BRA2E19',
          vehicleColor: 'Prata',
          vehicleYear: '2024',
          isVerified: true,
          isOnline: false,
          currentBalance: 0.0,
          lastBilledAt: DateTime.now(),
          ratingAvg: 5.0,
          totalRides: 0,
        );
      }
    }
    return _mockDriver;
  }

  Future<void> registerDriver(DriverModel driver) async {
    if (_isLive) {
      try {
        await client.from('drivers').upsert(driver.toJson());
      } catch (_) {}
    }
    _mockDriver = driver;
  }

  Future<void> setDriverOnline(String driverId, bool isOnline) async {
    if (_isLive) {
      try {
        await client.from('drivers').update({'is_online': isOnline}).eq('id', driverId);
      } catch (_) {}
    }
    if (_mockDriver != null) {
      _mockDriver = _mockDriver!.copyWith(isOnline: isOnline);
    }
  }

  Future<void> updateDriverLocation(String driverId, LatLng pos, double heading) async {
    if (_isLive) {
      try {
        await client.from('driver_locations').upsert({
          'driver_id': driverId,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'heading': heading,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  Stream<List<RideModel>> streamPendingRidesForDriver(String driverId) {
    if (_isLive) {
      return client
          .from('rides')
          .stream(primaryKey: ['id'])
          .eq('status', 'requested')
          .map((list) => list.map((e) => RideModel.fromJson(e)).toList());
    }
    return _pendingRidesController.stream;
  }

  Future<void> acceptRide(String rideId, DriverModel driver) async {
    if (_isLive) {
      try {
        await client.from('rides').update({
          'driver_id': driver.id,
          'status': 'accepted',
        }).eq('id', rideId);
      } catch (_) {}
    }

    final index = _mockRides.indexWhere((r) => r.id == rideId);
    if (index != -1) {
      final updated = _mockRides[index].copyWith(
        status: 'accepted',
        driverId: driver.id,
        driverName: driver.fullName,
        driverPhone: driver.phone,
        driverVehicle: '${driver.vehicleModel} • ${driver.vehicleColor}',
        driverPlate: driver.vehiclePlate,
        driverRating: driver.ratingAvg,
      );
      _mockRides[index] = updated;
      _activeRideController.add(updated);
      _pendingRidesController.add([]);
    }
  }

  Future<void> updateRideStatus(String rideId, String newStatus, {double? actualFare}) async {
    if (_isLive) {
      try {
        final Map<String, dynamic> updateData = {'status': newStatus};
        if (actualFare != null) updateData['actual_fare'] = actualFare;
        await client.from('rides').update(updateData).eq('id', rideId);
      } catch (_) {}
    }

    final index = _mockRides.indexWhere((r) => r.id == rideId);
    if (index != -1) {
      final updated = _mockRides[index].copyWith(
        status: newStatus,
        actualFare: actualFare,
      );
      _mockRides[index] = updated;
      _activeRideController.add(updated);

      // Se concluiu a corrida, executa a regra de taxa R$ 0,50 e faturamento R$ 20 / 15 dias
      if (newStatus == 'completed' && _mockDriver != null) {
        _applyPlatformFeeToMockDriver();
      }
    }
  }

  // Regra automática de cobrança: R$ 0,50 por corrida, fatura se >= R$ 20,00 ou 15 dias
  void _applyPlatformFeeToMockDriver() {
    if (_mockDriver == null) return;

    final double newBalance = _mockDriver!.currentBalance + AppConstants.platformFeePerRide;
    final int newTotalRides = _mockDriver!.totalRides + 1;
    final int daysSinceLastBilled = DateTime.now().difference(_mockDriver!.lastBilledAt).inDays;

    if (newBalance >= AppConstants.autoInvoiceThreshold ||
        (daysSinceLastBilled >= AppConstants.autoInvoiceDaysLimit && newBalance > 0)) {
      // Gera nova fatura Pix
      final newInvoice = InvoiceModel(
        id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
        driverId: _mockDriver!.id,
        amount: newBalance,
        status: 'pending',
        pixCopyPaste: Formatters.generateMockPix(
          invoiceId: 'inv-${DateTime.now().millisecondsSinceEpoch}',
          amount: newBalance,
        ),
        dueDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
      );

      _mockInvoices.insert(0, newInvoice);

      // Reseta saldo
      _mockDriver = _mockDriver!.copyWith(
        currentBalance: 0.0,
        lastBilledAt: DateTime.now(),
        totalRides: newTotalRides,
      );
    } else {
      _mockDriver = _mockDriver!.copyWith(
        currentBalance: newBalance,
        totalRides: newTotalRides,
      );
    }
  }

  Future<List<InvoiceModel>> getDriverInvoices(String driverId) async {
    if (_isLive) {
      try {
        final res = await client
            .from('invoices')
            .select()
            .eq('driver_id', driverId)
            .order('created_at', ascending: false);
        return (res as List).map((e) => InvoiceModel.fromJson(e)).toList();
      } catch (_) {}
    }
    return List.from(_mockInvoices);
  }

  Future<void> payInvoicePix(String invoiceId) async {
    if (_isLive) {
      try {
        await client.from('invoices').update({
          'status': 'paid',
          'paid_at': DateTime.now().toIso8601String(),
        }).eq('id', invoiceId);
      } catch (_) {}
    }

    final index = _mockInvoices.indexWhere((inv) => inv.id == invoiceId);
    if (index != -1) {
      _mockInvoices[index] = _mockInvoices[index].copyWith(
        status: 'paid',
        paidAt: DateTime.now(),
      );
    }
  }

  Future<List<RideModel>> getRideHistory(String userId, {required bool isDriver}) async {
    if (_isLive) {
      try {
        final res = isDriver 
            ? await client.from('rides').select().eq('driver_id', userId).order('created_at', ascending: false)
            : await client.from('rides').select().eq('passenger_id', userId).order('created_at', ascending: false);
        return (res as List).map((e) => RideModel.fromJson(e)).toList();
      } catch (_) {}
    }
    return List.from(_mockRides);
  }
}
