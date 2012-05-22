require 'thinking_sphinx'
require 'thinking_sphinx/deltas/sidekiq_delta'

require 'mock_redis'
require 'fakefs/spec_helpers'


#to make sidekiq inline
module Sidekiq
  module Worker
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def perform_async(*args)
        worker = new
        worker.send(:perform,*args)
      end
    end
  end
end

RSpec.configure do |c|
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
  c.treat_symbols_as_metadata_keys_with_true_values = true
end
