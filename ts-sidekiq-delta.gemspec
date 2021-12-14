# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = 'ts-sidekiq-delta'
  s.version     = '0.3.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Pat Allan', 'Aaron Gibralter', 'Danny Hawkins']
  s.email       = ['pat@freelancing-gods.com', 'danny.hawkins@gmail.com']
  s.homepage    = 'https://github.com/pat/ts-sidekiq-delta'
  s.summary     = %q{Thinking Sphinx - Sidekiq Deltas}
  s.description = %q{Manage delta indexes via Sidekiq for Thinking Sphinx}
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'thinking-sphinx',     '>= 3.1.0'
  s.add_dependency 'sidekiq',             '>= 2.5.4'
  s.add_dependency 'sidekiq-unique-jobs', '>= 7.0.0'

  s.add_development_dependency 'activerecord',     '>= 3.1.0'
  s.add_development_dependency 'combustion'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'database_cleaner', '>= 0.5.2'
  s.add_development_dependency 'mysql2',           '>= 0.3.12b4'
  s.add_development_dependency 'rake',             '>= 0.8.7'
  s.add_development_dependency 'redis-namespace'
  s.add_development_dependency 'rspec',            '>= 2.11.0'
end
