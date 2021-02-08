$:.push File.expand_path("../lib", __FILE__)
require File.expand_path("on_what", File.dirname(__FILE__))
require "docile/version"

Gem::Specification.new do |s|
  s.name        = "docile"
  s.version     = Docile::VERSION
  s.author      = "Marc Siegel"
  s.email       = "marc@usainnov.com"
  s.homepage    = "https://ms-ati.github.io/docile/"
  s.summary     = "Docile keeps your Ruby DSLs tame and well-behaved."
  s.description = "Docile treats the methods of a given ruby object as a DSL " \
                  "(domain specific language) within a given block. \n\n"      \
                  "Killer feature: you can also reference methods, instance "  \
                  "variables, and local variables from the original (non-DSL) "\
                  "context within the block. \n\n"                             \
                  "Docile releases follow Semantic Versioning as defined at "  \
                  "semver.org."
  s.license     = "MIT"

  # Files included in the gem
  s.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  s.require_paths = ["lib"]

  # Specify oldest supported Ruby version
  s.required_ruby_version = ">= 1.9.3"

  # Run rspec tests from rake even on old Ruby versions
  s.add_development_dependency "rake", "< 11.0" # See http://stackoverflow.com/questions/35893584/nomethoderror-undefined-method-last-comment-after-upgrading-to-rake-11
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rspec-expectations", "!= 3.8.3" # Workaround for RSpec's issue, see: https://github.com/rspec/rspec-expectations/issues/1111

  # To limit needed compatibility with versions of dependencies, only configure
  #   yard doc generation when *not* on Travis, JRuby, or < 2.3
  if !on_travis? && !on_jruby? && !on_less_than_2_3?
    # Github flavored markdown in YARD documentation
    # http://blog.nikosd.com/2011/11/github-flavored-markdown-in-yard.html
    s.add_development_dependency "yard"
    s.add_development_dependency "redcarpet"
    s.add_development_dependency "github-markup"
  end
end
