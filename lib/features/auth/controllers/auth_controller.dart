import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/supabase_service.dart';

class AuthController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _supabaseService.getCurrentUser();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _supabaseService.signInWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Falha no login: verifique suas credenciais.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithSocial(String provider) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _supabaseService.signInSocial(provider, redirectScheme: 'com.velixgo.driver');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Falha ao conectar com $provider.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _supabaseService.signUpWithEmail(email, password, name);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Falha no cadastro.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> selectRole(String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.updateRole(role);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(role: role);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _supabaseService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
