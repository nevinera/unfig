module Unfig
  Error = Class.new(StandardError)
  Invalid = Class.new(Error)
end

require_relative "unfig/version"
require_relative "unfig/param_config"
require_relative "unfig/param_validator"
