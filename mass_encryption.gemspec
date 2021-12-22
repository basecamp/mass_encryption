require_relative "lib/mass_encryption/version"

Gem::Specification.new do |spec|
  spec.name        = "mass_encryption"
  spec.version     = MassEncryption::VERSION
  spec.authors     = [ "Jorge Manrubia" ]
  spec.email       = [ "jorge@hey.com" ]
  spec.homepage    = "http://github.com/basecamp/mass_encryption"
  spec.summary     = "Encrypt data in mass with Active Record Encryption"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 7.0.0"

  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "mocha"
end
