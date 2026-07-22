/// Configuration centrale de l'API FasoIM.
///
/// Par défaut, l'application contacte le backend du binôme sur le réseau local.
/// L'adresse peut être remplacée au lancement sans modifier le code :
/// flutter run --dart-define=FASOIM_API_BASE_URL=http://AUTRE_IP:8000
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'FASOIM_API_BASE_URL',
    defaultValue: 'http://10.17.132.51:8000',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static Uri uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }
}
