module Unfig
  class EnvLoader
    def initialize(params:, env:)
      @params = params
      @env = env
    end

    def read
      return @_read if defined?(@_read)

      @_read = {}
      params.params.each do |p|
        next unless p.enabled.include?("env")

        reader = EnvReader.new(param: p, env: env)
        @_read[p.name] = reader.value if reader.supplied?
      end
      @_read
    end

    private

    attr_reader :params, :env
  end
end
