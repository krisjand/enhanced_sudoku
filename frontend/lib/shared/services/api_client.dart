import 'package:dio/dio.dart';

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
    : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;

  void dispose() => _dio.close();

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
      final response = await _dio.get<Map<String, dynamic>>(path);
      final data = response.data;
      if (data == null)
        throw const ApiServerException(200, 'Empty response body');
      return fromJson(data);
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = response.data;
      if (data == null)
        throw const ApiServerException(200, 'Empty response body');
      return data;
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  Future<T> _postTyped<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final data = await _post(path, body);
    return fromJson(data);
  }

  Never _rethrow(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw ApiNetworkException(e.message ?? 'Network error');
    }
    final status = e.response?.statusCode ?? 0;
    if (status == 404) {
      throw ApiNotFoundException(e.response?.data?.toString() ?? 'Not found');
    }
    throw ApiServerException(
      status,
      e.response?.data?.toString() ?? 'Server error',
    );
  }
}
