# ADR 0001: Internalize CPF/CNPJ math and support alphanumeric CNPJ

## Status

Accepted — implemented in 0.2.0.

## Context

The Receita Federal began issuing alphanumeric CNPJs on 01/07/2026 (IN RFB
2.229/2024), on a gradual rollout, with numeric CNPJs remaining valid and immutable
forever — the two formats coexist indefinitely (see `CONTEXT.md` for the domain
background). From 06/07/2026, NF-e environments accept alphanumeric CNPJ too (NT
Conjunta 2025.001), so the new format can arrive through any integration touching a
company's tax ID.

Independent of that regulatory push, this gem had two pre-existing problems:

- All CPF/CNPJ math was delegated to `brazilian_documents` (which itself delegates to
  `digit_checksum`), and that dependency was never even declared correctly in the
  gemspec — it only worked because host apps happened to load it too.
- `brazilian_documents` validates CNPJ with a digits-only regex, so it cannot support
  the new format at all. Even absent any goal of dropping the dependency, the
  alphanumeric rollout would have forced abandoning it.

Internalizing the checksum math and adding alphanumeric support are therefore the same
change, not two separate efforts.

## Decision

- Reimplement all CPF/CNPJ validation, digit-verification, formatting, and generation
  in pure Ruby (`BrazilianDocumentWrapper::DocumentMath`), with zero new runtime
  dependencies.
- Use **one** validator/algorithm for CNPJ, covering numeric and alphanumeric — a
  numeric CNPJ is the special case where the root has no letters, not a separate code
  path.
- Preserve letters (normalized to uppercase) when stripping/formatting a CNPJ. The
  mask is punctuation only (`.`, `-`, `/`); anything else must fail validation rather
  than being silently discarded the way `gsub(/\D/, "")` would discard it.
- Add `Wrapper#branch(code)`, generalizing the existing `headquarter`, which becomes
  `branch('0001')` internally.
- Move `InvalidDocumentError` to `BrazilianDocumentWrapper::InvalidDocumentError`,
  keeping the top-level constant as a deprecated alias for one version. A consumer app
  was found rescuing a namespaced exception that never existed
  (`BRDocuments::InvalidDocumentError`) — the fail-fast contract only ever worked by
  accident there, and the new namespace makes the correct constant unambiguous.
  Reaffirm that contract (`pretty`/`standard`/`stripped`/`to_param`/`headquarter`/
  `branch` all raise on invalid input, no lenient variants) and extend it to
  `to_param`, which previously stripped digits silently instead of raising.
- Fix gemspec hygiene alongside this change: no more `brazilian_documents` reference
  (direct or via the Gemfile), and the `allowed_push_host` TODO placeholder removed.
  Bump to 0.2.0.

## Consequences

- Positive: no runtime dependency for CPF/CNPJ math beyond Ruby itself; alphanumeric
  CNPJ works everywhere the gem is used; the exception namespace is unambiguous.
- `to_param` is now a breaking change for any caller relying on its old silent-strip
  behavior on invalid input — see the migration checklist in `CHANGELOG.md`.
- Consumer apps still doing `gsub(/\D/, "")` or similar digit-only assumptions on
  CPF/CNPJ anywhere in their own code remain broken by alphanumeric CNPJ; that's
  outside this gem's control. `README.md` documents the audit checklist.
- Non-goals kept explicitly out of scope: migrating consumer apps, CNAB240/400 layout
  changes (bank-side, numeric-only), historical data migration, analytics/dbt
  pipeline changes, and generating real (RFB-assigned) document numbers.

## References

- Instrução Normativa RFB nº 2.229/2024.
- Manual de Cálculo do DV do CNPJ Alfanumérico (SERPRO/RFB).
- NT Conjunta nº 2025.001.
- `CONTEXT.md` for the CPF/CNPJ domain model this decision builds on.
