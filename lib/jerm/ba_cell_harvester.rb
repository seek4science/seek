# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'alfresco_harvester'
require 'ba_cell_resource'

module Jerm
  class BaCellHarvester < AlfrescoHarvester

    def construct_resource item
      BaCellResource.new(item,@username,@password)
    end

    def project_name
      "BaCell"
    end
  end
end