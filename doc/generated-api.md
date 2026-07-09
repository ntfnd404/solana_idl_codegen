# Generated API

## Values and Borsh

Models defensively copy lists and byte arrays. Public byte getters return
unmodifiable views. Equality is field-specific: bytes and lists are compared
element-by-element, nested values use their own equality, enum hashes include
the variant type, and `-0.0` hashes like `0.0`. NaN is rejected.

Every model exposes a program-prefixed Borsh codec. `decodeExact` rejects
trailing bytes; `decodePrefix` reports the consumed count. Account decoding
permits Anchor allocation padding by default and provides an exact variant.
Owner checks happen during fetch, not raw decoding.

## Instructions and resolution

Each instruction has typed args, resolved accounts, tri-state overrides,
resolver, request, and immutable instruction types. Override states are
`inherit`, `use(address)`, and `absent`; `absent` is valid only for IDL-optional
accounts and becomes the program-ID sentinel with signer/writable flags
cleared.

Resolution precedence is explicit override, optional absence, fixed address,
special deterministic metadata, allow-listed identity, PDA, relation, then an
aggregate unresolved error. PDA calculation is delegated to an injected
canonical deriver; generated code performs typed seed encoding and enforces
IDL seed limits.

Account-data seeds owned by the generated program use its typed account codec.
External account-data seeds use the generated
`<ProgramPrefix>ExternalAccountSeedResolver` port, leaving external owner and
codec policy in the application adapter.

`prepare` resolves accounts and creates a request. `instruction()` serializes
it. `toWire()` returns a structural record suitable for an application-owned
transaction layer or cross-program composition.

Example adapter shape:

```dart
final generated = request.instruction().toWire();

final appInstruction = AppInstruction(
  programId: appAddressFromBytes(generated.programAddress),
  accounts: [
    for (final account in generated.accounts)
      AppAccountMeta(
        address: appAddressFromBytes(account.address),
        isSigner: account.isSigner,
        isWritable: account.isWritable,
      ),
  ],
  data: generated.data,
);
```

Generated SDKs do not contain signer, wallet, blockhash, fee-payer,
transaction assembly, sending, confirmation, or pre/post-instruction policy.
Those are intentionally application-owned concerns.

## Accounts, views, events, and errors

Account clients preserve order and nullable missing positions. `null` means
only “account absent”; RPC, owner, discriminator, and decode failures remain
errors. Scanner filters are transport-neutral.

Views are emitted only for instructions with return values and no writable
account in their nested account tree. They simulate exactly one instruction,
verify the return program, and decode the return bytes exactly.

Event decoding maintains a program invocation stack and accepts `Program
data:` only in the target program frame. Malformed payloads become recoverable
notifications; transport failures remain stream errors. Typed subscriptions
expose idempotent `close()`.

Program exceptions retain numeric code, optional IDL metadata, typed origin,
compared values, raw logs, signature, and neutral transaction failure. Unknown
and framework codes remain representable without embedding a
version-sensitive framework catalog.

An RPC adapter can keep transport policy local and call the generated parser
only after it has logs or a custom error payload:

```dart
try {
  await transactionSender.send(appTransaction);
} on AppRpcFailure catch (failure) {
  throw <ProgramPrefix>Errors.parseLogs(
    logs: failure.logs,
    signature: failure.signature,
    transactionFailure: failure.neutralFailure,
  );
}
```

## Imports and portability

Generated SDKs import only `dart:*` and neighboring generated files. They do
not import `package:solana_idl_codegen`, `package:solana`, Node, Anchor, RPC,
wallet, or Borsh packages. This keeps generated code usable from Dart VM,
Flutter mobile/desktop, and web consumers.
