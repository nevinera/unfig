module Unfig
  class ParamsConfig
    def initialize(data)
      raise(ArgumentError, "Params-config must be a hash") unless data.is_a?(Hash)
      @data = data
    end

    def params = @_params ||= @data.map { |k, v| ParamConfig.new(k, v) }
  end
end
