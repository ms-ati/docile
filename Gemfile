source "https://rubygems.org"

# Travis-only dependencies go here
if ENV["CI"] == "true"
  gem "codecov", require: false, group: "test"
end

# Specify gem's dependencies in docile.gemspec
gemspec
