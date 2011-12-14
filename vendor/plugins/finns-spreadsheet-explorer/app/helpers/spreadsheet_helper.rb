module SpreadsheetHelper
  
  include SpreadsheetUtil

  def escaped_sheet_name sheet
    sheet.name.gsub(" ","_").gsub(".","_").to_s
  end

end  