require 'libxml'

module SpreadsheetViewer
  
  def parse_spreadsheet_xml(spreadsheet_xml)
    workbook = Workbook.new
    
    html = "" #
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
  
  private 
  
  def to_alpha(col)
    col = col-1 #needs to be 0 indexed
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split(//)    
    result = ""
    
    while (col > -1) do
      letter = (col % 26)
      result = alphabet[letter] + result
      col = (col / 26) - 1
    end
    result
  end
  
  public
  
  class Workbook
  
    attr_accessor :sheets
    attr_accessor :styles
    
    def initialize
      @sheets = []
      @styles = {}
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
  
  class Style
    attr_accessor :name
    attr_accessor :attributes
    
    def initialize(name)
      @name = name
      @attributes = {}
    end
    
    def [] attribute
      @attributes[attribute]
    end
    
  end

  
  class Sheet
    attr_accessor :rows
    attr_accessor :columns
    attr_accessor :name
    attr_accessor :last_row
    attr_accessor :last_col
    
    def initialize(n=nil, h=0)
      @rows = []  
      @columns = []
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
  
  class Column
    attr_accessor :index
    attr_accessor :width
    
    def initialize(c=nil, w=nil)
      @index = c
      @width = w unless w.blank?
    end
    
  end
  
  class Row
    attr_accessor :cells
    attr_accessor :index
    attr_accessor :height
    
    def initialize(r=nil, h=nil)
      @cells = []
      @index = r
      @height = h unless h.blank?
    end
    
    def cell(x)
      @cells[x]
    end
    
    def [] x
      @cells[x]
    end
  end
  
  class Cell
    attr_accessor :value
    attr_accessor :row
    attr_accessor :column
    attr_accessor :formula
    attr_accessor :style
       
    def initialize(v=nil, r=nil, c=nil, f=nil, s=nil)
      @value = v
      @row = r
      @column = c
      @formula = f
      @style = s unless s.blank?
    end
  end

end