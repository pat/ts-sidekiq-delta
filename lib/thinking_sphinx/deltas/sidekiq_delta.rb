require 'sidekiq'
require 'thinking_sphinx'

class ThinkingSphinx::Deltas::SidekiqDelta < ThinkingSphinx::Deltas::DefaultDelta
  JOB_TYPES  = []
  JOB_PREFIX = 'ts-delta'

  # LTRIM + LPOP deletes all items from the Resque queue without loading it
  # into client memory (unlike Resque.dequeue).
  # WARNING: This will clear ALL jobs in any queue used by a ResqueDelta job.
  # If you're sharing a queue with other jobs they'll be deleted!
  def self.clear_thinking_sphinx_queues
    JOB_TYPES.collect { |job|
      job.sidekiq_options['queue']
    }.uniq.each do |queue|
      Sidekiq.redis { |redis| redis.srem "queues", queue }
      Sidekiq.redis { |redis| redis.del  "queue:#{queue}" }
    end
  end

  # Clear both the resque queues and any other state maintained in redis
  def self.clear!
    self.clear_thinking_sphinx_queues

    FlagAsDeletedSet.clear_all!
  end

  # Use simplistic locking.  We're assuming that the user won't run more than one
  # `rake ts:si` or `rake ts:in` task at a time.
  def self.lock(index_name)
    Sidekiq.redis {|redis|
      redis.set("#{JOB_PREFIX}:index:#{index_name}:locked", 'true')
    }
  end

  def self.unlock(index_name)
    Sidekiq.redis {|redis|
      redis.del("#{JOB_PREFIX}:index:#{index_name}:locked")
    }
  end

  def self.locked?(index_name)
    Sidekiq.redis {|redis|
      redis.get("#{JOB_PREFIX}:index:#{index_name}:locked") == 'true'
    }
  end

  def delete(index, instance)
    return if self.class.locked?(index.reference)

    ThinkingSphinx::Deltas::SidekiqDelta::FlagAsDeletedJob.perform_async(
      index.name, index.document_id_for_key(instance.id)
    )
  end

  def index(index)
    return if self.class.locked?(index.reference)

    ThinkingSphinx::Deltas::SidekiqDelta::DeltaJob.perform_async(index.name)
  end
end

require 'thinking_sphinx/deltas/sidekiq_delta/delta_job'
require 'thinking_sphinx/deltas/sidekiq_delta/flag_as_deleted_job'
