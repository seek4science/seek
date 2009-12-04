# To change this template, choose Tools | Templates
# and open the template in the editor.
require 'jerm/resource'

module Jerm
  class WebDavResource < Resource
    def initialize item
      @item=item
    end
  end
end