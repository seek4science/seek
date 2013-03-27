require File.expand_path(File.join(File.dirname(__FILE__), '..','..','..', 'config', 'environment'))

Seek::Rdf::RdfWatcher.new(ARGV).start