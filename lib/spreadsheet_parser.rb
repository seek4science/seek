class Workbook
  
  attr_accessor :sheets
  
  def initialize(uri, type="xls")
    #Open workbook
    uri = URI_CLASS.new(uri)
    input = uri.toURL.openStream
    
    workbook = nil
    
    if type == "xlsx"
      workbook = XLSX_WORKBOOK_CLASS.new(STREAM_CLASS.new(input))
    else
      workbook = XLS_WORKBOOK_CLASS.new(STREAM_CLASS.new(input))
    end
    
    #Create sheets
    @sheets = []
    
    #get no. of sheets in POI workbook
    workbook.getNumberOfSheets.times do |i|      
      jsheet = workbook.getSheetAt(i)  #get sheet      
      sheet_name = jsheet.getSheetName
      sheet_hide = workbook.isSheetVeryHidden(i) ? 2 : (workbook.isSheetHidden(i) ? 1 : 0)
      sheet = Sheet.new(sheet_name, sheet_hide)
      
      (jsheet.getLastRowNum+1).times do |j| #iterate up to last row. note: last row of 0 can mean either theres only 1 row, or theres no rows at all
        sheet.rows[j] = Row.new        
        jrow = jsheet.getRow(j) #get row
        unless jrow.nil?
          jrow.getLastCellNum.times do |k| #iterate up to last cell of row
            jvalue = nil
            jcell = jrow.getCell(k)
            unless jcell.nil?
              case jcell.getCellType
                when CELL_CLASS.CELL_TYPE_FORMULA #when formula, check if result is a string or number
                  case jcell.getCachedFormulaResultType
                    when CELL_CLASS.CELL_TYPE_NUMERIC
                      jvalue = jcell.getNumericCellValue
                    when CELL_CLASS.CELL_TYPE_STRING
                      jvalue = jcell.getStringCellValue
                   end
                when CELL_CLASS.CELL_TYPE_NUMERIC
                  if DATEUTIL_CLASS.isCellDateFormatted(jcell)
                    #Convert to string and back because java date class isn't compatible with ruby one 
                    jvalue = jcell.getDateCellValue.toString.to_date
                  else
                    jvalue = jcell.getNumericCellValue
                  end                  
                when CELL_CLASS.CELL_TYPE_STRING
                  jvalue = jcell.getStringCellValue
              end      
              sheet.rows[j].cells[k] = Cell.new(jvalue,j,k)
            end
          end
        end
      end  
      @sheets << sheet
    end
  end
  
  def [] x
    sheet(x)
  end
  
  def sheet(x)
    if x.class.name == "String"
      @sheets.select {|s| s.name == x}.first
    elsif x.class.name == "Fixnum"
      @sheets[x]
    end
  end
  
end

class Sheet
  attr_accessor :rows
  attr_accessor :name
  
  def initialize(n=nil, h=0)
    @rows = []  
    @name = n
    @hidden = h
  end
  
  def row(x)
    @rows[x]
  end
  
  def [] x
    @rows[x]
  end
  
  def cell(x,y)
    @rows[x].cells[y]
  end
  
  def hidden?
    @hidden == 1
  end
  
  def very_hidden?
    @hidden == 2
  end
end

class Row
  attr_accessor :cells
  attr_accessor :index
  
  def initialize(r=nil)
    @cells = []
    @index = r
  end
  
  def cell(x)
    @cells[x]
  end
  
  def [] x
    @cells[x].value
  end
end

class Cell
  attr_accessor :value
  attr_accessor :row
  attr_accessor :column
 
  def initialize(v=nil, r=nil, c=nil)
    @value = v
    @row = r
    @column = c
  end
  
  def excel_column
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split(//)
    num = @column
    col = ""
    while (num+1) > 0
      col = alphabet[num % 26] + col
      num = (num / 26) - 1
    end
    return col
  end
end
