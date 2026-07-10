import 'package:solana_idl_codegen/src/idl_path_matcher.dart';
import 'package:test/test.dart';

void main() {
  group('IdlPathMatcher', () {
    test('matches camelCase and snake_case segments', () {
      expect(IdlPathMatcher.canonicalSegment('fooBar'), 'foo_bar');
      expect(IdlPathMatcher.segmentsMatch('fooBar', 'foo_bar'), isTrue);
      expect(IdlPathMatcher.segmentsMatch('fooBar', 'fooBaz'), isFalse);
    });

    test('matches dotted paths segment by segment', () {
      expect(
        IdlPathMatcher.canonicalPath('groupState.adminKey'),
        'group_state.admin_key',
      );
      expect(
        IdlPathMatcher.pathsMatch(
          'groupState.adminKey',
          'group_state.admin_key',
        ),
        isTrue,
      );
      expect(
        IdlPathMatcher.pathsMatch(
          'groupState.adminKey',
          'group_state.owner_key',
        ),
        isFalse,
      );
    });

    test('detects canonical dotted prefixes', () {
      expect(
        IdlPathMatcher.pathHasPrefix(
          'group_state.admin_key.value',
          'groupState.adminKey',
        ),
        isTrue,
      );
      expect(
        IdlPathMatcher.pathHasPrefix('group_state', 'groupState.adminKey'),
        isFalse,
      );
      expect(
        IdlPathMatcher.pathHasPrefix(
          'group_state.admin_key',
          'groupState.adminKey',
        ),
        isFalse,
      );
    });

    test('returns the longest canonical prefix', () {
      expect(
        IdlPathMatcher.longestPathPrefix('group_state.admin_key.value', [
          'groupState',
          'groupState.adminKey',
        ]),
        'groupState.adminKey',
      );
      expect(
        IdlPathMatcher.longestPathPrefix('group_state.admin_key', [
          'groupState',
          'groupState.adminKey',
        ]),
        'groupState.adminKey',
      );
    });
  });
}
