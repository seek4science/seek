
require 'jerm/harvester'
require 'jerm/web_dav'

class WebDavHarvester < Harvester

  include WebDav
  
  def initialize username,password,base_uri
    @username=username
    @password=password
    @base_uri=base_uri
  end

  def authenticate
    raise Exception.new("No username") if @username.nil?
    raise Exception.new("No password") if @password.nil?
  end

  def changed_since time
    get_contents URI.parse(@base_uri),@username,@password,true
  end
  
end
