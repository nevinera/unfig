module Unfig
  # ParamConfig wraps the configuration of an individual param value, and all of
  # the ways it can be supplied (a long flag, a short flag, a config-file entry,
  # or an environment variable).
  #
  # It enforces the allowed values on each piece of configuration, constructs
  # defaults for several of them (based on the name), and exposes which of those
  # methods are _enabled_ for that variable (you can decide that `--verbose` is
  # not suppliable through the config file for example). Each parameter can also
  # be designated as `multi?`, meaning that it can be supplied multiple times
  # (or supplied as an array, in the config-file case), and produces an array of
  # values in any case.
  class ParamConfig
    Invalid = Class.new(Unfig::Error)

    KNOWN_TYPES = ["boolean", "string", "integer", "float"].to_set.freeze
    KNOWN_ENABLED_VALUES = ["long", "short", "env", "file"].to_set.freeze
    MAX_NAME = 64
    MAX_LONG_FLAG = 64
    MAX_ENV_LENGTH = 64

    def self.load(params_data) = params_data.map { |key, value| new(key, value) }

    def initialize(name, data)
      @name = name
      @data = data.transform_keys(&:to_sym)
      validate!
    end

    def validate!
      validate_name!
      validate_description!
      validate_multi!
      validate_enabled!
      validate_type!
      validate_default!
      validate_long!
      validate_short!
      validate_env!
    end

    # Required entries

    attr_reader :name

    def description = data.fetch(:description)

    def type = data.fetch(:type)

    def default = data.fetch(:default)

    # Optional entries

    def multi? = data.fetch(:multi, false)

    def enabled
      if data.key?(:enabled)
        data.fetch(:enabled)
      else
        KNOWN_ENABLED_VALUES.to_a.sort
      end
    end

    def long
      if data.key?(:long)
        data.fetch(:long)
      else
        name.tr("_", "-").downcase
      end
    end

    def short
      if data.key?(:short)
        data.fetch(:short)
      else
        name[0]
      end
    end

    def env
      if data.key?(:env)
        data.fetch(:env, nil)
      else
        name.upcase
      end
    end

    private

    attr_reader :data

    def validate_name!
      if !@name.is_a?(String)
        raise Invalid, "Name for a parameter is not a string"
      elsif !/\A[a-zA-Z0-9_]+\z/.match?(@name)
        raise Invalid, "Name '#{@name}' may contain only alphanumerics and underscores"
      elsif @name.length > MAX_NAME
        raise Invalid, "Name '#{@name}' contains more than #{MAX_NAME} characters"
      end
    end

    def validate_description!
      if !data.key?(:description)
        raise Invalid, "Description must be supplied for #{name}"
      elsif !data.fetch(:description).is_a?(String)
        raise Invalid, "Description for #{name} must be supplied as a string"
      elsif !/\S/.match?(description)
        raise Invalid, "Description for #{name} must not be blank"
      elsif /\n/.match?(description)
        raise Invalid, "Description for #{name} may not include newlines"
      end
    end

    def validate_type!
      if !data.key?(:type)
        raise Invalid, "Type for #{name} was not supplied"
      end

      if !type.is_a?(String)
        raise Invalid, "Type for #{name} must be supplied as a string"
      elsif !KNOWN_TYPES.include?(type)
        types_list = KNOWN_TYPES.to_a.sort.map(&:to_s).join(", ")
        raise Invalid, "Type supplied for #{name} is not recognized - must be one of: #{types_list}"
      end
    end

    def validate_multi!
      unless [false, true].include?(multi?)
        raise Invalid, "Param #{name} may not take a non-boolean for 'multi'"
      end
    end

    def validate_enabled!
      if !enabled.is_a?(Array)
        raise Invalid, "Param #{name} has a non-array supplied for 'enabled'"
      elsif enabled.empty?
        raise Invalid, "Param #{name} has no input methods enabled"
      else
        unrecognized = enabled.reject { |e| KNOWN_ENABLED_VALUES.include?(e) }.sort
        if unrecognized.any?
          raise Invalid, "Param #{name} has unrecognized 'enabled' values: #{unrecognized.join(", ")}. Expected any of #{KNOWN_ENABLED_VALUES.join(", ")}"
        end
      end
    end

    def validate_default!
      raise(Invalid, "Default not supplied for #{name}") if !data.key?(:default)
      return if default.nil?

      if multi?
        raise(Invalid, "Default for multi-valued #{name} is not an array") unless default.is_a?(Array)
        if default.any? { |entry| !correct_default_type?(entry) }
          raise Invalid, "Default for #{name} includes non-#{type} values"
        end
      elsif !correct_default_type?(default)
        raise Invalid, "Default for #{name} is not a #{type}"
      end
    end

    def correct_default_type?(value)
      case type
      when "boolean" then [true, false].include?(value)
      when "string" then default.is_a?(String)
      when "integer" then default.is_a?(Integer)
      when "float" then default.is_a?(Numeric)
      end
    end

    def validate_long!
      if !long.is_a?(String)
        raise Invalid, "Long flag supplied for #{name} is not a string"
      elsif /\s/.match?(long)
        raise Invalid, "Long flag supplied for #{name} includes whitespace"
      elsif long.length > MAX_LONG_FLAG
        raise Invalid, "Long flag for #{name} is over #{MAX_LONG_FLAG} characters"
      end
    end

    def validate_short!
      if !short.is_a?(String)
        raise Invalid, "Short flag supplied for #{name} is not a string"
      elsif !/\A[a-zA-Z0-9]\z/.match?(short)
        raise Invalid, "Short flag supplied for #{name} must be a single letter or digit"
      end
    end

    def validate_env!
      if !env.is_a?(String)
        raise Invalid, "ENV name supplied for #{name} is not a string"
      elsif !/\A[a-zA-Z0-9_]+\z/.match?(env)
        raise Invalid, "ENV name for #{name} may only contain alphanumerics and underscores"
      elsif !/\A[a-zA-Z]/.match?(env)
        raise Invalid, "ENV name for #{name} must begin with a letter"
      elsif env.length > MAX_ENV_LENGTH
        raise Invalid, "ENV name for #{name} is over #{MAX_ENV_LENGTH} characters"
      end
    end
  end
end
