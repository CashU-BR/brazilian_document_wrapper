# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Rails plugin gem that adds CPF/CNPJ helpers to strings and ActiveRecord attributes. All CPF/CNPJ validation, digit-verification, formatting, and generation math is implemented in pure Ruby inside the gem — there is no runtime dependency beyond Rails, and CNPJ validation supports both the legacy numeric-only format and the alphanumeric CNPJ introduced by IN RFB 2.229/2024. See `CONTEXT.md` for the CPF/CNPJ domain model (formats, checksum algorithm) and `docs/adr/` for why the gem is built this way — don't duplicate that background here. The gemspec supports Ruby >= 2.7.8 and Rails >= 6.1, < 9, and rubocop targets Ruby 2.7 — keep library code compatible with Ruby 2.7 syntax even if your local Ruby is newer.

## Commands

```bash
bundle install                                 # install dependencies
bin/test                                       # full test suite (minitest via rails/plugin/test)
bin/test test/wrapper_test.rb                  # one file
bin/test test/wrapper_test.rb:63               # one test, by line number
bin/test test/wrapper_test.rb -n "/doc_type/"  # tests matching a name pattern
bundle exec rubocop                            # lint (rubocop ~> 0.79, TargetRubyVersion 2.7.5)
```

SimpleCov runs on every test invocation and writes to `coverage/`.

## Architecture

`lib/brazilian_document_wrapper.rb` requires everything and defines module-level `generate_cpf` / `generate_cnpj(formatted = true, alphanumeric: true)` — `generate_cnpj` defaults to an alphanumeric root; pass `alphanumeric: false` for numeric-only.

- **`BrazilianDocumentWrapper::DocumentMath`** (`lib/brazilian_document_wrapper/document_math.rb`) — pure Ruby module holding all the checksum math: verify-digit calculation (mod 11, shared rule for CPF and CNPJ), CPF/CNPJ validity checks, and generation. One algorithm covers numeric and alphanumeric CNPJ — a numeric CNPJ is just the particular case where the root has no letters. Operates on already-normalized strings; owns no parsing/formatting.
- **`BrazilianDocumentWrapper::Wrapper`** (`lib/brazilian_document_wrapper/wrapper.rb`) — the core class: a `String` subclass holding a CPF or CNPJ. Document type is detected by validity (`cpf?` / `cnpj?` delegate to `DocumentMath`), so an invalid document has no type. Transformation methods (`stripped`, `pretty` / `standard`, `headquarter`, `to_param`, `branch`) return new `Wrapper` instances (via `return_document_type`) so results stay chainable, and raise `BrazilianDocumentWrapper::InvalidDocumentError` on invalid input — `to_param` included. `branch(code)` recalculates verify digits for an arbitrary CNPJ establishment code; `headquarter` is `branch('0001')`. The private `value` method left-pads with zeros (to 11 or 14 digits depending on length) so purely numeric documents that lost leading zeros still validate and format correctly — never applied when letters are present. CNPJ normalization strips only mask separators (`.`, `-`, `/`) and uppercases, preserving letters — it deliberately does not use a blanket "strip non-digits" regex, since that would silently delete the letters of an alphanumeric CNPJ.
- **String integration** (`lib/brazilian_document_wrapper/core_ext.rb`) — monkey-patches `String#to_brazilian_document`.
- **ActiveRecord integration** (`lib/brazilian_document_wrapper/acts_as_brazilian_document_wrapper.rb`) — a concern that host apps include in `ApplicationRecord`. `acts_as_brazilian_document brazilian_document_field: :cpf` (default field: `:document`) registers the attribute with `BrazilianDocumentType` (`lib/types/brazilian_document_type.rb`), an `ActiveModel::Type::Value` that casts values to `Wrapper`, and defines `legal_person?` / `natural_person?` on the model.
- `BrazilianDocumentWrapper::InvalidDocumentError` is the exception; a top-level `InvalidDocumentError` constant is kept as a deprecated alias for one version. `BrazilianDocumentType` remains a top-level constant, not namespaced.

## Tests

Standard Rails plugin layout: the suite boots the dummy Rails app in `test/dummy` (sqlite3). Its models exercise the concern — `BusinessProtest` uses the default `document` field, `Customer` a custom `cpf` field. `test/dummy` is excluded from rubocop.
