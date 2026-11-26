# Shared update validation primitives

`keel/update-contract` is an opt-in, transport-neutral validation module for future common update manifests. It is not a new wire format and does not change the existing Keel value contract or either consumer's signed manifest v1.

- `update-version-range? version minimum previous`: all supplied versions must be strict SemVer; minimum and any previous version must precede version. `#f` means no previous version; build metadata does not affect precedence.
- `update-artifact-sha256? value`: exactly 64 ASCII hexadecimal characters, either case.
- `update-artifact-size? value`: exact positive integer, in bytes.
- `update-artifact-identity? value`: a four-element list of nonempty platform, architecture and installer strings, plus a nonempty component string or `#f` for absent component. Identities compare by string content, case-sensitively. Consumers own supported identity vocabularies.
- `unique-update-artifact-identities? values`: nonempty list of valid identities, without duplicates; different components distinguish otherwise identical artifacts.

These predicates do not establish authenticity, verify signatures, decode JSON, validate URLs, choose release channels, authorize rollback or install software. Rivet and Glaze retain their legacy v1 adapters. Glaze v1 currently accepts zero-byte artifacts and does not require strict version ranges; do not silently substitute these stricter predicates in an existing v1 reader. Any future common wire version needs explicit negotiation, signed fixtures and downstream acceptance before rollout.

## Normalized records

`keel/update-manifest` provides guarded `update-artifact` and `update-manifest` structs. Artifact fields are platform, architecture, URL, SHA-256, size, installer, arguments, component and signature. The last two are independently optional (`#f`); the signature is opaque nonempty text, not evidence of authenticity. Manifest fields are application ID, version, build, channel, publication timestamp, minimum version, previous version, rollback permission, rollout percentage and artifacts. Build is positive; rollout is an exact integer in 0..100. All strings are immutable snapshots and SHA-256 is normalized to lowercase. Artifact lists must be nonempty with unique component-aware identities.

URL, timestamp and channel are nonempty strings only: adapters own syntax and policy validation, signature verification and installation authorization. Construction alone never authorizes an update. The normalized model is not a serialized schema or a replacement for legacy v1 readers; consumers must preserve the original signed bytes and apply their own legacy validation before conversion. A zero-size legacy artifact cannot be converted into this stricter model without an explicit migration decision.
