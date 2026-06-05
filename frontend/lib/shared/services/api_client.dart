import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/puzzle.dart';
import '../models/solve_result.dart';
import '../models/solve_step.dart';

class ApiNetworkException implements Exception {
  const ApiNetworkException(this.message);
  final String message;
  @override
  String toString() => 'ApiNetworkException: $message';
}

class ApiServerException implements Exception {
  const ApiServerException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'ApiServerException($statusCode): $message';
}

class ApiNotFoundException implements Exception {
  const ApiNotFoundException(this.message);
  final String message;
  @override
  String toString() => 'ApiNotFoundException: $message';
}

class HintResult {
  const HintResult({this.step, this.solved = false, this.stuck = false});
  final SolveStep? step;
  final bool solved;
  final bool stuck;
}

class ApiClient {
  ApiClient({required String baseUrl})
    : _baseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl,
      _client = http.Client();

  final String _baseUrl;
  final http.Client _client;

  void dispose() => _client.close();

  Future<Puzzle> fetchPuzzle() => _get('/puzzle', Puzzle.fromJson);

  Future<HintResult> getHint(
    List<List<int>> grid, {
    List<List<List<int>>>? candidates,
  }) async {
    final body = <String, dynamic>{'grid': grid};
    if (candidates != null) body['candidates'] = candidates;
    final data = await _post('/puzzle/hint', body);
    if (data['solved'] == true) return const HintResult(solved: true);
    if (data['stuck'] == true) return const HintResult(stuck: true);
    return HintResult(
      step: SolveStep.fromJson(data['step'] as Map<String, dynamic>),
    );
  }

  Future<SolveResult> solvePuzzle(List<List<int>> grid) =>
      _postTyped('/puzzle/solve', {'puzzle': grid}, SolveResult.fromJson);

  Future<Puzzle> findPuzzle(String technique) =>
      _get('/puzzle/find?technique=$technique', Puzzle.fromJson);

  Future<T> _get<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl$path'));
      return fromJson(_parseResponse(response));
    } on http.ClientException catch (e) {
      throw ApiNetworkException(e.message);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _parseResponse(response);
    } on http.ClientException catch (e) {
      throw ApiNetworkException(e.message);
    }
  }

  Future<T> _postTyped<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async => fromJson(await _post(path, body));

  Map<String, dynamic> _parseResponse(http.Response response) {
    if (response.statusCode == 404) {
      throw ApiNotFoundException(response.body);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiServerException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiServerException(response.statusCode, 'Unexpected response type');
    }
    return decoded;
  }
}
