import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/driver_model.dart';
import '../../../core/models/ride_model.dart';
import '../../../core/models/invoice_model.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/supabase_service.dart';

class DriverController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  DriverModel? _driverProfile;
  bool _isOnline = false;
  LatLng _currentLocation = const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
  double _heading = 0.0;
  int _currentSpeedKmH = 0;

  List<RideModel> _pendingRides = [];
  RideModel? _activeRide;
  List<InvoiceModel> _invoices = [];
  List<RideModel> _rideHistory = [];

  StreamSubscription<List<RideModel>>? _pendingRidesSub;
  StreamSubscription<RideModel>? _activeRideSub;
  StreamSubscription<Position>? _gpsStreamSub;
  Timer? _gpsTimer;

  bool _isLoading = false;
  String? _errorMessage;

  // Ganhos calculados
  double _earningsToday = 148.50;
  double _earningsWeek = 890.00;
  double _earningsMonth = 3450.00;

  // Getters
  DriverModel? get driverProfile => _driverProfile;
  bool get isOnline => _isOnline;
  LatLng get currentLocation => _currentLocation;
  double get heading => _heading;
  int get currentSpeedKmH => _currentSpeedKmH;
  List<RideModel> get pendingRides => _pendingRides;
  RideModel? get activeRide => _activeRide;
  List<InvoiceModel> get invoices => _invoices;
  List<RideModel> get rideHistory => _rideHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get earningsToday => _earningsToday;
  double get earningsWeek => _earningsWeek;
  double get earningsMonth => _earningsMonth;
  double get velixBalance => _driverProfile?.currentBalance ?? 0.0;
  bool get isCar => (_driverProfile?.vehicleType ?? 'car') == 'car';
  bool get isMotorcycle => (_driverProfile?.vehicleType ?? 'car') == 'motorcycle';
  String get vehicleType => _driverProfile?.vehicleType ?? 'car';

  // Fatura pendente que precisa de pagamento Pix imediato se houver
  InvoiceModel? get pendingInvoice {
    final list = _invoices.where((inv) => inv.isPending).toList();
    return list.isNotEmpty ? list.first : null;
  }

  Future<void> initialize(String driverId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentLocation = await LocationService.getCurrentLocation();
      _driverProfile = await _supabaseService.getDriverProfile(driverId);
      _isOnline = _driverProfile?.isOnline ?? false;
      _invoices = await _supabaseService.getDriverInvoices(driverId);
      _rideHistory = await _supabaseService.getRideHistory(driverId, isDriver: true);

      if (_isOnline) {
        _startListeningToPendingRides(driverId);
        _startGpsBroadcast(driverId);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerVehicle({
    required String driverId,
    required String fullName,
    required String phone,
    required String cnhNumber,
    required String vehicleType, // 'car' ou 'motorcycle'
    required String vehicleModel,
    required String vehiclePlate,
    required String vehicleColor,
    required String vehicleYear,
  }) async {
    _isLoading = true;
    notifyListeners();

    final driver = DriverModel(
      id: driverId,
      fullName: fullName,
      phone: phone,
      cnhNumber: cnhNumber,
      vehicleType: vehicleType,
      vehicleModel: vehicleModel,
      vehiclePlate: vehiclePlate,
      vehicleColor: vehicleColor,
      vehicleYear: vehicleYear,
      isVerified: true,
      lastBilledAt: DateTime.now(),
    );

    await _supabaseService.registerDriver(driver);
    _driverProfile = driver;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleOnline(String driverId) async {
    _isOnline = !_isOnline;
    await _supabaseService.setDriverOnline(driverId, _isOnline);

    if (_isOnline) {
      _startListeningToPendingRides(driverId);
      _startGpsBroadcast(driverId);
    } else {
      _stopListeningToPendingRides();
      _stopGpsBroadcast();
      _pendingRides = [];
    }

    notifyListeners();
  }

  Future<void> updateVehicleType(String driverId, String newType) async {
    if (_driverProfile != null) {
      _driverProfile = _driverProfile!.copyWith(vehicleType: newType);
    }
    await _supabaseService.updateDriverVehicleType(driverId, newType);
    if (_isOnline) {
      await _supabaseService.updateDriverLocation(
        driverId,
        _currentLocation,
        0.0,
        vehicleType: newType,
      );
    }
    notifyListeners();
  }

  void _startListeningToPendingRides(String driverId) {
    _pendingRidesSub?.cancel();
    _pendingRidesSub = _supabaseService.streamPendingRidesForDriver(driverId).listen((rides) {
      _pendingRides = rides;
      notifyListeners();
    });
  }

  void _stopListeningToPendingRides() {
    _pendingRidesSub?.cancel();
    _pendingRidesSub = null;
  }

  void _startGpsBroadcast(String driverId) {
    _gpsStreamSub?.cancel();
    _gpsTimer?.cancel();

    // 1. Atualização imediata da localização atual
    LocationService.getCurrentLocation().then((loc) {
      _currentLocation = loc;
      _supabaseService.updateDriverLocation(
        driverId,
        loc,
        0.0,
        vehicleType: _driverProfile?.vehicleType ?? 'car',
      );
      notifyListeners();
    });

    // 2. Transmissão contínua em tempo real conforme o motorista se desloca
    _gpsStreamSub = LocationService.getPositionStream().listen((pos) {
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      _heading = pos.heading;
      _currentSpeedKmH = (pos.speed > 0) ? (pos.speed * 3.6).round() : 0;
      _supabaseService.updateDriverLocation(
        driverId,
        _currentLocation,
        pos.heading,
        vehicleType: _driverProfile?.vehicleType ?? 'car',
      );
      notifyListeners();
    });
  }

  void _stopGpsBroadcast() {
    _gpsStreamSub?.cancel();
    _gpsStreamSub = null;
    _gpsTimer?.cancel();
    _gpsTimer = null;
  }

  Future<void> acceptRide(RideModel ride) async {
    if (_driverProfile == null) return;

    await _supabaseService.acceptRide(ride.id, _driverProfile!);
    _activeRide = ride.copyWith(
      status: 'accepted',
      driverId: _driverProfile!.id,
      driverName: _driverProfile!.fullName,
      driverPhone: _driverProfile!.phone,
      driverVehicle: '${_driverProfile!.vehicleModel} • ${_driverProfile!.vehicleColor}',
      driverPlate: _driverProfile!.vehiclePlate,
      driverRating: _driverProfile!.ratingAvg,
    );

    _pendingRides.removeWhere((r) => r.id == ride.id);
    _listenToActiveRide(ride.id);
    notifyListeners();
  }

  void declineRide(RideModel ride) {
    _pendingRides.removeWhere((r) => r.id == ride.id);
    notifyListeners();
  }

  void _listenToActiveRide(String rideId) {
    _activeRideSub?.cancel();
    _activeRideSub = _supabaseService.streamRide(rideId).listen((updated) {
      _activeRide = updated;
      notifyListeners();
    });
  }

  // Avança o fluxo: accepted -> arrived -> in_progress -> completed
  Future<void> advanceRideStatus() async {
    if (_activeRide == null) return;

    String nextStatus;
    switch (_activeRide!.status) {
      case 'accepted':
        nextStatus = 'arrived';
        break;
      case 'arrived':
        nextStatus = 'in_progress';
        break;
      case 'in_progress':
        nextStatus = 'completed';
        break;
      default:
        return;
    }

    await _supabaseService.updateRideStatus(
      _activeRide!.id,
      nextStatus,
      actualFare: nextStatus == 'completed' ? _activeRide!.estimatedFare : null,
    );

    if (nextStatus == 'completed') {
      _earningsToday += _activeRide!.estimatedFare;
      _earningsWeek += _activeRide!.estimatedFare;
      _earningsMonth += _activeRide!.estimatedFare;

      // Recarrega perfil com o novo saldo e faturas
      if (_driverProfile != null) {
        _driverProfile = await _supabaseService.getDriverProfile(_driverProfile!.id);
        _invoices = await _supabaseService.getDriverInvoices(_driverProfile!.id);
      }
      _activeRide = null;
      _activeRideSub?.cancel();
    } else {
      _activeRide = _activeRide!.copyWith(status: nextStatus);
    }

    notifyListeners();
  }

  Future<void> payInvoicePix(String invoiceId) async {
    _isLoading = true;
    notifyListeners();

    await _supabaseService.payInvoicePix(invoiceId);
    if (_driverProfile != null) {
      _invoices = await _supabaseService.getDriverInvoices(_driverProfile!.id);
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _pendingRidesSub?.cancel();
    _activeRideSub?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }
}
