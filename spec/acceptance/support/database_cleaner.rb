RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each, :live) do
    DatabaseCleaner.clean
  end
end
