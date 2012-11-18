ThinkingSphinx::Index.define :book, :with => :active_record, :delta => ThinkingSphinx::Deltas::SidekiqDelta do
  indexes title, author
end
