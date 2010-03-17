# To change this template, choose Tools | Templates
# and open the template in the editor.

module Jerm
  class SumoDownloader < HttpDownloader
    
    def get_remote_data url, username=nil, password=nil, type=nil
      url=url+"?format=txt" if is_sop?(type) && !url.end_with?("=txt")
      data_hash = super(url, username, password)
      if is_sop?(type)
        data_hash[:data] = cut_document_end(data_hash[:data])
        data_hash[:filename]=data_hash[:filename]+".txt"
      end
      return data_hash
    end

    private

    #strips off the discussion and comments from the end
    def cut_document_end document
      pos=document.index("== Changes")
      document = document[0,pos] if pos
      pos=document.index("== Discuss")
      document = document[0,pos] if pos
      return document
    end

    def is_sop? type
      (type && type.downcase=="sop")
    end

  end
end
