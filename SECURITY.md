# Security

`SECURITY.md` exists so users and maintainers have a clear responsible
disclosure path for parser, generated-runtime, and supply-chain issues.

## Supported versions

The currently supported pre-1.0 line is `0.1.x`.

## Reporting

Report sensitive vulnerabilities through the GitHub repository security
advisory or private vulnerability reporting flow when available:

<https://github.com/ntfnd404/solana_idl_codegen/security>

Do not publish private keys, wallet seed phrases, production IDLs containing
secrets, exploit details, or unpublished vulnerability details in public
issues. For non-sensitive hardening requests, use the public issue tracker.

## Security-sensitive areas

IDL input is untrusted. Changes affecting parser limits, allocation checks,
integer bounds, Borsh decoding, discriminators, PDA seeds, account/event logs,
generated support, or output ownership must include malformed-input or
regression tests.

Generated artifacts contain no timestamp or absolute path and are licensed for
consumer projects to commit without a runtime attribution dependency.
