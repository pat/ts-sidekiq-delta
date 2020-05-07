# Delayed Deltas for Thinking Sphinx with Sidekiq

This code was heavily based on Aaron Gibralter's [ts-resque-delta](https://github.com/agibralter/ts-resque-delta), and was initially adapted for Sidekiq by [Danny Hawkins](https://github.com/danhawkins). This release is maintained by [Pat Allan](https://github.com/pat).

This version of `ts-sidekiq-delta` works only with [Thinking Sphinx](https://github.com/pat/thinking-sphinx) v3 or newer. v1/v2 releases are not supported, and almost certainly will never be. It does work with the Flying Sphinx service, provided you're using 1.0.0 or newer of the `flying-sphinx` gem.

## Installation

Get it into your Gemfile - and don't forget the version constraint!

    gem 'ts-sidekiq-delta', '~> 0.3.0'

If you're using Thinking Sphinx v3.0.x, you'll need to jump back to the 0.1.0 release of this gem.

## Usage

In your index definitions, you'll want to include the delta setting as an initial option:

    ThinkingSphinx::Index.define(:article,
      :with  => :active_record,
      :delta => ThinkingSphinx::Deltas::SidekiqDelta
    ) do
      # fields and attributes and such
    end

If you've never used delta indexes before, you'll want to add the boolean
column named `:delta` to each model's table and a corresponding database index:

    def change
      add_column :articles, :delta, :boolean, :default => true, :null => false
      add_index  :articles, :delta
    end

From here on in, just use Thinking Sphinx and Sidekiq as you normally would, and you'll find your Sphinx indices are updated quite promptly by Sidekiq.

Make sure you have a sidekiq worker monitoring the `ts_delta` queue.

## Licence

Copyright (c) 2013, ts-sidekiq-delta was originally developed by Danny Hawkins, is currently maintained by Pat Allan, and is released under the open MIT Licence.
