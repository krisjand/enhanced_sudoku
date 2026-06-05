import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import 'settings_provider.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(settingsProvider).backendUrl;
  final client = ApiClient(baseUrl: baseUrl);
  ref.onDispose(client.dispose);
  return client;
});
