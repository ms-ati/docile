$:.push File.expand_path('../lib', __FILE__)
require 'docile/version'

Gem::Specification.new do |s|
  s.name        = 'docile'
  s.version     = Docile::VERSION
  s.authors     = ['Marc Siegel']
  s.email       = %w(msiegel@usainnov.com)
  s.homepage    = 'http://ms-ati.github.com/docile/'
  s.summary     = 'Docile keeps your Ruby DSLs tame and well-behaved'
  s.description = 'Docile turns any Ruby object into a DSL. Especially useful with the Builder pattern.'
  s.license     = 'MIT'

  s.rubyforge_project = 'docile'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)

  # Running rspec tests from rake
  s.add_development_dependency 'rake', '~> 10.1.1'
  s.add_development_dependency 'rspec', '~> 2.14.0'
  s.add_development_dependency 'mime-types', '~> 1.25.1'

  if defined?(RUBY_ENGINE) && 'rbx' == RUBY_ENGINE
    s.add_development_dependency 'rubysl'
    s.add_development_dependency 'rubinius-coverage'
  end

  if !(defined?(RUBY_ENGINE) && 'jruby' == RUBY_ENGINE)
    # Github flavored markdown in YARD documentation
    # http://blog.nikosd.com/2011/11/github-flavored-markdown-in-yard.html
    s.add_development_dependency 'yard'
    s.add_development_dependency 'redcarpet', '2.3.0' # because 1.8
    s.add_development_dependency 'github-markup'
  end

  # Coveralls test coverage tool
  s.add_development_dependency 'coveralls'
end
