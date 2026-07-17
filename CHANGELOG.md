# Changelog

## 0.2.0

### Added
- Support for alphanumeric CNPJ (IN RFB 2.229/2024, in production since 01/07/2026).
  `cnpj?`, `pretty`/`standard`, `stripped`/`to_param`, `headquarter`, and the new
  `branch` all accept and correctly validate/format CNPJs with letters in positions
  1-12; the verify digits (positions 13-14) remain numeric-only. A fully numeric CNPJ
  is a particular case of the alphanumeric format, validated by the same algorithm.
- `Wrapper#branch(code)` — recalculates verify digits for an arbitrary establishment
  code. `headquarter` is now `branch('0001')` internally.
- `BrazilianDocumentWrapper.generate_cnpj(formatted = true, alphanumeric: true)` —
  optional `alphanumeric:` flag to generate a CNPJ with letters in the root. Defaults
  to `true`; pass `alphanumeric: false` for a numeric-only CNPJ (e.g. existing
  factories/specs in consumer apps that assume digits-only).

### Changed
- **Internalized all CPF/CNPJ math.** Validation, digit-verification, stripping,
  formatting, and generation are now pure Ruby, implemented inside this gem. The
  `brazilian_documents`/`digit_checksum` runtime dependency is gone.
- `InvalidDocumentError` moved to `BrazilianDocumentWrapper::InvalidDocumentError`. The
  top-level `InvalidDocumentError` constant is kept as a **deprecated alias for one
  version** — update `rescue InvalidDocumentError` to the namespaced constant.
- `to_param` now raises `BrazilianDocumentWrapper::InvalidDocumentError` for an invalid
  document, matching `pretty`/`standard`/`stripped`/`headquarter`/`branch` (previously
  it silently stripped non-digit characters instead of raising).
- `stripped`/`to_param`/`pretty`/`standard` now preserve letters (normalized to
  uppercase) for CNPJ instead of stripping them — a CNPJ mask is only `.`, `-`, `/`.
  CPF behavior is unchanged (digits only).
- Gemspec no longer references `brazilian_documents`/`digit_checksum`, directly or
  indirectly. Removed the placeholder `allowed_push_host` TODO metadata.

### Migration checklist for consumer apps
This gem cannot audit apps that consume it, but if you're migrating off
`brazilian_documents`/`BRDocuments` directly, or preparing for alphanumeric CNPJ:

- **Database:** CPF/CNPJ columns must be `string`/`varchar`/`citext`, never
  `bigint`/`integer`/`numeric`. Unique indexes need consistent normalization (no mask,
  uppercase) or logical duplicates will slip through.
- **Ad-hoc validations:** search for `\d{14}`/`\d{11}` regexes, `to_i`/
  `Integer(cnpj)` calls, and especially `gsub(/\D/, "")` — that last one silently
  deletes the letters from an alphanumeric CNPJ. Replace with this gem's methods.
- **External integrations:** map any partner API/contract that still declares
  CPF/CNPJ as numeric — that can't be fixed from this gem's side.
- **Positional files (CNAB):** `picture 9` CNPJ fields don't support letters; layout
  changes depend on the bank/FEBRABAN spec, outside this gem's control.
- **Analytics:** dbt models/BI queries that cast CNPJ to numeric or use `lpad`/
  `to_number` will silently break on an alphanumeric CNPJ.
- Fix any `rescue BRDocuments::InvalidDocumentError` (that constant never existed) to
  `rescue BrazilianDocumentWrapper::InvalidDocumentError`.
- `pretty`/`standard`/`stripped`/`to_param`/`headquarter`/`branch` raise on invalid
  input — guard call sites that format untrusted/external data with
  `invalid_document?`/`invalid_cnpj?` first.
- `BrazilianDocumentWrapper.generate_cnpj` now returns an **alphanumeric** CNPJ by
  default. Any factory/fixture that assumes a digits-only result (e.g. `.to_i`,
  numeric-column seeds, `\d{14}` assertions) needs `generate_cnpj(alphanumeric: false)`.

## 0.2.1

### Fixed
- `Wrapper#cpf_digits` no longer strips letters via a blanket `\D` regex — it now removes
  only CPF mask separators (`.`, `-`), mirroring `cnpj_chars`. This resolves an ambiguity
  where an alphanumeric CNPJ whose embedded 11 digits happened to form a valid CPF (e.g.
  `5C9992M9H04496`, digits `59992904496`) was misdetected as a CPF, causing
  `pretty`/`stripped` to format it as a CPF instead of a CNPJ (~5 per million CNPJs in a
  1M-generation fuzz test).
- CPF strings with a stray non-mask character (e.g. a letter) now correctly fail
  validation instead of being silently coerced into a valid-looking CPF.

## 0.1.x
See git history.
