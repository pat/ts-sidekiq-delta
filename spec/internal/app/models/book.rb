class Book < ActiveRecord::Base
  ThinkingSphinx::Callbacks.append(
    self, :behaviours => [:sql, :deltas]
  )
end
