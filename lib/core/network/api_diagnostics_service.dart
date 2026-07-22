import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';

enum ApiProbeState { operational, reachableValidation, protected, missing, serverError, networkError }

class ApiProbeDefinition {
  const ApiProbeDefinition({required this.name, required this.method, required this.path, this.body, this.description = ''});
  final String name;
  final String method;
  final String path;
  final Map<String, Object?>? body;
  final String description;
}

class ApiProbeResult {
  const ApiProbeResult({required this.definition, required this.state, required this.message, this.statusCode, this.responsePreview = '', this.duration = Duration.zero});
  final ApiProbeDefinition definition;
  final ApiProbeState state;
  final String message;
  final int? statusCode;
  final String responsePreview;
  final Duration duration;

  bool get isUsable => state == ApiProbeState.operational || state == ApiProbeState.reachableValidation;
}

class ApiDiagnosticsService {
  ApiDiagnosticsService({HttpClient? client}) : _client = client ?? HttpClient() {
    _client.connectionTimeout = ApiConfig.connectTimeout;
  }

  final HttpClient _client;

  static const probes = <ApiProbeDefinition>[
    ApiProbeDefinition(name: 'Serveur FasoIM', method: 'GET', path: '/', description: 'Vérifie que Django répond.'),
    ApiProbeDefinition(name: 'Sessions ouvertes', method: 'GET', path: '/api/sessions/public/ouvertes-inscription/', description: 'Sessions volontaires ouvertes.'),
    ApiProbeDefinition(name: 'Soumission volontaire', method: 'POST', path: '/api/immerges/public/volontaires/demandes/', body: <String, Object?>{}, description: 'Test vide sans création de demande.'),
    ApiProbeDefinition(name: 'Suivi volontaire', method: 'POST', path: '/api/immerges/public/volontaires/suivi/', body: <String, Object?>{}, description: 'Route publique du code de suivi.'),
    ApiProbeDefinition(name: 'Informations d’arrivée', method: 'POST', path: '/api/documents/public/arrivee/', body: <String, Object?>{}, description: 'Consultation publique avant arrivée.'),
    ApiProbeDefinition(name: 'Consultation d’attestation', method: 'POST', path: '/api/documents/public/attestations/consulter/', body: <String, Object?>{}, description: 'Recherche d’une attestation.'),
    ApiProbeDefinition(name: 'Vérification d’attestation', method: 'POST', path: '/api/documents/public/attestations/verifier/', body: <String, Object?>{}, description: 'Contrôle par code ou numéro.'),
    ApiProbeDefinition(name: 'Authentification acteurs', method: 'POST', path: '/api/auth/token/', body: <String, Object?>{}, description: 'JWT des acteurs internes.'),
    ApiProbeDefinition(name: 'Documentation API', method: 'GET', path: '/api/docs/', description: 'Documentation Swagger.'),
  ];

  Future<List<ApiProbeResult>> runAll() async {
    final results = <ApiProbeResult>[];
    for (final probe in probes) {
      results.add(await run(probe));
    }
    return results;
  }

  Future<ApiProbeResult> run(ApiProbeDefinition definition) async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = await _client.openUrl(definition.method, ApiConfig.uri(definition.path)).timeout(ApiConfig.connectTimeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (definition.body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(definition.body));
      }
      final response = await request.close().timeout(ApiConfig.receiveTimeout);
      final body = await utf8.decoder.bind(response).join();
      stopwatch.stop();
      return ApiProbeResult(
        definition: definition,
        state: _stateFor(response.statusCode),
        message: _messageFor(response.statusCode),
        statusCode: response.statusCode,
        responsePreview: _preview(body),
        duration: stopwatch.elapsed,
      );
    } on TimeoutException {
      stopwatch.stop();
      return ApiProbeResult(definition: definition, state: ApiProbeState.networkError, message: 'Délai dépassé. Vérifiez l’IP, le réseau et le port 8000.', duration: stopwatch.elapsed);
    } on SocketException catch (error) {
      stopwatch.stop();
      return ApiProbeResult(definition: definition, state: ApiProbeState.networkError, message: 'Serveur inaccessible : ${error.message}', duration: stopwatch.elapsed);
    } catch (error) {
      stopwatch.stop();
      return ApiProbeResult(definition: definition, state: ApiProbeState.networkError, message: 'Échec du test : $error', duration: stopwatch.elapsed);
    }
  }

  ApiProbeState _stateFor(int code) {
    if (code >= 200 && code < 300) return ApiProbeState.operational;
    if (code == 400 || code == 405 || code == 422) return ApiProbeState.reachableValidation;
    if (code == 401 || code == 403) return ApiProbeState.protected;
    if (code == 404) return ApiProbeState.missing;
    return ApiProbeState.serverError;
  }

  String _messageFor(int code) {
    if (code >= 200 && code < 300) return 'Opérationnel';
    if (code == 400 || code == 422) return 'Route disponible, données valides requises';
    if (code == 405) return 'Route disponible, méthode refusée';
    if (code == 401 || code == 403) return 'Route protégée';
    if (code == 404) return 'Route introuvable';
    if (code >= 500) return 'Erreur du backend';
    return 'Réponse HTTP inattendue';
  }

  String _preview(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return compact.length <= 220 ? compact : '${compact.substring(0, 220)}…';
  }

  void close() => _client.close(force: true);
}
