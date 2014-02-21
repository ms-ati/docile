require 'simplecov'
require 'coveralls'

# On Ruby 1.9+ use SimpleCov and publish to Coveralls.io
if !RUBY_VERSION.start_with? '1.8'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start do
    add_filter '/spec/'    # exclude test code
    add_filter '/vendor/'  # exclude gems which are vendored on Travis CI
  end

  # Remove Docile, which was required by SimpleCov, to require again later
  Object.send(:remove_const, :Docile)
  $LOADED_FEATURES.reject! { |f| f =~ /\/docile\// }
end

lib_dir = File.join(File.dirname(File.dirname(__FILE__)), 'lib')
$LOAD_PATH.unshift lib_dir unless $LOAD_PATH.include? lib_dir

# Require Docile again, now with coverage enabled on 1.9+
require 'docile'

require 'singleton'
require 'rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end