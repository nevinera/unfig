module Unfig
  class Loader
    def initialize(values:, argv: UNSUPPLIED, env: UNSUPPLIED, config: UNSUPPLIED, **options)
      @argv = argv
      @env = env
      @config = config
      @values = values
      @format = options.fetch(:format, :hash)
      @banner = options.fetch(:banner, nil)
    end

    def read
      @_read ||=
        case format.to_s
        when "hash" then hashed_values
        when "struct" then struct_values
        when "openstruct" then openstruct_values
        else
          raise ArgumentError, "Unfig::Loader cannot return results in the format '#{format}'"
        end
    end

    private

    attr_reader :config, :values, :format, :banner

    def argv = (@argv == UNSUPPLIED) ? ARGV : @argv

    def env = (@env == UNSUPPLIED) ? ENV.to_h : @env

    def params = @_params ||= ParamsConfig.new(banner:, params: values)

    def loaded_argv
      return @_loaded_argv if defined?(@_loaded_argv)
      @_loaded_argv = argv.nil? ? {} : ArgvLoader.new(params:, argv:).read
    end

    def loaded_env
      return @_loaded_env if defined?(@_loaded_env)
      @_loaded_env = env.nil? ? {} : EnvLoader.new(params:, env:).read
    end

    def loaded_file
      return @_loaded_file if defined?(@_loaded_file)
      @_loaded_file = (config == UNSUPPLIED || config.nil?) ? {} : FileLoader.new(params:, path: config).read
    end

    def defaults = @_defaults ||= params.params.map { |p| [p.name, p.default] }.to_h

    def merged_values = @_merged_values ||= defaults.merge(loaded_file).merge(loaded_env).merge(loaded_argv)

    def hashed_values = merged_values.transform_keys(&:to_sym)

    def struct_values
      struct_keys = params.params.map(&:name).map(&:to_sym)
      struct = Struct.new(*struct_keys, keyword_init: true)
      struct.new(**merged_values)
    end

    def openstruct_values
      # Don't require ostruct unless they try to use it (we don't want to make it one of _our_
      # dependencies, but if they try to use it without making it one of _theirs_, ruby will
      # inform them)
      require "ostruct"
      OpenStruct.new(merged_values)
    end
  end
end
