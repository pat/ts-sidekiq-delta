class ThinkingSphinx::Deltas::SidekiqDelta < ThinkingSphinx::Deltas::DefaultDelta
  module FlagAsDeletedSet
    extend self

    def set_name(core_name)
      "#{ThinkingSphinx::Deltas::SidekiqDelta.job_prefix}:flag.deleted:#{core_name}:set"
    end

    def temp_name(core_name)
      "#{ThinkingSphinx::Deltas::SidekiqDelta.job_prefix}:flag.deleted:#{core_name}:temp"
    end

    def processing_name(core_name)
      "#{ThinkingSphinx::Deltas::SidekiqDelta.job_prefix}:flag.deleted:#{core_name}:processing"
    end

    def add(core_name, document_id)
      Sidekiq.redis{|r| r.sadd(set_name(core_name), document_id) }
    end

    def clear!(core_name)
      Sidekiq.redis{|r| r.del(set_name(core_name)) }

      #Clear processing set as well
      delta_name = ThinkingSphinx::Deltas::SidekiqDelta::IndexUtils.core_to_delta(core_name)
      ThinkingSphinx::Deltas::SidekiqDelta::DeltaJob.around_perform_lock(delta_name) do
        Sidekiq.redis{|r| r.del(processing_name(core_name)) }
      end
    end

    def clear_all!
      ThinkingSphinx::Deltas::SidekiqDelta::IndexUtils.core_indices.each do |core_index|
        clear!(core_index)
      end
    end

    def get_subset_for_processing(core_name)
      # Copy set to temp
      Sidekiq.redis{|r| r.sunionstore temp_name(core_name), set_name(core_name) }
      # Store (set - temp) into set.  This removes all items we copied into temp from set.
      Sidekiq.redis{|r| r.sdiffstore set_name(core_name), set_name(core_name), temp_name(core_name) }
      # Merge processing and temp together and store into processing.
      Sidekiq.redis{|r| r.sunionstore processing_name(core_name), processing_name(core_name), temp_name(core_name) }

      Sidekiq.redis{|r| r.del temp_name(core_name) }
    end

    def processing_members(core_name)
      Sidekiq.redis{|r| r.smembers(processing_name(core_name)).collect(&:to_i) }
    end

    def clear_processing(core_name)
      Sidekiq.redis{|r| r.del(processing_name(core_name)) }
    end
  end
end
