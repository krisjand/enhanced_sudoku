import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/utils/technique_names.dart';

void main() {
  group('techniqueDisplayName', () {
    test('known identifiers return display names', () {
      expect(techniqueDisplayName('nakedSingles'), 'Naked Singles');
      expect(techniqueDisplayName('hiddenSingleRow'), 'Hidden Single (Row)');
      expect(techniqueDisplayName('xWing'), 'X-Wing');
      expect(techniqueDisplayName('forcedChains'), 'Forced Chains');
    });

    test('unknown identifier falls back to the raw id', () {
      expect(techniqueDisplayName('unknownTechnique'), 'unknownTechnique');
    });
  });
}
