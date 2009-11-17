# To change this template, choose Tools | Templates
# and open the template in the editor.

module Jerm
  class Populator

    def populate resource
      resource.populate
      puts resource.to_s
    end
    
  end
end
