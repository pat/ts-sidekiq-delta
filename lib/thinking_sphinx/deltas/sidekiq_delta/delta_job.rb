# A simple job class that processes a given index.
#
class ThinkingSphinx::Deltas::SidekiqDelta::DeltaJob
  include Sidekiq::Worker

  sidekiq_options unique: :until_executed, retry: true, queue: 'ts_delta'

  # Runs Sphinx's indexer tool to process the index.
  #
  # @param [String] index the name of the Sphinx index
  #
  def perform(index)
    ThinkingSphinx::Deltas::IndexJob.new(index).perform
  end

  # Try again later if lock is in use.
  def self.lock_failed(*arguments)
    self.class.perform_async(*arguments)
  end

  # This allows us to have a concurrency safe version of ts-delayed-delta's
  # duplicates_exist:
  #
  # http://github.com/freelancing-god/ts-delayed-delta/blob/master/lib/thinkin
  # g_sphinx/deltas/delayed_delta/job.rb#L47
  #
  # The name of this method ensures that it runs within around_perform_lock.
  #
  # We've leveraged resque-lock-timeout to ensure that only one DeltaJob is
  # running at a time. Now, this around filter essentially ensures that only
  # one DeltaJob of each index type can sit at the queue at once. If the queue
  # has more than one, lrem will clear the rest off.
  #
  def self.around_perform_lock1(*arguments)
    # Remove all other instances of this job (with the same args) from the
    # queue. Uses LREM (http://code.google.com/p/redis/wiki/LremCommand) which
    # takes the form: "LREM key count value" and if count == 0 removes all
    # instances of value from the list.
    redis_job_value = {:class => self.to_s, :args => arguments}.to_json

    Sidekiq.redis {|redis|
      redis.lrem("queue:#{@queue}", 0, redis_job_value)
    }

    yield
  end
end

ThinkingSphinx::Deltas::SidekiqDelta::JOB_TYPES <<
  ThinkingSphinx::Deltas::SidekiqDelta::DeltaJob
