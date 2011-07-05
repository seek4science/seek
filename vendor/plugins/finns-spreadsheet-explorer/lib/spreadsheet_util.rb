#Methods concerning the parsing of spreadsheets

require 'libxml'

module SpreadsheetUtil
  
  include SpreadsheetRepresentation
  
  #Take in a string containing spreadsheet xml and returns
  # a Workbook object
  def parse_spreadsheet_xml(spreadsheet_xml)
    workbook = Workbook.new

    spreadsheet_xml = spreadsheet_xml.gsub(/xmlns=\"([^\"]*)\"/,"") #Strip NS
    
    doc = LibXML::XML::Parser.string(spreadsheet_xml).parse
    
    doc.find("//style").each do |s|
      style = Style.new(s["id"])
      s.children.each do |a|
        style.attributes[a.name] = a.content unless (a.name == "text")
      end
      workbook.styles[style.name] = style
    end
    
    doc.find("//sheet").each do |s|
      unless s["hidden"] == "true" || s["very_hidden"] == "true"
        sheet = Sheet.new(s["name"])
        workbook.sheets << sheet
        #Load into memory
        max_row = 0
        max_col = 0
        s.find(".//columns/column").each do |c|
          col_index = c["index"].to_i
          col = Column.new(col_index, c["width"])
          sheet.columns << col          
          if max_col < col_index
            max_col = col_index
          end
        end
        s.find(".//row").each do |r|
          row_index = r["index"].to_i
          row = Row.new(row_index, r["height"])
          sheet.rows[row_index] = row
          if max_row < row_index
            max_row = row_index
          end
          r.find(".//cell").each do |c|
            col_index = c["column"].to_i
            cell = Cell.new(c.content, row_index, col_index, c["formula"], c["style"])
            row.cells[col_index] = cell
          end
        end
        sheet.last_row = max_row
        sheet.last_col = max_col
      end
    end 
    
    workbook
  end 
  
  #Turns a numeric column ID into an Excel letter representation
  #eg. 1 > A, 10 > J, 28 > AB etc.
  def to_alpha(col)
    result = ""
    col = col-1
    while (col >= 0) do
      result = ((col % 26) + 65).chr + result
      col = (col / 26) - 1
    end
    result
  end  
  
  #Does the opposite of the above
  #eg. A > 1, J > 10, AB > 28 etc.
  def from_alpha(col)
    result = 0
    col = col.split(//)
    col.each_with_index do |c,i|
      result += (c.ord - 64) * (26 ** (col.length - (i+1)))
    end
    result
  end
  
end