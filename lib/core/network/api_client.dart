import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({HttpClient? client}) : _client = client ?? HttpClient() {
    _client.connectionTimeout = ApiConfig.connectTimeout;
  }

  final HttpClient _client;

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, {Map<String, Object?>? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    try {
      final request = await _client
          .openUrl(method, ApiConfig.uri(path))
          .timeout(ApiConfig.connectTimeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(ApiConfig.receiveTimeout);
      final rawBody = await utf8.decoder.bind(response).join();
      final decoded = _decode(rawBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _extractError(decoded, response.statusCode),
          statusCode: response.statusCode,
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Le serveur met trop de temps à répondre. Vérifiez la connexion USB et le backend.',
      );
    } on SocketException catch (error) {
      throw ApiException('Serveur FasoIM inaccessible : ${error.message}');
    } on FormatException {
      throw const ApiException('Le serveur a renvoyé une réponse invalide.');
    } catch (error) {
      throw ApiException('Erreur de communication avec FasoIM : $error');
    }
  }

  dynamic _decode(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return jsonDecode(trimmed);
  }

  String _extractError(dynamic payload, int statusCode) {
    if (payload is Map<String, dynamic>) {
      for (final key in const [
        'detail',
        'message',
        'erreur',
        'error',
        'non_field_errors',
      ]) {
        final value = payload[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
        if (value is List && value.isNotEmpty) return value.join('\n');
      }

      final messages = <String>[];
      for (final entry in payload.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          messages.add('${entry.key} : ${value.join(', ')}');
        } else if (value is String && value.trim().isNotEmpty) {
          messages.add('${entry.key} : ${value.trim()}');
        }
      }
      if (messages.isNotEmpty) return messages.join('\n');
    }

    return 'La requête a échoué (HTTP $statusCode).';
  }

  void close() => _client.close(force: true);
}
