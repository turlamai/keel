# Keel maintainer agent contract

## Positioning

Keel is the transport-neutral application contract for the family's desktop
runtimes: one value model, one canonical byte encoding, one structured-error
shape, one lifecycle vocabulary, one transport-neutral schema vocabulary, and
one compatibility corpus. It depends on nothing beyond `base`. It does not
own UI controls, transport frames, process embedding, HTTP, WebView
messaging, or platform policy: Rivet keeps RVT1 and its native hosts, Glaze
keeps GLZ1 and its WebView adapters. Consumers must reference published
`keel` catalog packages; vendoring or copying sources is not consumption.

## Normative text and compatibility

`docs/contract-v1.md` is normative for the wire contract and schema
vocabulary. The package version and the contract version are governed
separately: the package follows Semantic Versioning once released, contract
compatibility follows the rules in `docs/contract-v1.md`. Every wire or
normative semantic change updates the normative text, the golden corpus or
vectors, and `CHANGELOG.md` in the same change. Never weaken canonical
encoding checks (key ordering, duplicate-key rejection, size/depth/node
budgets) without an explicit contract-version decision.

## Source map

- `keel/`: the library (values, encoding, errors, schemas)
- `tests/`: behavior and rejection tests, golden corpus
- `docs/`: normative contract text
- `site/`: keel.jrtx.site contract homepage

## Required validation

```bash
raco test -p keel
raco setup --doc-index --check-pkg-deps --pkgs keel
```

CI runs both on ubuntu/macos/windows across Racket 9.0 and 9.3. Run the
narrowest relevant tests locally and rely on CI before merging.

## Family contracts

The canonical five-repository dependency graph, ownership table, change
routing, release order, and trust boundaries live in
[`docs/family-architecture.md`](docs/family-architecture.md). Read it before
changing a boundary shared with Rivet, Glaze, Permit, Commerce, or a product;
do not restate its portfolio rules here.

Consumers: Rivet and Glaze, each declaring a `keel` `#:version` floor equal
to the lowest version their suites actually cover. After tagging a release,
trigger the downstream compatibility suites the same day so contract changes
are validated against consumers immediately instead of at their next update:

```bash
gh workflow run family-compat.yml -R turinglambdaai/rivet
gh workflow run family-compat.yml -R turinglambdaai/glaze
```

A red downstream run outranks new work: fix forward with a patch release or
coordinate a floor bump, and keep `main` green on both sides.

## Handoff standard

Leave the repository understandable without chat history: a completed change
ships code, tests, normative text when semantics change, and a CHANGELOG
entry. Never edit an existing golden vector silently (see CONTRIBUTING.md).
Do not claim compatibility from unit tests alone; record the Racket versions
and platforms actually exercised. Treat repository state as the
agent-to-agent handoff.

## Portfolio placement

This is open-source infrastructure under the repository's existing LICENSE, not a product paywall or pricing authority. Portfolio decisions live in [PORTFOLIO](https://github.com/turlamai/turlamai.github.io/blob/master/PORTFOLIO.md); product-specific commercial rules stay in the product repository.

## Product delivery coordination

The [family delivery standard](https://github.com/turlamai/turlamai.github.io/blob/master/docs/PRODUCT-STANDARD.md) governs evidence and product handoff.
Keep the implementation queue in `docs/family-architecture.md` and preserve this library's domain
boundary. Products own interaction meaning, commercial policy and user data;
do not add those policies to a framework facade.

## Documentation languages

Default public entry points and technical references are English. Maintain complete Chinese README/getting-started user paths with reciprocal links; preserve commands, API names and protocol semantics. Update both languages when a public user path changes. Technical references remain one normative source; Chinese guides explain and link to them. Follow the [family language policy](https://github.com/turlamai/turlamai.github.io/blob/master/docs/DOCUMENTATION-LANGUAGES.md). Historical internal notes need not all be translated.
