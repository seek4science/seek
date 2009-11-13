# To change this template, choose Tools | Templates
# and open the template in the editor.

module Jerm
  class ScarabHarvester < WebDavHarvester

    def construct_resource item
      ScarabResource.new(item,@username,@password)
    end

    def project_name
      "Scarab"
    end
  
  end
end