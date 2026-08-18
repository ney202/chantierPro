import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_session.dart';

/// Client HTTP unique de l'application.
/// Ajoute automatiquement le token JWT à chaque requête
/// et gère les erreurs de manière uniforme.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl + ApiConfig.apiPrefix,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        // Pas de Content-Type fixe ici : il est déterminé par requête
        // (voir interceptor ci-dessous), pour ne pas casser les uploads multipart.
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // JSON par défaut, SAUF si le corps est un FormData (upload de fichier).
          // Dans ce cas on laisse Dio définir lui-même
          // "multipart/form-data; boundary=..." automatiquement.
          if (options.data is! FormData) {
            options.headers['Content-Type'] = 'application/json';
          }

          final token = AuthSession().token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Token expiré ou invalide -> on nettoie la session.
          if (error.response?.statusCode == 401) {
            AuthSession().clear();
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Extrait un message d'erreur lisible depuis une exception Dio.
  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msg = data['message'] ?? data['error'];
        if (msg is String && msg.isNotEmpty) return msg;
        // Erreurs de validation Spring: {"champ": "message", ...}
        if (data.isNotEmpty) {
          final first = data.values.first;
          if (first is String && first.isNotEmpty) return first;
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Délai de connexion dépassé. Vérifiez que le serveur est démarré.';
        case DioExceptionType.connectionError:
          return 'Impossible de joindre le serveur (${ApiConfig.baseUrl}). '
              'Vérifiez le backend et votre réseau.';
        default:
          break;
      }
      final code = error.response?.statusCode;
      if (code == 401) return 'Email ou mot de passe incorrect.';
      if (code == 403) return 'Accès refusé pour votre rôle.';
      if (code == 404) return 'Ressource introuvable.';
      if (code != null) return 'Erreur serveur ($code).';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}
