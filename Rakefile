require "bundler/gem_tasks"

desc 'run specs'
task :specs do
  opts = ['rspec', '-c']
  opts += ["--require", File.join(File.dirname(__FILE__), 'spec', 'spec_helper')]
  #opts += ['-I', YARD::ROOT]
  if ENV['DEBUG']
    $DEBUG = true
    opts += ['-d']
  end
  opts += FileList["spec/**/*_spec.rb"].sort
  cmd = opts.join(' ')
  puts cmd if Rake.application.options.trace
  system(cmd)
  raise "Command failed with status (#{$?.to_i}): #{cmd}" if $?.to_i != 0
end
task :spec => :specs

desc 'build gem and push to gem inabox'
task :gem_inabox_release do
  cmd= "gem build hop_hop.gemspec; gem inabox hop_hop-#{HopHop::VERSION}.gem"
  puts cmd if Rake.application.options.trace
  system(cmd)
end

require 'rubocop/rake_task'

Rubocop::RakeTask.new


task :default => :spec
