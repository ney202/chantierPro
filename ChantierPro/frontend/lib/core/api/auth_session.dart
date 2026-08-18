import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/utilisateur.dart';

/// Session utilisateur (token JWT + infos du compte connecté).
/// Persistée dans SharedPreferences pour rester connecté
/// entre deux lancements de l'application.
class AuthSession extends ChangeNotifier {
  static final AuthSession _instance = AuthSession._internal();
  factory AuthSession() => _instance;
  AuthSession._internal();

  String? _token;
  Utilisateur? _user;

  String? get token => _token;
  Utilisateur? get user => _user;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final id = prefs.getInt('user_id');
    if (id != null) {
      _user = Utilisateur(
        id: id,
        nom: prefs.getString('user_nom') ?? '',
        email: prefs.getString('user_email') ?? '',
        telephone: prefs.getString('user_telephone'),
        role: prefs.getString('user_role') ?? 'CHEF_CHANTIER',
      );
    }
  }

  Future<void> save({required String token, required Utilisateur user}) async {
    _token = token;
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_nom', user.nom);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role);
    if (user.telephone != null) {
      await prefs.setString('user_telephone', user.telephone!);
    }
    notifyListeners();
  }

  Future<void> updateUser(Utilisateur user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_nom', user.nom);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role);
    if (user.telephone != null) {
      await prefs.setString('user_telephone', user.telephone!);
    }
    notifyListeners();
  }

  Future<void> clear() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_nom');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('user_telephone');
    notifyListeners();
  }
}
