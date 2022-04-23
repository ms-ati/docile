# frozen_string_literal: true

# Code coverage (via SimpleCov)
require "simplecov"

SimpleCov.start do
  add_filter "/spec/"      # exclude test code
  add_filter "/vendor/"    # exclude gems which are cached in CI
end

# On CI we publish coverage to codecov.io
# To use the codecov action, we need to generate XML based coverage report
if ENV.fetch("CI", nil) == "true"
  begin
    require "simplecov-cobertura"
    SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  rescue LoadError
    warn "simplecov-cobertura gem not found - not generating XML for codecov.io"
  end
end

# Due to circular dependency (SimpleCov depends on Docile), remove docile and
# then require the docile gem again below.
Object.send(:remove_const, :Docile)
$LOADED_FEATURES.reject! { |f| f.include?("/lib/docile") }

# Require Docile again, now with coverage enabled
lib_dir = File.join(File.dirname(File.dirname(__FILE__)), "lib")
$LOAD_PATH.unshift lib_dir unless $LOAD_PATH.include? lib_dir
require "docile"
