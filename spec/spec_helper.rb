require File.expand_path("on_what", File.dirname(File.dirname(__FILE__)))

# Code coverage (via SimpleCov) on Ruby 1.9+
unless on_1_8?
  begin
    require "simplecov"
    SimpleCov.start do
      add_filter "/spec/"      # exclude test code
      add_filter "/vendor/"    # exclude gems which are vendored on Travis CI
      add_filter "/on_what.rb" # exclude help used only in gemspec
    end

    # On CI we publish simplecov results to codecov.io
    if on_travis?
      require "codecov"
      SimpleCov.formatter = SimpleCov::Formatter::Codecov
    end

    # Due to circular dependency (simplecov depends on docile), remove docile and require again below
    Object.send(:remove_const, :Docile)
    $LOADED_FEATURES.reject! { |f| f =~ /\/docile\// }
  rescue LoadError
    warn "warning: simplecov or codecov gems not found; skipping coverage"
  end
end

lib_dir = File.join(File.dirname(File.dirname(__FILE__)), "lib")
$LOAD_PATH.unshift lib_dir unless $LOAD_PATH.include? lib_dir

# Require Docile again, now with coverage enabled on 1.9+
require "docile"
