require 'rubygems'
require 'rake'
require 'rake/rdoctask'

namespace :doc do
  desc "Generate documentation for key areas of the SEEK API"
  Rake::RDocTask.new("seek") { |rdoc|
    rdoc.rdoc_dir = 'doc/seek'
    rdoc.template = ENV['template'] if ENV['template']
    rdoc.title = ENV['title'] || "Sysmo-SEEK Technical and API Documentation"
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.options << '--charset' << 'utf-8'
    rdoc.rdoc_files.include('doc/README_FOR_APP')
#    rdoc.rdoc_files.include('doc/JERM')
#    rdoc.rdoc_files.include('doc/ARCHITECTURE')
    rdoc.rdoc_files.include('doc/CREDITS')
    rdoc.rdoc_files.include('doc/INSTALL')
    rdoc.rdoc_files.include('doc/UPGRADING')
    rdoc.rdoc_files.include('doc/BACKUPS')
#    rdoc.rdoc_files.include('app/**/*.rb')

#    rdoc.rdoc_files.include('lib/jerm/resource.rb')
#    rdoc.rdoc_files.include('lib/jerm/harvester.rb')
#    rdoc.rdoc_files.include('lib/jerm/populator.rb')
#    rdoc.rdoc_files.include('lib/jerm/embedded_populator.rb')
#    rdoc.rdoc_files.include('lib/jerm/restful_populator.rb')
#    rdoc.rdoc_files.include('lib/seek/remote_downloader.rb')
#    rdoc.rdoc_files.include('lib/jerm/downloader_factory.rb')
  }
end
