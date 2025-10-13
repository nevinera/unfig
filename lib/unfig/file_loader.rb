module Unfig
  class FileLoader
    def initialize(params:, path:)
      @params = params
      @path = path
    end

    def read
      return @_read if defined?(@_read)

      @_read = {}
      params.params.each do |p|
        @_read[p.name] = read_for(p) if data.key?(p.name)
      end
      @_read
    end

    private

    attr_reader :params, :path

    def text = File.read(path)

    def data = @_data ||= YAML.safe_load(text)

    def read_for(p)
      data[p.name].tap do |value|
        p.multi? ? validate_types!(p, value) : validate_type!(p, value)
      end
    end

    def validate_type!(p, value)
      case p.type
      when "string" then validate_string!(p.name, value)
      when "boolean" then validate_boolean!(p.name, value)
      when "integer" then validate_integer!(p.name, value)
      when "float" then validate_float!(p.name, value)
      else
        raise Invalid, "Unfig::FileLoader does not know how to handle the parameter type '#{p.type}'"
      end
    end

    def validate_types!(p, value)
      if value.is_a?(Array)
        value.each { |v| validate_type!(p, v) }
      else
        validate_type!(p, value)
      end
    end

    def validate_string!(name, value)
      return if value.nil? || value.is_a?(String)

      raise InvalidYamlValue, "Unfig::FileLoader expected a string for #{name}, but got #{value.class}"
    end

    def validate_boolean!(name, value)
      return if [nil, true, false].include?(value)

      raise InvalidYamlValue, "Unfig::FileLoader expected a boolean for #{name}, but got #{value.class}"
    end

    def validate_integer!(name, value)
      return if value.nil? || value.is_a?(Integer)

      raise InvalidYamlValue, "Unfig::FileLoader expected an integer for #{name}, but got #{value.class}"
    end

    def validate_float!(name, value)
      return if value.nil? || value.is_a?(Numeric)

      raise InvalidYamlValue, "Unfig::FileLoader expected a float for #{name}, but got #{value.class}"
    end
  end
end
