require 'rubygems'
require 'spreadsheet'
require 'open-uri'
require 'net/http'

module Jerm
  class MosesResource < Resource
  
    def populate      
      valid = false
      if self.uri.end_with?(".xls")
        valid = parse_spreadsheet
      end
      return valid
    end
    
    private 
    
    def parse_spreadsheet
      valid = false
      filename = "temp_ss_#{self.object_id}.xls"
      File.open(filename, 'w') {|f| f.write(open(self.uri).read)}
      ss = Spreadsheet.open(filename)
      sheet1 = ss.worksheet 0
      if !sheet1.row(0)[0].nil? && sheet1.row(0)[0].strip.downcase == "partner" #A1
        valid = old_format(sheet1)
      else 
        ss = Spreadsheet.open(filename) #Need to open again or it doesnt work for "Pulse_steady_fluxes.xls" - not sure why!
        sheet1 = ss.worksheet 'experiment'
        if sheet1
          if !sheet1.row(0)[0].nil? && sheet1.row(0)[0].strip.downcase == "explanations"
            valid = new_format(sheet1)
          elsif !sheet1.row(1)[0].nil? && sheet1.row(1)[0].strip.downcase == "objective"
            valid = other_format(sheet1)
          end
        end
      end
      File.delete(filename)
      return valid
    end
  
    
    #For the old style templates
    def old_format(worksheet)
      valid = false
      author_name = worksheet.row(11)[2] #C12
      if author_name =~ /^[a-zA-Z ]+$/
        self.author_first_name, self.author_last_name = author_name.split(" ", 2)
        valid = true
      end
      return valid
    end
    
    #For the new ones (the orangey-ones with lots of data)
    def new_format(worksheet)   
      valid = false
      row = 0      
      #Go down to the DATA_CREATED section...
      cell = worksheet.row(row += 1)[0] until ((!cell.nil? && cell.downcase == "data_created") || row > 200)
      unless row > 200
        row -= 1 #necessary because ruby can't do post increment!, and I want to read the last row that was read before
        offset = row
        
        #Go across, then down to the creation_date section...
        cell = worksheet.row(row += 1)[1] until ((!cell.nil? && cell.downcase == "creation_date") || row > 200)
        unless worksheet.row(row)[3].nil?
          self.timestamp = worksheet.row(row)[3]
        end
        
        #Go down to the person_created section...
        cell = worksheet.row(row += 1)[1] until ((!cell.nil? && cell.downcase == "person_created") || row > 200)
        #The author name will be two columns over from this cell
        unless (author_name = worksheet.row(row)[3]).nil?          
          self.author_first_name, self.author_last_name = author_name.split(" ", 2)
        end        
        valid = true
      end
      return valid      
    end
    
    #Other format that I've discovered... blue with a big orange header
    def other_format(worksheet)
      valid = false
      row = 0
      #Go down to the experiment section...
      cell = worksheet.row(row += 1)[0] until ((!cell.nil? && cell.downcase == "experiment") || row > 200)
      unless row > 200
        row -= 1 #necessary because ruby can't do post increment!, and I want to read the last row that was read before
        offset = row
        #Go across, then down to the 'experimentator' section...
        cell = worksheet.row(row += 1)[1] until ((!cell.nil? && cell.downcase == "experimentator") || row > 200)
        unless (author_name = worksheet.row(row)[2]).nil?          
          self.author_first_name, self.author_last_name = author_name.split(" ", 2)
        end 
        valid = true
      end      
      return valid
    end
  end
end
