module SpreadsheetRepresentation
  
  class Workbook
  
    attr_accessor :sheets
    attr_accessor :styles
    attr_accessor :annotations
    
    def initialize
      @sheets = []
      @styles = {}
      @annotations = []
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

    #Rows with content
    def actual_rows
      @rows.select {|r| !r.nil?}
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

    #Cells with content (present in XML - can still be blank with styles)
    def actual_cells
      @cells.select {|c| !c.nil?}
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

    def pretty_value
      if @value.class == Float
        return @value.round(3)
      else
        return @value
      end
    end
  end

end