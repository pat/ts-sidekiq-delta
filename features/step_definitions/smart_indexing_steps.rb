When /^I run the smart indexer$/ do
  ThinkingSphinx::Deltas::SidekiqDelta::CoreIndex.new.smart_index(:verbose => false)
end
