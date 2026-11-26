# Shared update validation primitives

`keel/update-contract` is an opt-in, transport-neutral validation module for future common update manifests. It is not a new wire format and does not change the existing Keel value contract or either consumer's signed manifest v1.

- `update-version-range? version minimum previous`: all supplied versions must be strict SemVer; minimum and any previous version must precede version. `#f` means no previous version; build metadata does not affect precedence.
- `update-artifact-sha256? value`: exactly 64 ASCII hexadecimal characters, either case.
- `update-artifact-size? value`: exact positive integer, in bytes.
- `update-artifact-identity? value`: a four-element list of nonempty platform, architecture and installer strings, plus a nonempty component string or `#f` for absent component. Identities compare by string content, case-sensitively. Consumers own supported identity vocabularies.
- `unique-update-artifact-identities? values`: nonempty list of valid identities, without duplicates; different components distinguish otherwise identical artifacts.

These predicates do not establish authenticity, verify signatures, decode JSON, validate URLs, choose release channels, authorize rollback or install software. Rivet and Glaze retain their legacy v1 adapters. Glaze v1 currently accepts zero-byte artifacts and does not require strict version ranges; do not silently substitute these stricter predicates in an existing v1 reader. Any future common wire version needs explicit negotiation, signed fixtures and downstream acceptance before rollout.
