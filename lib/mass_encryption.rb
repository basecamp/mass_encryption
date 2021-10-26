require "mass_encryption/version"
require "mass_encryption/engine"

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module MassEncryption
  mattr_accessor :logger, default: ActiveSupport::Logger.new(STDOUT)
end
