module Jerm
  class SumoResource < Resource
    
    attr_accessor :work_package, :experimenters
    
    def populate      
      if title.blank? && type=="Sop" && uri
        extract_title_from_sop_text
      end
    end

    def initialize
      self.project = "SUMO"
    end

    private

    #attempts to extract the title from the wiki markup
    def extract_title_from_sop_text
      p=Project.find(:first,:conditions=>['name = ?',project])
      if p
        p.decrypt_credentials
        downloader = DownloaderFactory.create project
        data_hash = downloader.get_remote_data(uri,p.site_username,p.site_password,"Sop")
        matches = data_hash[:data].scan(/= [^=]* =/)
        if matches.length>1
          proposed_title=matches[0]
          if proposed_title.length>4 #i.e contains some text as the title
            self.title = proposed_title[2..-3] #remove the first 2, and last 2 characters (the = plus space)
          end
        end
      end      
    end
    
  end
  
end