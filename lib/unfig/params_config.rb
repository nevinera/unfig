module Unfig
  # ParamsConfig wraps the configuration of _all_ of the possible parameters,
  # and enforces uniqueness validations - you can't have two parameters with
  # the same flag, or the same name; they'll collide in the implementation.
  class ParamsConfig
    def initialize(data)
      raise(Invalid, "Params-config must be a Hash") unless data.is_a?(Hash)
      raise(Invalid, "Params-config must supply some params (as a Hash)") unless data[:params].is_a?(Hash)
      @data = data
    end

    def params
      return @_params if defined?(@_params)
      validate!
      @_params = built
    end

    private

    attr_reader :data

    def built = @_built ||= data[:params].map { |k, v| ParamConfig.new(k, v) }

    def validate!
      validate_no_duplicate_names!
      validate_no_duplicate_long_flags!
      validate_no_duplicate_short_flags!
      validate_no_duplicate_envs!
    end

    def repeats(items) = items.tally.select { |_k, v| v > 1 }.keys.sort

    def validate_no_duplicate_names!
      dups = repeats(built.map(&:name))
      return if dups.none?

      raise Invalid, "Duplicate parameter names: #{dups.join(", ")}"
    end

    def validate_no_duplicate_long_flags!
      dups = repeats(built.map(&:long))
      return if dups.none?

      raise Invalid, "Duplicate long-flags: #{dups.join(", ")}"
    end

    def validate_no_duplicate_short_flags!
      dups = repeats(built.map(&:short))
      return if dups.none?

      raise Invalid, "Duplicate short-flags: #{dups.join(", ")}"
    end

    def validate_no_duplicate_envs!
      dups = repeats(built.map(&:env))
      return if dups.none?

      raise Invalid, "Duplicate env-names: #{dups.join(", ")}"
    end
  end
end
