# frozen_string_literal: true

require_relative 'lib/brazilian_document_wrapper/version'

Gem::Specification.new do |spec|
  spec.name        = 'brazilian_document_wrapper'
  spec.version     = BrazilianDocumentWrapper::VERSION
  spec.authors     = ['Joao Torquato']
  spec.email       = ['joao.otl@gmail.com']
  spec.homepage    = 'https://cashu.com.br'
  spec.summary     = 'Summary of BrazilianDocumentWrapper.'
  spec.description = 'Description of BrazilianDocumentWrapper.'
  spec.license     = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/CashU-BR/brazilian_document_wrapper'
  spec.metadata['changelog_uri'] = 'https://github.com/CashU-BR/brazilian_document_wrapper/CHANGELOG.md'

  spec.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'rails', '>= 6.1', '< 8.0'
  spec.required_ruby_version = '>= 2.7.8'
end
