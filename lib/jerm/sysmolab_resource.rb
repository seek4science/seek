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
      if self.uri.ends_with?(".xls")
        valid = parse_spreadsheet
      end
      return valid
    end
    
    private 
    
    def parse_spreadsheet
      valid = false
      filename = "temp_ss_#{self.object_id}.xls"
      File.open(filename, 'w') {|f| f.write(open(self.uri, :http_basic_authentication=>[@username, @password]).read)}
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