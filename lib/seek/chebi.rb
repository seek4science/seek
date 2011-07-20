# BioCatalogue: lib/bio_catalogue/api.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module to abstract out any specific processing for the REST XML/JSON/etc API

# Taken from our friends Biocatalogue http://www.biocatalogue.org

require 'soap/wsdlDriver'


module Seek
  class Chebi
    def self.getCompleteEntity
      begin
        wsdl = SOAP::WSDLDriverFactory.new("http://hitssv506.h-its.org:80/sabiork?wsdl")
        a = wsdl.create_rpc_driver
         puts 'aaaaaaaaaaaaaaaaaaaaaaaa'
        puts a.getCHEBIID('water')
      rescue => err
         puts err.message
      end
    end
  end
end