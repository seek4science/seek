require 'rubygems'
require 'spreadsheet'
require 'open-uri'
require 'net/http'

module Jerm
  class MosesResource < Resource
  
    def populate
      filename = "temp_ss_#{self.object_id}.xls"
      File.open(filename, 'w') {|f| f.write(open(self.uri).read)}
      ss = Spreadsheet.open(filename)
      sheet1 = ss.worksheet 0
      valid = false
      if sheet1.row(0)[0] == "Partner" #A1
        author_name = sheet1.row(11)[2] #C12
        self.author_first_name, self.author_last_name = author_name.split(" ", 2)
        valid = true
      end
      File.delete(filename)
      return valid
    end
    
  end
end