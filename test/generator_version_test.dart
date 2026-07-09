import 'dart:io';

import 'package:solana_idl_codegen/src/generator/generator_version.dart';
import 'package:test/test.dart';

void main() {
  test('generator version matches pubspec package version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([^\s]+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull);
    expect(solanaIdlGeneratorVersion, match!.group(1));
  });
}
