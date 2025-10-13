module Unfig
  class EnvReader
    TRUTHY_STRINGS = %w[true yes on enable allow t y 1 ok okay].to_set.freeze
    FALSEY_STRINGS = %w[false no off disabled disable deny f n 0 nope].to_set.freeze

    def initialize(param:, env:)
      @param = param
      @env = env
    end

    def supplied? = multi? ? multi_keys_supplied? : key_supplied?

    def value
      if multi?
        supplied? ? multi_values : []
      else
        supplied? ? single_value : nil
      end
    end

    private

    attr_reader :param, :env

    def multi? = param.multi?

    def multi_keys = @_multi_keys ||= [param.env] + (0..9).map { |n| "#{param.env}_#{n}" }

    def supplied_multi_keys = multi_keys.select { |k| env.key?(k) }

    def multi_keys_supplied?
      return @_multi_keys_supplied if defined?(@_multi_keys_supplied)

      @_multi_keys_supplied = multi_keys.any? { |key| env.key?(key) }
    end

    def multi_values = supplied_multi_keys.map { |k| cast_env(k, env.fetch(k)) }

    def single_value = cast_env(param.env, env.fetch(param.env))

    def key_supplied? = env.key?(param.env)

    def cast_env(name, uncast)
      case param.type
      when "string" then uncast
      when "boolean" then cast_to_boolean(name, uncast)
      when "integer" then cast_to_integer(name, uncast)
      when "float" then cast_to_float(name, uncast)
      else
        raise Invalid, "Unfig::EnvLoader does not know how to handle parameter type '#{param.type}'"
      end
    end

    def cast_to_boolean(name, s)
      return true if TRUTHY_STRINGS.include?(s.strip.downcase)
      return false if FALSEY_STRINGS.include?(s.strip.downcase)
      raise InvalidBooleanText, "ENV['#{name}'] had unexpected content for a boolean: '#{s}'"
    end

    def cast_to_integer(name, s)
      return s.to_i if /\A-?\d+\z/.match?(s.strip)

      raise InvalidIntegerText, "ENV['#{name}'] had unexpected content for an integer: '#{s}'"
    end

    def cast_to_float(name, s)
      return s.to_f if /\A-?\d+(\.\d+)?\z/.match?(s.strip)

      raise InvalidFloatingPointText, "ENV['#{name}'] had unexpected content for a float: '#{s}'"
    end
  end
end
