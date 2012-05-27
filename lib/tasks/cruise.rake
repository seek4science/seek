require 'rubygems'
require 'rake'
require 'fileutils'
require 'bundler'

def run_in_parallel(cmd, options)
  count = "-n #{options[:count]}" if options[:count]
  executable = 'parallel_test'
  command = "#{executable} --exec '#{cmd}' #{count} #{'--non-parallel' if options[:non_parallel]}"
  abort unless system(command)
end

desc "task for cruise control"
task :cruise, :run_secondary do |t, args|
  args.with_defaults :run_secondary => true, :count => 8  #count determines the number of processes that parallel_tests will use
  run_secondary_signal = "#{RAILS_ROOT}/tmp/run_secondary_tests"
  if args[:run_secondary]
    File.new(run_secondary_signal, 'w') unless File.exists? run_secondary_signal
  else
    File.delete(run_secondary_signal) if File.exists? run_secondary_signal
  end
  RAILS_ENV = ENV['RAILS_ENV'] = 'test'

  FileUtils.copy(Dir.pwd+"/config/database.cc.yml", Dir.pwd+"/config/database.yml")

  Rake::Task["parallel:test"].invoke(args[:count])

  File.delete(run_secondary_signal) if File.exists? run_secondary_signal
end
