# BrazilianDocumentWrapper
Short description and motivation.

## Usage
This plugin is a wrapper that injects helpers for brazilian document strings into string and active-record classes

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'brazilian_document_wrapper', git: 'https://github.com/CashU-BR/brazilian_document_wrapper'
```

Include wrapper on application record class:
```ruby
class ApplicationRecord < ActiveRecord::Base
  include BrazilianDocumentWrapper::ActsAsBrazilianDocumentWrapper

  self.abstract_class = true
end
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install brazilian_document_wrapper
```

## Usage

Define attribute to acts_as_brazilian_document:
```ruby
class Customer < ApplicationRecord
  acts_as_brazilian_document brazilian_document_field: :cpf
end
```
or
```ruby
class Customer < ApplicationRecord
  acts_as_brazilian_document # will consider document attribute as brazilian_document_field
end
```

And you can use as follows:
```ruby
customer = Customer.new(cpf: '52.256.591/0001-66')

customer.cpf.stripped # 52256591000166
customer.cpf.pretty_prefix # 52.256.591
customer.cpf.standard # 52.256.591/0001-66
```

You can instantiate a document from a string:
```ruby
document = '52.256.591/0001-66'.to_brazilian_document

document.stripped # 52256591000166
```

## CPF/CNPJ validation, alphanumeric CNPJ

CPF and CNPJ validation, digit-verification, formatting, and generation are implemented
in pure Ruby inside this gem — no runtime dependency beyond Rails, including the
alphanumeric CNPJ introduced by IN RFB 2.229/2024. See [`CONTEXT.md`](CONTEXT.md) for
the CPF/CNPJ format and checksum background. Letters are normalized to uppercase, never
stripped as if they were mask punctuation:

```ruby
'12.ABC.345/01DE-35'.to_brazilian_document.cnpj?   # true
'12.abc.345/01de-35'.to_brazilian_document.pretty  # '12.ABC.345/01DE-35'
```

### Fail-fast contract

`pretty`, `standard`, `stripped`, `to_param`, `headquarter`, and `branch` all raise
`BrazilianDocumentWrapper::InvalidDocumentError` when called on an invalid document.
There are no lenient variants (no `pretty_or_nil`, etc.) — if invalid input is an
expected case in your flow, guard the call with `invalid_document?` / `invalid_cnpj?`
first:

```ruby
document = untrusted_input.to_brazilian_document
document.pretty unless document.invalid_document?
```

The top-level `InvalidDocumentError` constant still works as a deprecated alias for
`BrazilianDocumentWrapper::InvalidDocumentError` (for one version) — update any
`rescue InvalidDocumentError` to the namespaced constant.

### Branches

`Wrapper#branch(code)` recalculates the verify digits for any establishment code of a
CNPJ, generalizing `headquarter` (which is `branch('0001')`):

```ruby
'12.345.678/0001-95'.to_brazilian_document.branch('0003')
# => '12.345.678/0003-XX' (verify digits recalculated)
```

### Auditing an app that consumes this gem

If you're migrating a Rails app off `brazilian_documents`/`BRDocuments` and onto this
gem, or just making sure your app is ready for alphanumeric CNPJ, check:

- **Database:** CPF/CNPJ columns must be `string`/`varchar`/`citext`, never
  `bigint`/`integer`/`numeric`. Unique indexes need consistent normalization (no mask,
  uppercase), or logical duplicates will slip through.
- **Ad-hoc validations:** search for `\d{14}`/`\d{11}` regexes, `to_i`/`Integer(cnpj)`
  calls, and especially `gsub(/\D/, "")` — the last one silently deletes the letters
  from an alphanumeric CNPJ (`12ABC34501DE35` becomes `12345013`, wrong length and
  value, no error raised). Replace these with this gem's methods.
- **External integrations:** map any partner API where CPF/CNPJ is still declared as a
  numeric field — that can't be fixed from this gem's side.
- **Positional files (CNAB):** `picture 9` CNPJ fields don't support letters; changing
  that depends on the bank/FEBRABAN layout spec, outside this gem's control.
- **Analytics:** dbt models/BI queries that cast CNPJ to numeric or use `lpad`/
  `to_number` will silently break on an alphanumeric CNPJ.

## Test gem

```bash
$ bin/test
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
