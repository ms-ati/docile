source "https://rubygems.org"

# CI-only dependencies go here
if ENV["CI"] == "true"
  gem "simplecov-cobertura", require: false, group: "test"
end

# Specify gem's dependencies in docile.gemspec
gemspec
