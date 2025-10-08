module Unfig
  class ParamConfig
    Invalid = Class.new(Unfig::Error)

    def self.load(params_data) = params_data.map { |key, value| new(key, value) }

    def initialize(name, data)
      @name = name.to_s
      @data = data.transform_keys(&:to_sym)
    end

    attr_reader :name

    # Required entries

    def description = data.fetch(:description).to_s.tap { |d| validate_description!(d) }

    def type = data.fetch(:type).to_sym.tap { |t| validate_type!(t) }

    def default = data.fetch(:default).tap { |d| validate_default!(d) }

    # Optional entries

    def long = data.fetch(:long, nil).tap { |l| validate_long!(l) }

    def long_supplied? = data.key?(:long)

    def short = data.fetch(:short, nil).tap { |s| validate_short!(s) }

    def short_supplied? = data.key?(:short)

    def env = data.fetch(:env, nil).tap { |e| validate_env!(e) }

    def env_supplied? = data.key?(:env)

    private

    attr_reader :data

    def validate_description!(d)
      unless /\S/.match?(d)
        raise Invalid, "Description for #{name} must not be blank"
      end
    end

    KNOWN_TYPES = [:boolean, :string, :integer, :float].to_set.freeze

    def validate_type!(t)
      unless KNOWN_TYPES.include?(t)
        types_list = KNOWN_TYPES.to_a.sort.map(&:to_s).join(", ")
        raise Invalid, "Type supplied for #{name} is not recognized - must be one of #{types_list}"
      end
    end

    def validate_default!(d)
      case type
      when :boolean
        raise(Invalid, "Default for #{name} is not a boolean") unless [nil, true, false].include?(d)
      when :string
        raise(Invalid, "Default for #{name} is not a string") unless d.nil? || d.is_a?(String)
      when :integer
        raise(Invalid, "Default for #{name} is not an integer") unless d.nil? || d.is_a?(Integer)
      when :float
        raise(Invalid, "Default for #{name} is not a float") unless d.nil? || d.is_a?(Numeric)
      end
    end

    def validate_long!(l)
      return if l.nil?

      if !l.is_a?(String)
        raise Invalid, "Long flag supplied for #{name} is not a string"
      elsif /\s/.match?(l)
        raise Invalid, "Long flag supplied for #{name} includes whitespace"
      end
    end

    def validate_short!(s)
      return if s.nil?

      if !s.is_a?(String)
        raise Invalid, "Short flag supplied for #{name} is not a string"
      elsif !/\A[a-zA-Z0-9]\z/.match?(s)
        raise Invalid, "Short flag supplied for #{name} must be a single letter or digit"
      end
    end

    def validate_env!(e)
      return if e.nil?

      if !e.is_a?(String)
        raise Invalid, "ENV name supplied for #{name} is not a string"
      elsif !/\A[a-zA-Z0-9_]+\z/.match?(e)
        raise Invalid, "ENV name for #{name} may only contain alphanumerics and underscores"
      elsif !/\A[a-zA-Z]/.match?(e)
        raise Invalid, "ENV name for #{name} must begin with a letter"
      end
    end
  end
end
