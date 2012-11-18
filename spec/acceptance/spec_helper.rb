require 'spec_helper'
require 'sidekiq/processor'

root = File.expand_path File.dirname(__FILE__)
Dir["#{root}/support/**/*.rb"].each { |file| require file }
