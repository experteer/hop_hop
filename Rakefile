require "bundler/gem_tasks"
require 'fileutils'

def cd_root
  File.expand_path(File.dirname(__FILE__))
end

desc 'run specs'
task :specs do
  opts = %w(rspec -c)
  opts += ["--require", File.join(File.dirname(__FILE__), 'spec', 'spec_helper')]
  # opts += ['-I', YARD::ROOT]
  if ENV['DEBUG']
    $DEBUG = true
    opts += ['-d']
  end
  opts += FileList["spec/**/*_spec.rb"].sort
  cmd = opts.join(' ')
  puts cmd if Rake.application.options.trace
  system(cmd)
  raise "Command failed with status (#{$CHILD_STATUS.to_i}): #{cmd}" if $CHILD_STATUS.to_i != 0
end
task :spec => :specs

desc 'build gem and push to gem inabox'
task :gem_inabox_release do
  cmd = "gem build hop_hop.gemspec; gem inabox hop_hop-#{HopHop::VERSION}.gem"
  puts cmd if Rake.application.options.trace
  system(cmd)
end

require 'rubocop/rake_task'

Rubocop::RakeTask.new

task :default => :spec
desc 'alias for init:all'
task :init => "init:all"

namespace :init do

  desc 'initialize everything'
  task :all => ["git_hooks"]

  desc 'copy the git-hooks'
  task :git_hooks do
    cd_root
    mkdir ".git/hooks" unless File.exist?(".git/hooks")
    ln_sf "../../misc/git/pre-commit", ".git/hooks"
    # ln_sf "../../misc/git/post-checkout", ".git/hooks"
    # ln_sf "../../misc/git/post-merge", ".git/hooks"
  end

end
