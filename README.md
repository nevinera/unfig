# Unfig

We've written code that merges/cascades some combination of defaults, config-files,
environment-variables, and cli-supplied parameters *too many times*. In one of my
gems, _half of the code_ is concerned with managing those various ways to supply
its 20+ control parameters. That's ridiculous.

The intent of `unfig` is to consolidate all of that capability, so that we
just need to specify what configuration exists (and optionally how it can be
supplied) in a straightforward yaml config, and stop worrying about it.

## Usage Example (currently tentative)

Let's use a config file (at config/unfig.yml) like.. this:

```yaml
---
values:
  verbose:
    description: Expose much more information in the logs
    long: "verbose"
    short: "v"
    type: boolean
    skip: ["config"]
    default: false
  parallel:
    description: Run in parallel instead of serially
    long: ["parallel", "concurrent"]
    short: ["p", "c"]
    type: boolean
    default: false
```

Now, in my cli script I can do this (`REPO_ROOT` is the path of the repository _using_
my gem FooBar, which itself describes its configuration using Unfig):

```ruby
require "unfig"

unfig_path = File.expand_path("../config/unfig.yml", __dir__)
config_path = File.join(REPO_ROOT, ".foo_bar.yml")
config = Unfig.parse(unfig_path, argv: ARGV, config: config_path, format: :struct)

Logger.verbosity = :debug if config.verbose?
FooBar.execute!(parallel: config.parallel?)
```

And it just.. works. `optparse` is _awesome_ (and will be involved), but now you
can stick a yaml file like `parallel: true` in `.foo_bar.yml`, and supply `--vebose`
on the command-line or like VERBOSE=true in your environment.

## Details

The `Unfig.parse` method requires a path to a 'unfig' config file as its
only positional parameter, but it accepts these named options:

* argv: (required) The supplied arguments to the script (usually just ARGV).
  If you supply `nil` as the value, no command-line parameters will be
  parsed/accepted.
* config: (required) The path to the _local_ config file - the project using
  *your gem* is able to specify local defaults for *your* options. If you
  supply `nil`, then no local defaults will be used.
* env: (default: ENV) This is rarely supplied outside of testing, but you can
  supply a Hash instead of just letting the gem read values from ENV. If you
  supply `nil`, environment will not be used at all.
* format (default: `hash`) One of `hash`, `struct` or `ostruct` - what comes
  _out_ of the `parse` method will either be a hash (with symbol keys), a
  generated Struct, or an OpenStruct.
