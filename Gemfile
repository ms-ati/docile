# frozen_string_literal: true

source "https://rubygems.org"

# Specify gem's runtime dependencies in docile.gemspec
gemspec

group :test do
  gem "rspec", "~> 3.13"
  gem "simplecov", require: false

  # CI-only test dependencies go here
  if ENV.fetch("CI", nil) == "true"
    gem "simplecov-cobertura", require: false, group: "test"
  end
end

# Excluded from CI except on latest MRI Ruby, to reduce compatibility burden
group :checks do
  gem "panolint-ruby", github: "panorama-ed/panolint-ruby", branch: "main"
  gem "rubocop-rake", require: false
end

# Optional, only used locally to release to rubygems.org
group :release, optional: true do
  gem "rake"
end
