/// Configuration centrale de l'API backend.
///
/// L'URL de base peut être surchargée au lancement :
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080
///
/// Valeurs typiques :
///  - Émulateur Android : http://10.0.2.2:8080  (défaut)
///  - Simulateur iOS    : http://localhost:8080
///  - Appareil physique : http://<IP_DE_VOTRE_PC>:8080
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String apiPrefix = '/api';

  /// Transforme un chemin relatif renvoyé par le backend
  /// (ex: /uploads/photos/xxx.jpg) en URL absolue affichable.
  static String resolveUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
