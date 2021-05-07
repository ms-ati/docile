# Code coverage (via SimpleCov)
begin
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"      # exclude test code
    add_filter "/vendor/"    # exclude gems which are cached in CI
  end

  # On CI we publish coverage to codecov.io
  # To use codecov-action, we need to generate XML based covarage report
  if ENV["CI"] == "true"
    require "simplecov-cobertura"
    SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  end

  # Due to circular dependency (simplecov depends on docile), remove docile and require again below
  Object.send(:remove_const, :Docile)
  $LOADED_FEATURES.reject! { |f| f =~ /\/docile\// }
rescue LoadError
  warn "warning: simplecov or codecov gems not found; skipping coverage"
end

lib_dir = File.join(File.dirname(File.dirname(__FILE__)), "lib")
$LOAD_PATH.unshift lib_dir unless $LOAD_PATH.include? lib_dir

# Require Docile again, now with coverage enabled
require "docile"
