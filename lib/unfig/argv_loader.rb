module Unfig
  class ArgvLoader
    def initialize(params:, argv:)
      @params = params
      @argv = argv
      @options = {}
      @stop_early = false
    end

    def read
      return @_read if defined?(@_read)
      option_parser.parse!(argv)
      @_read = @stop_early ? nil : @options
    end

    private

    attr_reader :params, :argv

    def short_enabled?(p) = p.enabled.include?("short")

    def long_enabled?(p) = p.enabled.include?("long")

    def enabled?(p) = short_enabled?(p) || long_enabled?(p)

    def option_parser
      @_option_parser ||= OptionParser.new do |opts|
        opts.banner = params.banner if params.banner
        add_help_option(opts)

        params.params.each do |p|
          next unless enabled?(p)

          add_option_for(opts, p)
        end
      end
    end

    def short_arg(p)
      if p.type == "boolean" || p.count?
        "-#{p.short}"
      else
        "-#{p.short}#{p.name.upcase}"
      end
    end

    def long_arg(p)
      if p.count?
        "--#{p.long}"
      elsif p.type == "boolean"
        "--[no-]#{p.long}"
      else
        "--#{p.long}=#{p.name.upcase}"
      end
    end

    def type_arg(p)
      case p.type
      when "string" then String
      when "boolean" then TrueClass
      when "integer" then Integer
      when "float" then Numeric
      else
        raise Invalid, "ArgvLoader does not know how to handle type '#{p.type}'"
      end
    end

    def option_args(p)
      args = []
      args << short_arg(p) if short_enabled?(p)
      args << long_arg(p) if long_enabled?(p)
      args << type_arg(p)
      args << p.description
    end

    def initialize_flag_for(p)
      if p.count?
        @options[p.name] ||= 0
      elsif p.multi?
        @options[p.name] ||= []
      end
    end

    def handle_flag_for(p, name, value)
      if p.count?
        @options[name] += 1
      elsif p.multi?
        @options[name] << value
      elsif @options.key?(name)
        raise FlagError, "Cannot supply #{name} more than once"
      else
        @options[name] = value
      end
    end

    def add_option_for(opts, p)
      opts.on(*option_args(p)) do |value|
        initialize_flag_for(p)
        handle_flag_for(p, p.name, value)
      end
    end

    def add_help_option(opts)
      opts.on_tail("-h", "--help", "Print this help information") do
        warn(opts)
        @stop_early = true
      end
    end
  end
end
