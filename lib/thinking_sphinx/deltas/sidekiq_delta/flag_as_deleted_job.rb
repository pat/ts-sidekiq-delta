class ThinkingSphinx::Deltas::SidekiqDelta::FlagAsDeletedJob
  include Sidekiq::Worker

  # Runs Sphinx's indexer tool to process the index. Currently assumes Sphinx
  # is running.
  sidekiq_options unique: :until_executed, retry: true, queue: 'ts_delta'

  def perform(index, document_id)
    ThinkingSphinx::Deltas::DeleteJob.new(index, document_id).perform
  rescue Mysql2::Error => error
    # This isn't vital, so don't raise the error
  end
end

ThinkingSphinx::Deltas::SidekiqDelta::JOB_TYPES <<
  ThinkingSphinx::Deltas::SidekiqDelta::FlagAsDeletedJob
