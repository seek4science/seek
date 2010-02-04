# To change this template, choose Tools | Templates
# and open the template in the editor.
module Jerm
  class HttpDownloader < ResourceDownloader
    def get_remote_data url
      return basic_auth url
    end  
  end
end