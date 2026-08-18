import 'api_client.dart';
import 'auth_session.dart';
import '../models/utilisateur.dart';

/// Appels vers /api/auth (login, register) + gestion de session.
class AuthService {
  final _client = ApiClient();

  Future<Utilisateur> login({
    required String email,
    required String motDePasse,
  }) async {
    final res = await _client.dio.post('/auth/login', data: {
      'email': email,
      'motDePasse': motDePasse,
    });
    return _handleAuthResponse(res.data);
  }

  Future<Utilisateur> register({
    required String nom,
    required String email,
    required String motDePasse,
    String? telephone,
    required String role, // ADMIN | CHEF_CHANTIER
  }) async {
    final res = await _client.dio.post('/auth/register', data: {
      'nom': nom,
      'email': email,
      'motDePasse': motDePasse,
      if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
      'role': role,
    });
    return _handleAuthResponse(res.data);
  }

  Future<Utilisateur> _handleAuthResponse(Map<String, dynamic> data) async {
    final user = Utilisateur(
      id: (data['id'] as num).toInt(),
      nom: data['nom'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'CHEF_CHANTIER',
    );
    await AuthSession().save(token: data['token'], user: user);
    return user;
  }

  /// GET /api/utilisateurs/me — profil complet (avec téléphone).
  Future<Utilisateur> getMe() async {
    final res = await _client.dio.get('/utilisateurs/me');
    final user = Utilisateur.fromJson(res.data);
    await AuthSession().updateUser(user);
    return user;
  }

  Future<void> logout() => AuthSession().clear();
}
