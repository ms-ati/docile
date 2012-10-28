require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "github/markup"
require "redcarpet"
require "yard"
require "yard/rake/yardoc_task"

YARD::Rake::YardocTask.new do |t|
  OTHER_PATHS = %w()
  t.files   = ['lib/**/*.rb', OTHER_PATHS]
  t.options = %w(--markup-provider=redcarpet --markup=markdown --main=README.md)
end

RSpec::Core::RakeTask.new

task :default => [:spec]