require File.expand_path('on_what', File.dirname(__FILE__))
source 'https://rubygems.org'

# Travis-only dependencies go here
if on_travis? && !on_1_8?
  group :test do
    gem 'codecov', :require => false
  end
end

# Specify gem's dependencies in docile.gemspec
gemspec
