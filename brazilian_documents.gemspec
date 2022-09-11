require_relative "lib/brazilian_documents/version"

Gem::Specification.new do |spec|
  spec.name        = "brazilian_documents"
  spec.version     = BrazilianDocuments::VERSION
  spec.authors     = ["Joao Torquato"]
  spec.email       = ["joao.otl@gmail.com"]
  spec.homepage    = "TODO"
  spec.summary     = "TODO: Summary of BrazilianDocuments."
  spec.description = "TODO: Description of BrazilianDocuments."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.4", ">= 6.1.4.4"
end
