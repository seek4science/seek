# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'resource'

module Jerm
  class TranslucentResource < Resource
    def initialize item      
      @type=item[:type]
      @node=item[:node]
      @project=project_name
    end

    def populate
      #puts @node
    end

    def project_name
      "Translucent"
    end
  end
end
