import '../../../core/network/api_client.dart';
import 'consultation_models.dart';

class ConsultationService {
  ConsultationService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<ArrivalSession>> fetchSessions() async {
    final payload = await _client.get(
      '/api/sessions/public/consultables-arrivee/',
    );

    final values = _extractList(payload);
    return values
        .whereType<Map>()
        .map((item) => ArrivalSession.fromJson(Map<String, dynamic>.from(item)))
        .where((session) => session.id > 0)
        .toList(growable: false);
  }

  Future<ArrivalInformation> search({
    required ArrivalSession session,
    required String identifier,
    required String birthDate,
  }) async {
    final payload = await _client.post(
      '/api/documents/public/arrivee/',
      body: <String, Object?>{
        'type_immerge': session.typeImmerge,
        'identifiant': identifier.trim(),
        'session_code': session.code,
        'date_naissance': birthDate.trim(),
      },
    );

    if (payload is! Map) {
      throw const ApiException(
        'Le serveur a renvoyé des informations d’arrivée invalides.',
      );
    }

    return ArrivalInformation.fromJson(Map<String, dynamic>.from(payload));
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final results = payload['results'] ?? payload['data'];
      if (results is List) return results;
    }
    throw const ApiException(
      'Le serveur a renvoyé une liste de sessions invalide.',
    );
  }

  void close() => _client.close();
}
