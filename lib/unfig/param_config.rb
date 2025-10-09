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
    KNOWN_ENABLED_VALUES = ["long", "short", "env", "file"].to_set.freeze

    def self.load(params_data) = params_data.map { |key, value| new(key, value) }

    def initialize(name, data)
      @name = name
      @data = data.transform_keys(&:to_sym)
      ParamValidator.new(@name, @data).validate!
    end

    attr_reader :name

    def description = data.fetch(:description)

    def type = data.fetch(:type)

    def default = data.fetch(:default)

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
  end
end
