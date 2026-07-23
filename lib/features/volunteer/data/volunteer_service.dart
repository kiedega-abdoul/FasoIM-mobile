import '../../../core/network/api_client.dart';
import 'volunteer_models.dart';

class VolunteerService {
  VolunteerService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<VolunteerSession>> fetchOpenSessions() async {
    final payload = await _client.get(
      '/api/sessions/public/ouvertes-inscription/',
    );
    final values = _extractList(payload);

    return values
        .whereType<Map>()
        .map(
          (item) => VolunteerSession.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((session) => session.id > 0)
        .toList(growable: false);
  }

  Future<VolunteerApplicationCreated> submitApplication({
    required Map<String, Object?> data,
  }) async {
    final payload = await _client.post(
      '/api/immerges/public/volontaires/demandes/',
      body: data,
    );

    if (payload is! Map) {
      throw const ApiException('Le serveur a renvoyé une réponse invalide.');
    }

    return VolunteerApplicationCreated.fromJson(
      Map<String, dynamic>.from(payload),
    );
  }

  Future<VolunteerFollowUp> followApplication(String trackingCode) async {
    final payload = await _client.post(
      '/api/immerges/public/volontaires/suivi/',
      body: <String, Object?>{'code_suivi': trackingCode.trim().toUpperCase()},
    );

    if (payload is! Map) {
      throw const ApiException('Le serveur a renvoyé une réponse invalide.');
    }

    return VolunteerFollowUp.fromJson(Map<String, dynamic>.from(payload));
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final results = payload['results'];
      if (results is List) return results;
    }
    throw const ApiException(
      'Le serveur a renvoyé une liste de sessions invalide.',
    );
  }

  void close() => _client.close();
}
