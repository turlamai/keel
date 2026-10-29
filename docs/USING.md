# Keel adoption and support

**English** · [简体中文](USING.zh-CN.md)

## When to use it

Use Keel for transport-neutral values, canonical bytes, schemas and structured errors shared by runtimes. Most product developers should start with Rivet or Glaze rather than assemble a second application framework around Keel.

## Requirements and maturity

Racket 9.0+; base-only implementation. There is no GUI, network service, package installer or commercial account in this library. Consumers keep transport envelopes and platform behavior outside Keel.

## One useful verification

Encode then decode a small value, test rejection at your actual input boundary, and run the shared golden corpus for any independent implementation. Do not hand-copy the codec into a product. Package SemVer and wire-contract versions have separate ownership.

## Reading path

1. [First round trip](getting-started.md)
2. [Normative v1 contract](contract-v1.md)
3. [Family architecture](family-architecture.md)

Technical references retain one normative meaning. Chinese onboarding explains and links to that reference rather than creating a second protocol.

## Upgrades, data and support

Record the package versions and platforms your application actually tests. Read CHANGELOG and compatibility contracts before upgrading, test user-data migration on copies and retain a recoverable version. A library does not supply your product’s database backup, publisher identity, refunds, account recovery or privacy policy. Example customer/offer identifiers and amounts are fixtures, not live offers.

Use [Issues](https://github.com/turlamai/keel/issues) in English or Chinese. Include package/commit, Racket version, OS/architecture, a minimal reproduction and the first redacted error. Never attach real keys, customer credentials, raw payment data or private documents. Community support has no guaranteed response time.

[Private vulnerability reporting](../SECURITY.md).

[Current licence](../LICENSE) · [CHANGELOG](../CHANGELOG.md)
