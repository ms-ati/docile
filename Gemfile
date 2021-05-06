source "https://rubygems.org"

# CI-only dependencies go here
if ENV["CI"] == "true" && RUBY_ENGINE == "ruby"
  gem "codecov", require: false, group: "test"
end

# Specify gem's dependencies in docile.gemspec
gemspec
