module Unfig
  class EnvLoader
    InvalidEnv = Class.new(Error)
    InvalidBooleanText = Class.new(InvalidEnv)
    InvalidIntegerText = Class.new(InvalidEnv)
    InvalidFloatingPointText = Class.new(InvalidEnv)

    def initialize(params:, env:)
      @params = params
      @env = env
    end

    def read = supplied_params.map { |p| [p.name, value_for(p)] }.to_h

    private

    attr_reader :params, :env

    def all_params = params.params

    def supplied_params = all_params.select { |p| env.key?(p.env) }

    def value_for(p)
      uncast = env.fetch(p.env)
      case p.type
      when "string" then uncast
      when "boolean" then cast_to_boolean(p, uncast)
      when "integer" then cast_to_integer(p, uncast)
      when "float" then cast_to_float(p, uncast)
      else
        raise Invalid, "Unfig::EnvLoader does not know how to handle parameter type '#{p.type}'"
      end
    end

    TRUTHY_STRINGS = %w[true yes on enable allow t y 1 ok okay].to_set.freeze
    FALSEY_STRINGS = %w[false no off disabled disable deny f n 0 nope].to_set.freeze

    def cast_to_boolean(p, s)
      return true if TRUTHY_STRINGS.include?(s.strip.downcase)
      return false if FALSEY_STRINGS.include?(s.strip.downcase)
      raise InvalidBooleanText, "ENV['#{p.env}'] had unexpected content for a boolean: '#{s}'"
    end

    def cast_to_integer(p, s)
      return s.to_i if /\A-?\d+\z/.match?(s.strip)

      raise InvalidIntegerText, "ENV['#{p.env}'] had unexpected content for an integer: '#{s}'"
    end

    def cast_to_float(p, s)
      return s.to_f if /\A-?\d+(\.\d+)?\z/.match?(s.strip)

      raise InvalidFloatingPointText, "ENV['#{p.env}'] had unexpected content for a float: '#{s}'"
    end
  end
end
