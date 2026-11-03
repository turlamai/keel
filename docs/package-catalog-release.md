# Official Racket package catalog release gate

**Catalog source correction verified (2026-10-29):** the
[official Keel package record](https://pkgs.racket-lang.org/package/keel)
now resolves to `https://github.com/turlamai/keel.git#main`.
A historical [successful package-build transcript](https://pkg-build.racket-lang.org/server/built/test-success/keel.txt)
recorded 2,361 passing assertions against commit
`72353dbf87adca36816224438d2dac5e19427c2e`. **That historical result is
not the current official build status.** On 2026-11-03 the
[current package-builder test transcript](https://pkg-build.racket-lang.org/server/built/test-fail/keel.txt)
reported one failing documentation test out of 2,316 assertions: the test
required a checkout-only `.github/workflows/catalog-release-gate.yml` file
inside the published package. Package builds do not need to distribute GitHub
workflow configuration. The documentation test should keep enforcing the
workflow's existence in a Git checkout, while permitting its absence from the
installed catalog archive. A fresh official build must be checked after this
change is merged; the status must not be reported as green in advance.

The former package-source problem has been fixed. [Issue #8](https://github.com/turlamai/keel/issues/8)
now tracks rerunning the *previously blocked* Rivet/Glaze consumer suites.
A green Keel package build does not establish all downstream compatibility.

## Catalog revalidation and future maintenance

1. Inspect the current published source with a fresh Racket install:

   ```sh
   raco pkg catalog-show --catalog https://pkgs.racket-lang.org keel
   ```

   Confirm `https://github.com/turlamai/keel.git#main`. If a future
   migration requires correction, the authorized package catalog maintainer
   must edit the **existing** `keel` source record; GitHub redirects and
   repository README edits do not update official catalog metadata.
2. Run [Published package catalog release gate](../.github/workflows/catalog-release-gate.yml)
   manually after it reaches the default branch. This checks the official
   source and installs/tests `keel` by name on a clean Racket 9.3 runner.
3. Rerun `turlamai/rivet` and `turlamai/glaze` `family-compat.yml` and
   any affected packaging CI; verify the published Keel version still
   satisfies the consumers' declared minimum version. Record exact run
   URLs and consumer SHAs.
4. Close [#8](https://github.com/turlamai/keel/issues/8) only after
   the previously blocked suites complete successfully. Do not vendor
   Keel or replace its published catalog dependency with a direct Git clone.

## Failure semantics

- Catalog unavailable or old owner reappears: **NO-GO**.
- Catalog correct but fresh install/test fails: **NO-GO**, investigate.
- Official Keel build passes but downstream jobs remain queued: **Keel
  package gate passed, downstream gate unverified**; not an all-green release.
- Local linked-package tests alone are not official catalog evidence.

The manual gate never edits official metadata or dispatches downstream CI.
See [Racket package commands](https://docs.racket-lang.org/pkg/cmdline.html)
for `raco pkg catalog-show`.
