# Contributing

Keel is intentionally small. Changes should make independent Racket
desktop runtimes more interoperable without coupling their UI or transport
architectures.

Before opening a pull request:

1. Run `raco test -p keel` from a linked package installation.
2. Run `raco setup --doc-index --check-pkg-deps --pkgs keel`.
3. Update documentation and rejection tests with behavior changes.
4. Never edit an existing golden vector silently. Explain compatibility impact,
   add cross-runtime evidence, and state whether negotiation or a new contract
   version is required.

The `app-schema->app-value` shape is a compatibility surface too. Renaming a
key, changing declaration-order semantics, or reinterpreting an existing type
descriptor requires the same written version decision as changing value bytes.

Test module names are a packaging surface: the top-level `tests/` collection is
shared by every installed package, so two packages claiming the same module
path cannot coexist in one installation (the `tests/documentation` collision
with rivet v0.11.0 broke every downstream install). Every Keel test module
therefore carries the `keel-` prefix; `tests/keel-collection-names.rkt`
enforces this.

Pull requests should be narrow, include an executable regression test, and
avoid transport-, renderer-, or product-specific policy. Generated files and
unrelated formatting changes do not belong in the same commit.

## Family operating model

The canonical five-repository dependency graph, ownership table, change
routing, release order, and trust boundaries live in
[`docs/family-architecture.md`](docs/family-architecture.md). Read it before a
change that crosses Keel, Rivet, Glaze, Permit, Commerce, or a product boundary.

Keel's role in a coordinated change is deliberately narrow: specify and
release the transport-neutral contract first, then validate the released
package in Rivet and Glaze. Do not put framework, product, or commercial policy
in Keel to reduce the number of downstream edits.

## Releasing

1. Bump the package version in `info.rkt` and add the matching
   `CHANGELOG.md` section in the same change.
2. Tag the release with an annotated tag.
3. Trigger the downstream compatibility suites the same day so contract
   changes are validated against consumers immediately instead of at their
   next update:

       gh workflow run family-compat.yml -R turinglambdaai/rivet
       gh workflow run family-compat.yml -R turinglambdaai/glaze

4. Watch both runs; a red downstream run outranks new work.

By participating, contributors agree to be respectful, technically specific,
and welcoming. Maintainers may moderate conduct that makes collaboration unsafe
or hostile.

## Documentation languages

Use English for default public docs and preserve complete Chinese README and onboarding paths. Keep examples, supported-platform limits, troubleshooting and privacy/security promises consistent in the same change. Preserve identifiers and copyable commands; technical protocols have one normative English source, not separate language implementations. See the [family documentation language policy](https://github.com/turinglambdaai/turinglambdaai.github.io/blob/master/docs/DOCUMENTATION-LANGUAGES.md) for scope and review checks.
