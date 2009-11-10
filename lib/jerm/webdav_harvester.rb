# To change this template, choose Tools | Templates
# and open the template in the editor.
require 'jerm/harvester'

class WebdavHarvester < Harvester
  
  def initialize username,password
    @username=username
    @password=password
  end

  def authenticate
    raise Exception.new("No username") if @username.nil?
    raise Exception.new("No password") if @password.nil?
  end
  
end
