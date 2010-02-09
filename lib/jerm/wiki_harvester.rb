require 'hpricot'
require 'open-uri'
require 'net/http'
require 'net/https'
module Jerm
  class WikiHarvester < Harvester    
  
    protected
  
    #Turn relative paths into complete urls
    def complete_url(url, base)
      if url.start_with?("/")
        resource_uri = base + url
      else
        resource_uri = url
      end    
      return resource_uri
    end  
    
    #extract the base url from a url, eg.:
    # http://www.website.com/folder/file.ext
    # becomes: http://www.website.com/
    def extract_base_url(uri)
      root = uri.split("/",4)
      root[0] + "//" + root[2]
    end
  end
end
