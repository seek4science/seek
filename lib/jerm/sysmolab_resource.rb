require 'rubygems'
require 'spreadsheet'
require 'open-uri'
require 'net/http'

module Jerm
  class SysmolabResource < Resource
  
    def initialize(user,pass)
      @username = user
      @password = pass
    end

    def populate
      valid = false
      doc = open(self.uri, :http_basic_authentication=>[@username, @password])
      self.timestamp = doc.last_modified
      if self.uri.end_with?(".xls")
        valid = parse_spreadsheet(doc)
      end
      return valid
    end
    
    private 
    
    def parse_spreadsheet(file)
      valid = false
      filename = "temp_ss_#{self.object_id}.xls"
      File.open(filename, 'w') {|f| f.write(file.read)}
      ss = Spreadsheet.open(filename)
      sheet1 = ss.worksheet 'Metadata'
      if sheet1
        #Find "Experimentator" cell
        row = 0      
        cell = sheet1.row(row += 1)[0] until ((!cell.nil? && cell.downcase == "experimentator") || row > 200)
        unless row > 200
          unless (author_name = sheet1.row(row)[1]).nil?  
            self.author_first_name, self.author_last_name = author_name.split(" ", 2)
            valid = true
          end
        end        
      end
      File.delete(filename)
      return valid
    end
    
  end
end
