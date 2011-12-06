require "bundler/gem_tasks"
require "yard"
require "yard/rake/yardoc_task"

YARD::Rake::YardocTask.new do |t|
  OTHER_PATHS = %w(README.md LICENSE)
  t.files   = ['lib/**/*.rb', OTHER_PATHS]
  t.options = ['--main README.md']
end
