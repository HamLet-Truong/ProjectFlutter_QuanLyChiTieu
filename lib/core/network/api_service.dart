import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class ApiService {
  static const _tokenKey = 'api_auth_token';
  static const Duration _requestTimeout = Duration(seconds: 4);

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (withAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('${ApiConfig.baseUrl}/$cleanPath').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool withAuth = true}) async {
    final uri = _uri(path, query);
    try {
      final response = await http
          .get(
            uri,
            headers: await _headers(withAuth: withAuth),
          )
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      _debugLog('GET timeout', uri);
      throw Exception('Request timeout');
    } catch (e) {
      _debugLog('GET failed: $e', uri);
      rethrow;
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool withAuth = true}) async {
    final uri = _uri(path);
    try {
      final response = await http
          .post(
            uri,
            headers: await _headers(withAuth: withAuth),
            body: jsonEncode(body ?? {}),
          )
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      _debugLog('POST timeout', uri);
      throw Exception('Request timeout');
    } catch (e) {
      _debugLog('POST failed: $e', uri);
      rethrow;
    }
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body, bool withAuth = true}) async {
    final uri = _uri(path);
    try {
      final response = await http
          .put(
            uri,
            headers: await _headers(withAuth: withAuth),
            body: jsonEncode(body ?? {}),
          )
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      _debugLog('PUT timeout', uri);
      throw Exception('Request timeout');
    } catch (e) {
      _debugLog('PUT failed: $e', uri);
      rethrow;
    }
  }

  Future<dynamic> delete(String path, {bool withAuth = true}) async {
    final uri = _uri(path);
    try {
      final response = await http
          .delete(
            uri,
            headers: await _headers(withAuth: withAuth),
          )
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      _debugLog('DELETE timeout', uri);
      throw Exception('Request timeout');
    } catch (e) {
      _debugLog('DELETE failed: $e', uri);
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body is Map<String, dynamic> ? body['message'] : 'API request failed';
    throw Exception(message ?? 'API request failed');
  }

  void _debugLog(String message, Uri uri) {
    if (kDebugMode) {
      debugPrint('[ApiService] $message -> $uri');
    }
  }
}
