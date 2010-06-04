# To change this template, choose Tools | Templates
# and open the template in the editor.

module Jerm
  class Resource
    AUTH_TYPES={:default=>"DEFAULT",:project=>"PROJECT",:sysmo=>"SYSMO",:public=>"PUBLIC"}
    
    attr_accessor :project, :uri, :author_first_name, :author_last_name,:author_seek_id,:timestamp,:type, :filename, :title, :description, :duplicate, :error, :authorization
    
    def to_s
      "Owner: #{author_name} (#{author_seek_id}), Project: #{project}, URI: #{uri}, Type: #{type}, Timestamp: #{timestamp}"
    end
    
    def author_name
      "#{author_first_name} #{author_last_name}"
    end
    
    def authorization
      if (@authorization.nil?)
        return AUTH_TYPES[:default]
      else
        @authorization
      end
    end        
    
  end
end
