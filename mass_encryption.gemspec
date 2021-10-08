require_relative "lib/mass_encryption/version"

Gem::Specification.new do |spec|
  spec.name        = "mass_encryption"
  spec.version     = MassEncryption::VERSION
  spec.authors     = [ "Jorge Manrubia" ]
  spec.email       = [ "jorge.manrubia@gmail.com" ]
  spec.homepage    = "http://github.com/basecamp/mass_encryption/settings/access"
  spec.summary     = "Mass encryption for active record"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
end
