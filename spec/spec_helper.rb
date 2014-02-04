require 'rubygems'
require 'rspec'
require 'singleton'
require 'simplecov'
require 'coveralls'

# Both local SimpleCov and publish to Coveralls.io
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter "/spec/"
end

test_dir = File.dirname(__FILE__)
$LOAD_PATH.unshift test_dir unless $LOAD_PATH.include?(test_dir)

lib_dir = File.join(File.dirname(test_dir), 'lib')
$LOAD_PATH.unshift lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'docile'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end