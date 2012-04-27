#Methods concerning the parsing of spreadsheets

require 'simple-spreadsheet-extractor'
require 'libxml'

module SpreadsheetUtil
  
  include SpreadsheetRepresentation
  include SysMODB::SpreadsheetExtractor

  EXTRACTABLE_FILE_SIZE=1*1024*1024

  #is excel and is smaller than 10Mb
  def is_extractable_spreadsheet?
    is_excel? && !content_blob.filesize.nil? && content_blob.filesize<=EXTRACTABLE_FILE_SIZE
  end

  def is_excel?
    self.content_type == "application/vnd.ms-excel" ||
    self.content_type == "application/vnd.excel" ||
    self.content_type == "application/excel" ||
    self.content_type == "application/x-msexcel" ||
    self.content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def spreadsheet_annotations
    content_blob.worksheets.collect {|w| w.cell_ranges.collect {|c| c.annotations}}.flatten
  end

  #Return the data file's spreadsheet
  #If it doesn't exist yet, it gets created
  def spreadsheet
    if is_extractable_spreadsheet?
      workbook = parse_spreadsheet_xml(spreadsheet_xml)
      if content_blob.worksheets.empty?
        workbook.sheets.each_with_index do |sheet, sheet_number|
          content_blob.worksheets << Worksheet.create(:sheet_number => sheet_number, :last_row => sheet.last_row, :last_column => sheet.last_col)
        end
        content_blob.save
      end
      return workbook
    else
      return nil
    end
  end

  #Return the data file's spreadsheet XML
  #If it doesn't exist yet, it gets created
  def spreadsheet_xml
    if is_extractable_spreadsheet?
      Rails.cache.fetch("#{content_blob.cache_key}-ss-xml") do
        spreadsheet_to_xml(open(content_blob.filepath))
      end
    else
      nil
    end
  end
  
  #Takes in a string containing the xml representation of a spreadsheet and returns
  # a Workbook object
  def parse_spreadsheet_xml(spreadsheet_xml)
    workbook = Workbook.new
    
    doc = LibXML::XML::Parser.string(spreadsheet_xml).parse
    doc.root.namespaces.default_prefix="ss"
    
    doc.find("//ss:style").each do |s|
      style = Style.new(s["id"])
      s.children.each do |a|
        style.attributes[a.name] = a.content unless (a.name == "text")
      end
      workbook.styles[style.name] = style
    end


   doc.find("//ss:sheet").each do |s|
     unless s["hidden"] == "true" || s["very_hidden"] == "true"
       sheet = Sheet.new(s["name"])
       workbook.sheets << sheet
       #Load into memory
       min_rows = 10
       min_cols = 10
         #Grab columns
       columns = s.find("./ss:columns/ss:column")
       col_index = 0
       #Add columns
       columns.each do |c|
         col_index = c["index"].to_i
         col = Column.new(col_index, c["width"])
         sheet.columns << col
       end
       #Pad columns (so it's at least 10 cols wide)
       if col_index < min_cols
         for i in ((col_index+1)..min_cols)
           col = Column.new(i, 2964.to_s)
           sheet.columns << col
         end
       else
         min_cols = col_index
       end
         #Grab rows
       rows = s.find("./ss:rows/ss:row")
       row_index = 0
       #Add rows
       rows.each do |r|
         row_index = r["index"].to_i
         row = Row.new(row_index, r["height"])
         sheet.rows[row_index] = row
         #Add cells
         r.find("./ss:cell").each do |c|
           col_index = c["column"].to_i
           content = c.content
           content = content.to_f if c["type"] == "numeric"
           cell = Cell.new(content, row_index, col_index, c["formula"], c["style"])
           row.cells[col_index] = cell
         end
       end
       #Pad rows
       if row_index < min_rows
         for i in (row_index..min_rows)
           row = Row.new(i, 1000.to_s)
           sheet.rows << row
         end
         min_rows = 10
       else
         min_rows = row_index
       end
       sheet.last_row = min_rows
       sheet.last_col = min_cols
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
