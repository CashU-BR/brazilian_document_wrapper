require_relative "lib/brazilian_document_wrapper/version"

Gem::Specification.new do |spec|
  spec.name        = "brazilian_document_wrapper"
  spec.version     = BrazilianDocumentWrapper::VERSION
  spec.authors     = ["Joao Torquato"]
  spec.email       = ["joao.otl@gmail.com"]
  spec.homepage    = "https://cashu.com.br"
  spec.summary     = "Summary of BrazilianDocumentWrapper."
  spec.description = "Description of BrazilianDocumentWrapper."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/CashU-BR/brazilian_document_wrapper"
  spec.metadata["changelog_uri"] = "https://github.com/CashU-BR/brazilian_document_wrapper/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.4", ">= 6.1.4.4"
end
