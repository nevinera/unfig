require "yaml"
require "optparse"

module Unfig
  Error = Class.new(StandardError)
  Invalid = Class.new(Error)

  InvalidEnv = Class.new(Error)
  InvalidBooleanText = Class.new(InvalidEnv)
  InvalidIntegerText = Class.new(InvalidEnv)
  InvalidFloatingPointText = Class.new(InvalidEnv)

  InvalidYamlValue = Class.new(Error)
  FlagError = Class.new(Error)
end

require_relative "unfig/version"
require_relative "unfig/param_config"
require_relative "unfig/param_validator"
require_relative "unfig/params_config"
require_relative "unfig/env_reader"
require_relative "unfig/env_loader"
require_relative "unfig/file_loader"
require_relative "unfig/argv_loader"
