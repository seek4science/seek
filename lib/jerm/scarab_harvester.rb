# To change this template, choose Tools | Templates
# and open the template in the editor.

module Jerm
  class ScarabHarvester < WebDavHarvester

    def construct_resource item
      puts item[:full_path]
    end

    def key_directories
      []
    end
  
  end
end