# Unfig

We've written code that merges/cascades some combination of defaults, config-files,
environment-variables, and cli-supplied parameters *too many times*. In one of my
gems, _half of the code_ is concerned with managing those various ways to supply
its 20+ control parameters. That's ridiculous.

The intent of `unfig` is to consolidate all of that capability, so that we
just need to specify what configuration exists (and optionally how it can be
supplied) in a straightforward way, and stop worrying about it.

## Usage Example (currently tentative)

Let's invoke Unfig like this, as an example:

```ruby
require "unfig"

@options = Unfig.load_options(
  config: File.expand_path("~/.mygem.yml"),
  values: {
    verbose: {
      description: "Expose much more information in the logs",
      type: "boolean",
      default: false,
    },
    parallel: {
      description: "Run in parallel instead of serially",
      type: "boolean",
      default: false,
    }
  }
)
```

Now I'll have an `@options` object (a Hash, since we didn't specify), and the
user can supply either of those options on the command-line, in the environment,
or in a config-file in their home directory.

It's more configurable than that of course. At the top-level, it accepts these
options:

* `config` - where to search for the (yaml) config file that might specify some
  of these parameters. Optional - if not supplied, no config-file will be used.
* `banner` - what to say on the command-line when help is invoked (usually a
  usage example). Optional - if not supplied, no banner is present.
* `format` - what sort of object comes out of the `load` call; one of
  `[:hash, :struct, :openstruct]`. If not supplied, defaults to `:hash`.
* `argv` - Usually this is `ARGV` (the default), but if you want to interact
  with the separately, you could supply `argv: ARGV.dup`, or just an array
  of arguments.
* `env` - Usually this is `ENV` (the default), but if you want, you can just
  pass an arbitrary Hash(String => String) here instead.
* `params` - the parameter configurations; keys are parameter names (symbol or
  string), and values are parameter configs.

And for each parameter, we have these options:

* `name` - this is the key in the params hash. It can be a String or Symbol,
  it must start with a letter, and it may contain only letters, numbers, and
  underscores. No more than 64 characters long.
* `description` - this will be used as the description of the parameter on the
  cli - it is required, must be a non-blank string, and may contain no newlines.
* `type` - this is the type to cast the supplied values into - it is required,
  and must be one of "boolean", "string", "integer", or "float" (a String).
* `multi` - this specifies whether the parameter can be "multi-valued" (default
  is false). If true, supplying the flag more than once, or supplying an array
  of values in the config file, or (more awkwardly) setting multiple environment
  variables with numeric suffixes (`FOO_0` through `FOO_9` for an option `foo`)
  will allow you to supply multiple values, and the parameter will return an
  Array (whether you actually do so or not).
* `enabled` - which configuration methods are supported for the parameter. By
  default all of them will be, but you can for example exclude `verbose` from
  being supplied via the config file if you want to, or only support the _long_
  flag (`--verbose` works but not `-v`).
* `default` - what value should this parameter have if they don't supply one?
  If you supplied `multi: true`, this is required to be an array of defaults;
  in either case, the _type_ of the default will be validated against the
  supplied `type`.
* `long`/`short` - these can override the default long/short cli flags. This is
  particularly important for `short`, since two parameters that start with the
  same letter will automatically collide unless it's supplied for one of them.
  The default values are (a) the parameter-name, but with underscores mapped to
  dashes and (b) the first letter of the parameter name.
* `env` - the name of the environment variable to consult. By default, it's the
  parameter name up-cased, but like.. if your parameter is `user`, you may need
  to look at `MYGEM_USER` instead for example (unless you _want_ the unix USER).
