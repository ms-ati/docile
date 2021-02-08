# NOTE: Very simple tests for what system we are on, extracted for sharing
#   between Rakefile, gemspec, and spec_helper. Not for use in actual library.

def on_travis?
  ENV["CI"] == "true"
end

def on_jruby?
  defined?(RUBY_ENGINE) && "jruby" == RUBY_ENGINE
end

def on_less_than_2_0?
  RUBY_VERSION < "2.0.0"
end

def on_less_than_2_3?
  RUBY_VERSION < "2.3.0"
end
