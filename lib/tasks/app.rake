require 'rubygems'
require 'rake'

namespace :app do
  desc 'Displays the current version.'
  task(version: :environment) do
    puts Seek::Version.read
  end
end
