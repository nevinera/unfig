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

    def long = Array(data.fetch(:long, [])).tap { |s| validate_longs!(s) }

    def long_supplied? = data.key?(:long)

    def short = Array(data.fetch(:short, [])).tap { |s| validate_shorts!(s) }

    def short_supplied? = data.key?(:short)

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

    def validate_longs!(s)
      raise(Invalid, "Long flags supplied for #{name} are an empty array") if long_supplied? && s.empty?
      s.each { |elem| validate_long!(elem) }
    end

    def validate_long!(s)
      if !s.is_a?(String)
        raise Invalid, "Long flag supplied for #{name} is not a string"
      elsif /\s/.match?(s)
        raise Invalid, "Long flag supplied for #{name} includes whitespace"
      end
    end

    def validate_shorts!(s)
      raise(Invalid, "Short flags supplied for #{name} are an empty array") if short_supplied? && s.empty?
      s.each { |elem| validate_short!(elem) }
    end

    def validate_short!(s)
      if !s.is_a?(String)
        raise Invalid, "Short flag supplied for #{name} is not a string"
      elsif !/\A[a-zA-Z0-9]\z/.match?(s)
        raise Invalid, "Short flag supplied for #{name} must be a single letter or digit"
      end
    end
  end
end
