module Unfig
  class ParamValidator
    MAX_NAME = 64
    MAX_LONG_FLAG = 64
    MAX_ENV_LENGTH = 64
    KNOWN_TYPES = ["boolean", "string", "integer", "float"].to_set.freeze
    KNOWN_ENABLEMENTS = ParamConfig::KNOWN_ENABLED_VALUES.dup.freeze

    def initialize(name, data)
      @name = name
      @data = data
    end

    def validate!
      validate_name!
      validate_description!
      validate_type!
      validate_multi!
      validate_enabled!
      validate_default!
      validate_long!
      validate_short!
      validate_env!
    end

    private

    attr_reader :name, :data

    # accessors

    [:description, :type, :multi, :enabled, :default, :long, :short, :env].each do |key|
      define_method(key) { data[key] }
    end

    # helpers

    def invalid!(msg) = raise(Invalid, "Param '#{name}': #{msg}")

    def missing?(key) = !data.key?(key)

    def nonstring?(s) = !s.is_a?(String)

    def nonstringlike?(s) = !(s.is_a?(String) || s.is_a?(Symbol))

    def blank?(s) = !/\S/.match?(s)

    def whitespace?(s) = /\s/.match?(s)

    def multi_line?(s) = /\n/.match?(s)

    def alphanumeric?(s) = /\A[a-zA-Z0-9_]+\z/.match?(s)

    def boolean?(v) = [true, false].include?(v)

    def array?(v) = v.is_a?(Array)

    def known_type?(t) = KNOWN_TYPES.include?(t)

    def known_enablement?(e) = KNOWN_ENABLEMENTS.include?(e)

    def unrecognized_enablements = enabled.reject { |e| known_enablement?(e) }.sort

    def types_list = KNOWN_TYPES.to_a.sort.map(&:to_s).join(", ")

    # validators

    def validate_name!
      invalid!("Name is not a string") if nonstringlike?(name)
      invalid!("Name may contain only alphanumerics and underscores") unless alphanumeric?(name)
      invalid!("Name contains more than #{MAX_NAME} characters") if name.length > MAX_NAME
    end

    def validate_description!
      invalid!("Description must be supplied") if missing?(:description)
      invalid!("Description must be supplied as a string") if nonstring?(description)
      invalid!("Description must not be blank") if blank?(description)
      invalid!("Description may not include newlines") if multi_line?(description)
    end

    def validate_type!
      invalid!("Type was not supplied") if missing?(:type)
      invalid!("Type must be supplied as a string") if nonstring?(type)
      invalid!("Type not recognized - expected #{types_list}") unless known_type?(type)
    end

    def validate_multi!
      return unless data.key?(:multi)

      invalid!("Multi must be a boolean") unless boolean?(multi)
    end

    def validate_enabled!
      return if missing?(:enabled)

      invalid!("Enabled must be an array") unless array?(enabled)
      invalid!("Enabled must not be empty") if enabled.empty?

      if unrecognized_enablements.any?
        invalid!("Enabled includes unrecognized values: #{unrecognized_enablements.join(", ")}")
      end
    end

    def validate_multi_default!
      invalid!("Multi-valued, but default is not an Array") unless array?(default)

      if default.any? { |entry| !correct_default_type?(type, entry) }
        invalid!("Default includes non-#{type} values")
      end
    end

    def validate_single_default!
      return if correct_default_type?(type, default)
      invalid!("Default is not a #{type}")
    end

    def validate_default!
      invalid!("Default not supplied") if missing?(:default)
      return if default.nil?

      multi ? validate_multi_default! : validate_single_default!
    end

    def correct_default_type?(type, value)
      case type
      when "boolean" then [true, false].include?(value)
      when "string" then value.is_a?(String)
      when "integer" then value.is_a?(Integer)
      when "float" then value.is_a?(Numeric)
      end
    end

    def validate_long!
      return if missing?(:long)

      invalid!("Long flag is not a string") if nonstring?(long)
      invalid!("Long flag includes whitespace") if whitespace?(long)
      invalid!("Long flag is over #{MAX_LONG_FLAG} characters") if long.length > MAX_LONG_FLAG
    end

    def validate_short!
      return if missing?(:short)

      invalid!("Short flag is not a string") if nonstring?(short)
      invalid!("Short flag must be a single letter or digit") unless /\A[a-z0-9]\z/i.match?(short)
    end

    def validate_env!
      return if missing?(:env)

      invalid!("ENV name is not a string") if nonstring?(env)
      invalid!("ENV name may only contain alphanumerics and underscores") unless alphanumeric?(env)
      invalid!("ENV name must begin with a letter") unless /\A[a-z]/i.match?(env)
      invalid!("ENV name is over #{MAX_ENV_LENGTH} characters") if env.length > MAX_ENV_LENGTH
    end
  end
end
