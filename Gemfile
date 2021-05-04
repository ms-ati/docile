source "https://rubygems.org"

# Travis-only dependencies go here
if ENV["CI"] == "true" && RUBY_ENGINE == "ruby"
  gem "codecov", require: false, group: "test"
end

# Specify gem's dependencies in docile.gemspec
gemspec
