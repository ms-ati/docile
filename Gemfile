source "https://rubygems.org"

# Specify gem's dependencies in docile.gemspec
gemspec

# Explicitly require test gems for Travis CI, since we're excluding dev dependencies
group :test do
  gem "rake", "~> 0.9.2"
  gem "rspec", "~> 2.11.0"
end