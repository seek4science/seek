require 'rubygems'
require 'spreadsheet'
require 'open-uri'
require 'net/http'

module Jerm
  class SysmodbResource < Resource
    
    attr_accessor :work_package, :experimenters
    
    def populate      
      if title.blank? && type=="Sop" && uri
        extract_title_from_sop_text
      end
      if self.uri.end_with?(".xls")
        doc = open(self.uri, :http_basic_authentication=>[@username, @password])
        parse_spreadsheet(doc)
      end
    end

    def initialize
      self.project = "SysMO-DB"
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
    
    def parse_spreadsheet(file)
      puts "PARSING"
      filename = "temp_ss_#{self.object_id}.xls"
      File.open(filename, 'w') {|f| f.write(file.read)}
      ss = Spreadsheet.open(filename)
      sheet1 = ss.worksheet 'IDF'
      if sheet1
        #Find "Title"
        row = 0     
        cell = sheet1.row(row += 1)[0] until ((!cell.nil? && cell.downcase == "datafile title") || row > 200)
        unless row > 200
          unless (title = sheet1.row(row)[1]).nil?  
            self.title = title
          end
        end        
      end
      File.delete(filename)
    end    
    
  end  
end