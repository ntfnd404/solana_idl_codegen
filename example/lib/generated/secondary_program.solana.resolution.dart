// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.1.0
// source-sha256: bfba19c124c33b827b5c139cc62b583f9c36aafb5951f72e02387a67705816a7
// semantic-ir-sha256: 116502c850c55b1b16510193442452e33c2161adb8e40f36a00d8c66826e6b0a
// SPDX-License-Identifier: MIT
// ignore_for_file: curly_braces_in_flow_control_structures, empty_constructor_bodies, prefer_initializing_formals, unused_element, unused_import, use_super_parameters

/// Generated account resolution API for `secondary_program`.
library;

import 'dart:convert';
import 'dart:typed_data';
import 'secondary_program.solana.accounts.dart';
import 'secondary_program.solana.instructions.dart';
import 'secondary_program.solana.support.dart';
import 'secondary_program.solana.types.dart';

/// Tri-state override for one instruction account.
sealed class SecondaryProgramAccountOverride {
  /// Creates an override state.
  const SecondaryProgramAccountOverride();

  /// Uses IDL-driven resolution.
  const factory SecondaryProgramAccountOverride.inherit() =
      SecondaryProgramInheritAccountOverride;

  /// Uses an explicit address.
  const factory SecondaryProgramAccountOverride.use(
    SecondaryProgramAddress address,
  ) = SecondaryProgramUseAccountOverride;

  /// Omits an IDL-optional account using the program sentinel.
  const factory SecondaryProgramAccountOverride.absent() =
      SecondaryProgramAbsentAccountOverride;
}

/// IDL-driven resolution without an explicit override.
final class SecondaryProgramInheritAccountOverride
    extends SecondaryProgramAccountOverride {
  /// Creates the inherit state.
  const SecondaryProgramInheritAccountOverride();
}

/// Explicit account address override.
final class SecondaryProgramUseAccountOverride
    extends SecondaryProgramAccountOverride {
  /// Creates an explicit address state.
  const SecondaryProgramUseAccountOverride(this.address);

  /// Explicit address.
  final SecondaryProgramAddress address;
}

/// Explicit absence for an IDL-optional account.
final class SecondaryProgramAbsentAccountOverride
    extends SecondaryProgramAccountOverride {
  /// Creates the absent state.
  const SecondaryProgramAbsentAccountOverride();
}

/// Dependencies supplied to generated account resolvers.
/// Relation/PDA cycles are runtime-resolvable when these dependencies break the cycle.
final class SecondaryProgramResolutionContext {
  /// Creates a resolution context.
  SecondaryProgramResolutionContext({
    this.identity,
    Set<String> identityAccountPaths = const {},
    this.accountReader,
    this.externalAccountSeedResolver,
    this.relationResolver,
    this.pdaDeriver,
    this.readOptions = const SecondaryProgramAccountReadOptions(),
    this.decodeLimits = SecondaryProgramDecodeLimits.defaults,
  }) : identityAccountPaths = Set.unmodifiable(identityAccountPaths);

  /// Optional application identity.
  final SecondaryProgramAddress? identity;

  /// Account paths allowed to use [identity].
  final Set<String> identityAccountPaths;

  /// Optional account reader used by relation and account-data seeds.
  final SecondaryProgramAccountReader? accountReader;

  /// Optional decoder for application-owned external account seeds.
  final SecondaryProgramExternalAccountSeedResolver?
  externalAccountSeedResolver;

  /// Optional application relation resolver.
  final SecondaryProgramRelationResolver? relationResolver;

  /// Optional canonical PDA deriver.
  final SecondaryProgramPdaDeriver? pdaDeriver;

  /// Account read policy.
  final SecondaryProgramAccountReadOptions readOptions;

  /// Decode limits.
  final SecondaryProgramDecodeLimits decodeLimits;
}

/// One deterministic account-resolution failure.
final class SecondaryProgramAccountResolutionCause {
  /// Creates a cause.
  const SecondaryProgramAccountResolutionCause({
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
final class SecondaryProgramAccountResolutionException implements Exception {
  /// Creates an exception and copies ordered causes.
  SecondaryProgramAccountResolutionException(
    List<SecondaryProgramAccountResolutionCause> causes,
  ) : causes = List.unmodifiable(causes);

  /// Ordered unresolved accounts and reasons.
  final List<SecondaryProgramAccountResolutionCause> causes;

  @override
  String toString() =>
      'SecondaryProgramAccountResolutionException: ${causes.length} unresolved account(s)';
}

/// Typed account overrides for `consume`.
final class SecondaryProgramConsumeAccountOverrides {
  /// Creates override states; every field inherits by default.
  const SecondaryProgramConsumeAccountOverrides({
    this.authority = const SecondaryProgramAccountOverride.inherit(),
  });

  /// Override for `authority`.
  final SecondaryProgramAccountOverride authority;
}

/// Asynchronous resolver for `consume` accounts.
final class SecondaryProgramConsumeAccountResolver {
  /// Creates a resolver from injected capabilities.
  const SecondaryProgramConsumeAccountResolver(this.context);

  /// Resolution dependencies.
  final SecondaryProgramResolutionContext context;

  /// Resolves overrides, fixed addresses, identity, PDA, and relations.
  /// Precedence is use override, absent override, fixed address, identity, PDA, then relation.
  /// Relation/PDA cycles must be broken by use overrides, identity, or a relation resolver.
  Future<SecondaryProgramConsumeAccounts> resolve({
    required SecondaryProgramConsumeArgs args,
    SecondaryProgramConsumeAccountOverrides overrides =
        const SecondaryProgramConsumeAccountOverrides(),
  }) async {
    final causes = <SecondaryProgramAccountResolutionCause>[];
    SecondaryProgramAddress? authority;
    var authoritySuppressed = false;
    switch (overrides.authority) {
      case SecondaryProgramUseAccountOverride(:final address):
        authority = address;
        authoritySuppressed = false;
      case SecondaryProgramAbsentAccountOverride():
        authoritySuppressed = true;
        causes.add(
          const SecondaryProgramAccountResolutionCause(
            path: 'authority',
            code: 'RESOLUTION_REQUIRED_ABSENT',
            message: 'Required account cannot be absent.',
          ),
        );
      case SecondaryProgramInheritAccountOverride():
        authoritySuppressed = false;
        if (context.identityAccountPaths.contains('authority') &&
            context.identity != null) {
          authority = context.identity;
        }
    }
    if (authority == null && !authoritySuppressed) {
      causes.add(
        const SecondaryProgramAccountResolutionCause(
          path: 'authority',
          code: 'RESOLUTION_UNRESOLVED',
          message:
              'No override, fixed address, allowed identity, PDA, or relation resolved this account.',
        ),
      );
    }
    if (causes.isNotEmpty) {
      throw SecondaryProgramAccountResolutionException(causes);
    }
    return SecondaryProgramConsumeAccounts(authority: authority!);
  }

  /// Resolves accounts and constructs an immutable instruction request.
  Future<SecondaryProgramConsumeRequest> prepare({
    required SecondaryProgramConsumeArgs args,
    SecondaryProgramConsumeAccountOverrides overrides =
        const SecondaryProgramConsumeAccountOverrides(),
    List<SecondaryProgramAccountMeta> remainingAccounts = const [],
  }) async => SecondaryProgramConsumeRequest(
    args: args,
    accounts: await resolve(args: args, overrides: overrides),
    remainingAccounts: remainingAccounts,
  );
}
