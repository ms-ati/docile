# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "docile/version"

Gem::Specification.new do |s|
  s.name        = "docile"
  s.version     = Docile::VERSION
  s.authors     = ["Marc Siegel"]
  s.email       = ["msiegel@usainnov.com"]
  s.homepage    = "http://docile.github.com"
  s.summary     = "Docile helps keep your DSLs tame and well-behaved'"
  s.description = "Docile handles ruby DSL evaluation best-practices so you can concentrate on your project"

  s.rubyforge_project = "docile"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", "~> 2.7.0"
  s.add_development_dependency "yard"
  s.add_development_dependency "redcarpet"
end
