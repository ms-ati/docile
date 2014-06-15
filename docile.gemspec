require File.expand_path('on_what', File.dirname(__FILE__))
$:.push File.expand_path('../lib', __FILE__)
require 'docile/version'

Gem::Specification.new do |s|
  s.name        = 'docile'
  s.version     = Docile::VERSION
  s.authors     = ['Marc Siegel']
  s.email       = %w(msiegel@usainnov.com)
  s.homepage    = 'https://ms-ati.github.io/docile/'
  s.summary     = 'Docile keeps your Ruby DSLs tame and well-behaved'
  s.description = 'Docile turns any Ruby object into a DSL. Especially useful with the Builder pattern.'
  s.license     = 'MIT'

  s.rubyforge_project = 'docile'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)

  # Running rspec tests from rake
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.0.0'

  # To limit needed compatibility with versions of dependencies, only configure
  #   yard doc generation when *not* on Travis, JRuby, or 1.8
  if !on_travis? && !on_jruby? && !on_1_8?
    # Github flavored markdown in YARD documentation
    # http://blog.nikosd.com/2011/11/github-flavored-markdown-in-yard.html
    s.add_development_dependency 'yard'
    s.add_development_dependency 'redcarpet'
    s.add_development_dependency 'github-markup'
  end

  # Coveralls test coverage tool
  s.add_development_dependency 'coveralls'
end
