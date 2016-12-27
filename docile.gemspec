require File.expand_path('on_what', File.dirname(__FILE__))
$:.push File.expand_path('../lib', __FILE__)
require 'docile/version'

Gem::Specification.new do |s|
  s.name        = 'docile'
  s.version     = Docile::VERSION
  s.author      = 'Marc Siegel'
  s.email       = 'marc@usainnov.com'
  s.homepage    = 'https://ms-ati.github.io/docile/'
  s.summary     = 'Docile keeps your Ruby DSLs tame and well-behaved'
  s.description = 'Docile turns any Ruby object into a DSL. Especially useful with the Builder pattern.'
  s.license     = 'MIT'

  # Files included in the gem
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)

  # Specify oldest supported Ruby version
  s.required_ruby_version = '>= 1.8.7'

  # Run rspec tests from rake
  s.add_development_dependency 'rake', '~> 10.5.0' if on_less_than_1_9_3? # Pin compatible rake on old rubies, see: https://github.com/travis-ci/travis.rb/issues/380
  s.add_development_dependency 'rake', '< 11.0'    unless on_less_than_1_9_3? # See http://stackoverflow.com/questions/35893584/nomethoderror-undefined-method-last-comment-after-upgrading-to-rake-11
  s.add_development_dependency 'rspec', '~> 3.0.0'

  # NOTE: needed for Travis builds on 1.8, but can't yet reproduce failure locally
  s.add_development_dependency 'mime-types' , '~> 1.25.1' if on_1_8?
  s.add_development_dependency 'rest-client', '~> 1.6.8'  if on_1_8?

  # To limit needed compatibility with versions of dependencies, only configure
  #   yard doc generation when *not* on Travis, JRuby, or 1.8
  if !on_travis? && !on_jruby? && !on_1_8?
    # Github flavored markdown in YARD documentation
    # http://blog.nikosd.com/2011/11/github-flavored-markdown-in-yard.html
    s.add_development_dependency 'yard'
    s.add_development_dependency 'redcarpet'
    s.add_development_dependency 'github-markup'
  end
end
