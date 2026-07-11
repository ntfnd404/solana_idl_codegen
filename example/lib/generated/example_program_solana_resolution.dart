// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.1.0
// source-sha256: 2865113b5e9095b7a15ecca890930530f1875b9cd72df2cd2c81ac066ae07d80
// semantic-ir-sha256: 5a434b479f377019592da21c1dd21985819054fa8f3ddcca8908f25645f95fef
// SPDX-License-Identifier: MIT
/// Generated account resolution API for `example_program`.
library;

import 'dart:typed_data';
import 'example_program_solana_instructions.dart';
import 'example_program_solana_support.dart';
import 'example_program_solana_types.dart';

/// Tri-state override for one instruction account.
sealed class ExampleProgramAccountOverride {
  /// Creates an override state.
  const ExampleProgramAccountOverride();

  /// Uses IDL-driven resolution.
  const factory ExampleProgramAccountOverride.inherit() =
      ExampleProgramInheritAccountOverride;

  /// Uses an explicit address.
  const factory ExampleProgramAccountOverride.use(
    ExampleProgramAddress address,
  ) = ExampleProgramUseAccountOverride;

  /// Omits an IDL-optional account using the program sentinel.
  const factory ExampleProgramAccountOverride.absent() =
      ExampleProgramAbsentAccountOverride;
}

/// IDL-driven resolution without an explicit override.
final class ExampleProgramInheritAccountOverride
    extends ExampleProgramAccountOverride {
  /// Creates the inherit state.
  const ExampleProgramInheritAccountOverride();
}

/// Explicit account address override.
final class ExampleProgramUseAccountOverride
    extends ExampleProgramAccountOverride {
  /// Creates an explicit address state.
  const ExampleProgramUseAccountOverride(this.address);

  /// Explicit address.
  final ExampleProgramAddress address;
}

/// Explicit absence for an IDL-optional account.
final class ExampleProgramAbsentAccountOverride
    extends ExampleProgramAccountOverride {
  /// Creates the absent state.
  const ExampleProgramAbsentAccountOverride();
}

/// Dependencies supplied to generated account resolvers.
/// Relation/PDA cycles are runtime-resolvable when these dependencies break the cycle.
final class ExampleProgramResolutionContext {
  /// Creates a resolution context.
  ExampleProgramResolutionContext({
    this.identity,
    Set<String> identityAccountPaths = const {},
    this.accountReader,
    this.externalAccountSeedResolver,
    this.relationResolver,
    this.pdaDeriver,
    this.readOptions = const ExampleProgramAccountReadOptions(),
    this.decodeLimits = ExampleProgramDecodeLimits.defaults,
  }) : identityAccountPaths = Set.unmodifiable(identityAccountPaths);

  /// Optional application identity.
  final ExampleProgramAddress? identity;

  /// Account paths allowed to use [identity].
  final Set<String> identityAccountPaths;

  /// Optional account reader used by relation and account-data seeds.
  final ExampleProgramAccountReader? accountReader;

  /// Optional decoder for application-owned external account seeds.
  final ExampleProgramExternalAccountSeedResolver? externalAccountSeedResolver;

  /// Optional application relation resolver.
  final ExampleProgramRelationResolver? relationResolver;

  /// Optional canonical PDA deriver.
  final ExampleProgramPdaDeriver? pdaDeriver;

  /// Account read policy.
  final ExampleProgramAccountReadOptions readOptions;

  /// Decode limits.
  final ExampleProgramDecodeLimits decodeLimits;
}

/// One deterministic account-resolution failure.
final class ExampleProgramAccountResolutionCause {
  /// Creates a cause.
  const ExampleProgramAccountResolutionCause({
    required this.path,
    required this.code,
    required this.message,
  });

  /// Account path.
  final String path;

  /// Stable failure code.
  final String code;

  /// Human-readable explanation.
  final String message;
}

/// Aggregate account-resolution exception.
final class ExampleProgramAccountResolutionException implements Exception {
  /// Creates an exception and copies ordered causes.
  ExampleProgramAccountResolutionException(
    List<ExampleProgramAccountResolutionCause> causes,
  ) : causes = List.unmodifiable(causes);

  /// Ordered unresolved accounts and reasons.
  final List<ExampleProgramAccountResolutionCause> causes;

  @override
  String toString() =>
      'ExampleProgramAccountResolutionException: ${causes.length} unresolved account(s)';
}

/// Typed account overrides for `create_message`.
final class ExampleProgramCreateMessageAccountOverrides {
  /// Creates override states; every field inherits by default.
  const ExampleProgramCreateMessageAccountOverrides({
    this.authority = const ExampleProgramAccountOverride.inherit(),
    this.stateMessage = const ExampleProgramAccountOverride.inherit(),
    this.optionalReferrer = const ExampleProgramAccountOverride.inherit(),
    this.systemProgram = const ExampleProgramAccountOverride.inherit(),
  });

  /// Override for `authority`.
  final ExampleProgramAccountOverride authority;

  /// Override for `state_message`.
  final ExampleProgramAccountOverride stateMessage;

  /// Override for `optional_referrer`.
  final ExampleProgramAccountOverride optionalReferrer;

  /// Override for `system_program`.
  final ExampleProgramAccountOverride systemProgram;
}

/// Asynchronous resolver for `create_message` accounts.
final class ExampleProgramCreateMessageAccountResolver {
  /// Creates a resolver from injected capabilities.
  const ExampleProgramCreateMessageAccountResolver(this.context);

  /// Resolution dependencies.
  final ExampleProgramResolutionContext context;

  /// Resolves overrides, fixed addresses, identity, PDA, and relations.
  /// Precedence is use override, absent override, fixed address, identity, PDA, then relation.
  /// Relation/PDA cycles must be broken by use overrides, identity, or a relation resolver.
  Future<ExampleProgramCreateMessageAccounts> resolve({
    required ExampleProgramCreateMessageArgs args,
    ExampleProgramCreateMessageAccountOverrides overrides =
        const ExampleProgramCreateMessageAccountOverrides(),
  }) async {
    final causes = <ExampleProgramAccountResolutionCause>[];
    ExampleProgramAddress? authority;
    var authoritySuppressed = false;
    switch (overrides.authority) {
      case ExampleProgramUseAccountOverride(:final address):
        authority = address;
        authoritySuppressed = false;
      case ExampleProgramAbsentAccountOverride():
        authoritySuppressed = true;
        causes.add(
          const ExampleProgramAccountResolutionCause(
            path: 'authority',
            code: 'RESOLUTION_REQUIRED_ABSENT',
            message: 'Required account cannot be absent.',
          ),
        );
      case ExampleProgramInheritAccountOverride():
        authoritySuppressed = false;
        if (context.identityAccountPaths.contains('authority') &&
            context.identity != null) {
          authority = context.identity;
        }
    }
    ExampleProgramAddress? stateMessage;
    var stateMessageSuppressed = false;
    switch (overrides.stateMessage) {
      case ExampleProgramUseAccountOverride(:final address):
        stateMessage = address;
        stateMessageSuppressed = false;
      case ExampleProgramAbsentAccountOverride():
        stateMessageSuppressed = true;
        causes.add(
          const ExampleProgramAccountResolutionCause(
            path: 'state.message',
            code: 'RESOLUTION_REQUIRED_ABSENT',
            message: 'Required account cannot be absent.',
          ),
        );
      case ExampleProgramInheritAccountOverride():
        stateMessageSuppressed = false;
        if (context.identityAccountPaths.contains('state.message') &&
            context.identity != null) {
          stateMessage = context.identity;
        }
    }
    ExampleProgramAddress? optionalReferrer;
    switch (overrides.optionalReferrer) {
      case ExampleProgramUseAccountOverride(:final address):
        optionalReferrer = address;
      case ExampleProgramAbsentAccountOverride():
        optionalReferrer = null;
      case ExampleProgramInheritAccountOverride():
        if (context.identityAccountPaths.contains('optional_referrer') &&
            context.identity != null) {
          optionalReferrer = context.identity;
        }
    }
    ExampleProgramAddress? systemProgram;
    var systemProgramSuppressed = false;
    switch (overrides.systemProgram) {
      case ExampleProgramUseAccountOverride(:final address):
        systemProgram = address;
        systemProgramSuppressed = false;
      case ExampleProgramAbsentAccountOverride():
        systemProgramSuppressed = true;
        causes.add(
          const ExampleProgramAccountResolutionCause(
            path: 'system_program',
            code: 'RESOLUTION_REQUIRED_ABSENT',
            message: 'Required account cannot be absent.',
          ),
        );
      case ExampleProgramInheritAccountOverride():
        systemProgramSuppressed = false;
        systemProgram = ExampleProgramAddress.fromBase58(
          '11111111111111111111111111111111',
        );
    }
    for (var pass = 0; pass < 4; pass++) {
      var progressed = false;
      if (stateMessage == null && !stateMessageSuppressed) {
        final deriver = context.pdaDeriver;
        if (deriver != null) {
          final seeds = <Uint8List>[];
          seeds.add(
            Uint8List.fromList(<int>[109, 101, 115, 115, 97, 103, 101]),
          );
          final seedWriter1 = ExampleProgramBorshWriter();
          seedWriter1.writeUnsigned(args.id, 8);
          seeds.add(seedWriter1.takeBytes());
          for (var index = 0; index < seeds.length; index++) {
            if (seeds[index].length > 32) {
              throw ExampleProgramPdaException(
                code: 'PDA_SEED_LENGTH',
                message: 'A PDA seed cannot exceed 32 bytes.',
                seedIndex: index,
              );
            }
          }
          final derived = await deriver.derive(
            programAddress: ExampleProgramProgram.programAddress,
            seeds: seeds,
          );
          stateMessage = derived.address;
          progressed = true;
        }
      }
      if (stateMessage != null || stateMessageSuppressed) {
        break;
      }
      if (!progressed) {
        break;
      }
    }
    if (authority == null && !authoritySuppressed) {
      causes.add(
        const ExampleProgramAccountResolutionCause(
          path: 'authority',
          code: 'RESOLUTION_UNRESOLVED',
          message:
              'No override, fixed address, allowed identity, PDA, or relation resolved this account.',
        ),
      );
    }
    if (stateMessage == null && !stateMessageSuppressed) {
      causes.add(
        const ExampleProgramAccountResolutionCause(
          path: 'state.message',
          code: 'RESOLUTION_UNRESOLVED',
          message:
              'No override, fixed address, allowed identity, PDA, or relation resolved this account.',
        ),
      );
    }
    if (systemProgram == null && !systemProgramSuppressed) {
      causes.add(
        const ExampleProgramAccountResolutionCause(
          path: 'system_program',
          code: 'RESOLUTION_UNRESOLVED',
          message:
              'No override, fixed address, allowed identity, PDA, or relation resolved this account.',
        ),
      );
    }
    if (causes.isNotEmpty) {
      throw ExampleProgramAccountResolutionException(causes);
    }
    return ExampleProgramCreateMessageAccounts(
      authority: authority!,
      stateMessage: stateMessage!,
      optionalReferrer: optionalReferrer,
      systemProgram: systemProgram!,
    );
  }

  /// Resolves accounts and constructs an immutable instruction request.
  Future<ExampleProgramCreateMessageRequest> prepare({
    required ExampleProgramCreateMessageArgs args,
    ExampleProgramCreateMessageAccountOverrides overrides =
        const ExampleProgramCreateMessageAccountOverrides(),
    List<ExampleProgramAccountMeta> remainingAccounts = const [],
  }) async => ExampleProgramCreateMessageRequest(
    args: args,
    accounts: await resolve(args: args, overrides: overrides),
    remainingAccounts: remainingAccounts,
  );
}

/// Typed account overrides for `read_message`.
final class ExampleProgramReadMessageAccountOverrides {
  /// Creates override states; every field inherits by default.
  const ExampleProgramReadMessageAccountOverrides({
    this.message = const ExampleProgramAccountOverride.inherit(),
  });

  /// Override for `message`.
  final ExampleProgramAccountOverride message;
}

/// Asynchronous resolver for `read_message` accounts.
final class ExampleProgramReadMessageAccountResolver {
  /// Creates a resolver from injected capabilities.
  const ExampleProgramReadMessageAccountResolver(this.context);

  /// Resolution dependencies.
  final ExampleProgramResolutionContext context;

  /// Resolves overrides, fixed addresses, identity, PDA, and relations.
  /// Precedence is use override, absent override, fixed address, identity, PDA, then relation.
  /// Relation/PDA cycles must be broken by use overrides, identity, or a relation resolver.
  Future<ExampleProgramReadMessageAccounts> resolve({
    required ExampleProgramReadMessageArgs args,
    ExampleProgramReadMessageAccountOverrides overrides =
        const ExampleProgramReadMessageAccountOverrides(),
  }) async {
    final causes = <ExampleProgramAccountResolutionCause>[];
    ExampleProgramAddress? message;
    var messageSuppressed = false;
    switch (overrides.message) {
      case ExampleProgramUseAccountOverride(:final address):
        message = address;
        messageSuppressed = false;
      case ExampleProgramAbsentAccountOverride():
        messageSuppressed = true;
        causes.add(
          const ExampleProgramAccountResolutionCause(
            path: 'message',
            code: 'RESOLUTION_REQUIRED_ABSENT',
            message: 'Required account cannot be absent.',
          ),
        );
      case ExampleProgramInheritAccountOverride():
        messageSuppressed = false;
        if (context.identityAccountPaths.contains('message') &&
            context.identity != null) {
          message = context.identity;
        }
    }
    if (message == null && !messageSuppressed) {
      causes.add(
        const ExampleProgramAccountResolutionCause(
          path: 'message',
          code: 'RESOLUTION_UNRESOLVED',
          message:
              'No override, fixed address, allowed identity, PDA, or relation resolved this account.',
        ),
      );
    }
    if (causes.isNotEmpty) {
      throw ExampleProgramAccountResolutionException(causes);
    }
    return ExampleProgramReadMessageAccounts(message: message!);
  }

  /// Resolves accounts and constructs an immutable instruction request.
  Future<ExampleProgramReadMessageRequest> prepare({
    required ExampleProgramReadMessageArgs args,
    ExampleProgramReadMessageAccountOverrides overrides =
        const ExampleProgramReadMessageAccountOverrides(),
    List<ExampleProgramAccountMeta> remainingAccounts = const [],
  }) async => ExampleProgramReadMessageRequest(
    args: args,
    accounts: await resolve(args: args, overrides: overrides),
    remainingAccounts: remainingAccounts,
  );
}
