import '../../../core/network/api_client.dart';
import 'certificate_models.dart';

class CertificateService {
  CertificateService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<CertificateVerification> verify(String value) async {
    final normalized = value.trim();
    final body = normalized.toUpperCase().startsWith('ATT-')
        ? <String, Object?>{'numero': normalized}
        : <String, Object?>{'code': normalized};

    final payload = await _client.post(
      '/api/documents/public/attestations/verifier/',
      body: body,
    );

    if (payload is! Map) {
      throw const ApiException(
        'Le serveur a renvoyé une vérification invalide.',
      );
    }

    return CertificateVerification.fromJson(Map<String, dynamic>.from(payload));
  }

  Future<CertificateConsultation> consultByFasoImCode(String code) async {
    final payload = await _client.post(
      '/api/documents/public/attestations/consulter/',
      body: <String, Object?>{'code_fasoim': code.trim()},
    );

    if (payload is! Map) {
      throw const ApiException(
        'Le serveur a renvoyé une consultation invalide.',
      );
    }

    return CertificateConsultation.fromJson(Map<String, dynamic>.from(payload));
  }

  void close() => _client.close();
}
