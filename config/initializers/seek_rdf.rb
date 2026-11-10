require 'rightfield/rightfield'
require 'rdf/rdfxml'
require 'rdf/vocab'
# lib is not autoloadable until initialization has finished
Rails.application.config.after_initialize do
  Seek::Rdf::JSONLdContexts.preload
end
