# BrazilianDocumentWrapper
Short description and motivation.

## Usage
This plugin is a wrapper that injects the [brazilian_documents](https://github.com/fidelisrafael/brazilian_documents) gem behavior into string and active-record classes

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'brazilian_document_wrapper', git: 'https://github.com/CashU-BR/brazilian_document_wrapper'
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

Define attribute to acts_as_brazilian_document_wrapper:
```ruby
class Customer < ApplicationRecord
  acts_as_brazilian_document_wrapper brazilian_document_field: :cpf
end
```
or
```ruby
class Customer < ApplicationRecord
  acts_as_brazilian_document_wrapper # will consider document attribute as brazilian_document_field
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

## Test gem

```bash
$ bin/test
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
