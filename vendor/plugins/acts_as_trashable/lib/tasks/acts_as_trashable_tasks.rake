require 'rake'

namespace :acts_as_trashable do
  
  desc "Empty the trash older than MAX_AGE seconds. You can limit the classes with a comma delimited list of classes for ONLY or EXCEPT"
  task :empty_trash => :environment do
    raise ArgumentError.new("you must specify a MAX_AGE in seconds") if ENV['MAX_AGE'].blank?
    options = {}
    options[:only] = ENV['ONLY'].split(',') unless ENV['ONLY'].blank?
    options[:except] = ENV['EXCEPT'].split(',') unless ENV['EXCEPT'].blank?
    TrashRecord.empty_trash(ENV['MAX_AGE'].to_i, options)
  end
  
end
