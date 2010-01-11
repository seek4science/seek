# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'alfresco_harvester'
require 'ba_cell_sysmo_resource'

module Jerm
  class BaCellSysmoHarvester < AlfrescoHarvester

    def construct_resource item
      BaCellSysmoResource.new(item,@username,@password)
    end

    def project_name
      "BaCell-SysMO"
    end
  end
end