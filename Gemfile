source "https://rubygems.org"

# Specify gem's dependencies in docile.gemspec
gemspec

# Explicitly require test gems for Travis CI, since we're excluding dev dependencies
group :test do
  gem 'rubysl', platform: :rbx # Since 2.2.0, Rubinius needs Ruby standard lib as gem
  gem "rake", "~> 0.9.2"
  gem "rspec", "~> 2.11.0"
  gem "mime-types", "~> 1.25.1"
  gem "coveralls", :require => false
end
