require 'simple-spreadsheet-extractor'

module Seek
  module Data
    module SpreadsheetExplorerRepresentation
      include SysMODB::SpreadsheetExtractor

      MIN_ROWS = 35
      MIN_COLS = 10

      def supported_spreadsheet_format?
        content_blob && content_blob.is_supported_spreadsheet_format?
      end

      def contains_extractable_spreadsheet?
        supported_spreadsheet_format? && content_blob.is_extractable_spreadsheet?
      end

      def contains_extractable_excel?
        content_blob.is_extractable_excel?
      end

      def spreadsheet_annotations
        content_blob.worksheets.collect { |w| w.cell_ranges.collect(&:annotations) }.flatten
      end

      # Return the data file's spreadsheet
      # If it doesn't exist yet, it gets created
      def spreadsheet
        if contains_extractable_spreadsheet?
          workbook = parse_spreadsheet
          if content_blob.worksheets.empty?
            workbook.sheets.each_with_index do |sheet, sheet_number|
              content_blob.worksheets << Worksheet.create(sheet_number: sheet_number, last_row: sheet.last_row, last_column: sheet.last_col)
            end
            content_blob.save
          end
          return workbook
        else
          return nil
        end
      end

      # Return the data file's spreadsheet XML
      # If it doesn't exist yet, it gets created
      def spreadsheet_xml
        Rails.cache.fetch("blob_ss_xml-#{content_blob.cache_key}") do
          content_blob.to_spreadsheet_xml
        end
      end

      def spreadsheet_csv
        Rails.cache.fetch("blob_ss_csv-#{content_blob.cache_key}") do
          content_blob.extract_csv
        end
      end

      private

      def parse_spreadsheet
        if content_blob.is_excel?
          return parse_spreadsheet_xml(spreadsheet_xml)
        elsif content_blob.is_csv?
          return parse_spreadsheet_csv(spreadsheet_csv)
        elsif content_blob.is_tsv?
          return parse_spreadsheet_csv(spreadsheet_csv, "\t")
        else
          return nil          
        end
      end

      # Takes in a string containing the xml representation of a spreadsheet and returns
      # a Workbook object
      def parse_spreadsheet_xml(spreadsheet_xml)
        workbook = Workbook.new

        doc = LibXML::XML::Parser.string(spreadsheet_xml).parse
        doc.root.namespaces.default_prefix = 'ss'

        doc.find('//ss:style').each do |s|
          style = Style.new(s['id'])
          s.children.each do |a|
            style.attributes[a.name] = a.content unless a.name == 'text'
          end
          workbook.styles[style.name] = style
        end

        doc.find('//ss:sheet').each do |s|
          next if s['hidden'] == 'true' || s['very_hidden'] == 'true'
          sheet = Sheet.new(s['name'])
          workbook.sheets << sheet
          # Load into memory
          min_rows = MIN_ROWS
          min_cols = MIN_COLS
          # Grab columns
          columns = s.find('./ss:columns/ss:column')
          col_index = 0
          # Add columns
          columns.each do |c|
            col_index = c['index'].to_i
            col = Column.new(col_index, c['width'])
            sheet.columns << col
          end
          # Pad columns (so it's at least 10 cols wide)
          if col_index < min_cols
            for i in ((col_index + 1)..min_cols)
              col = Column.new(i, 2964.to_s)
              sheet.columns << col
            end
          else
            min_cols = col_index
          end
          # Grab rows
          rows = s.find('./ss:rows/ss:row')
          row_index = 0
          # Add rows
          rows.each do |r|
            row_index = r['index'].to_i
            row = Row.new(row_index, r['height'])
            sheet.rows[row_index] = row
            # Add cells
            r.find('./ss:cell').each do |c|
              col_index = c['column'].to_i
              content = c.content
              cell = Cell.new(content, row_index, col_index, c['formula'], c['style'])
              row.cells[col_index] = cell
            end
          end
          # Pad rows
          if row_index < min_rows
            for i in ((row_index + 1)..min_rows)
              row = Row.new(i, 1000.to_s)
              sheet.rows << row
            end
            min_rows = MIN_ROWS
          else
            min_rows = row_index
          end
          sheet.last_row = min_rows
          sheet.last_col = min_cols
        end

        workbook
      end
      
      # Takes in a string containing the csv representation of a spreadsheet and returns
      # a Workbook object
      def parse_spreadsheet_csv(spreadsheet_csv, col_sep=nil)
        workbook = Workbook.new

        if col_sep.nil?
          csv = CSV.parse(spreadsheet_csv, quote_char: "\x00")
        else
          csv = CSV.parse(spreadsheet_csv, col_sep: col_sep, quote_char: "\x00")
        end

        sheet = Sheet.new('Sheet1')
        workbook.sheets << sheet

        # set a default style
        style = Style.new("default")
        style.attributes["font-size"] = "11pt"
        style.attributes["color"] = "#000000"
        workbook.styles[style.name] = style

        # Load into memory
        min_rows = MIN_ROWS
        min_cols = MIN_COLS

        # Initialise column width to default width
        col_index=0
        csv[0].each_with_index do |c, index|
          col_index = index + 1
          col = Column.new(col_index, 2964.to_s)
          sheet.columns << col
        end

        # Pad columns (so it's at least 10 cols wide)
        if csv[0].length < min_cols
          for i in ((col_index + 1)..min_cols)
            col = Column.new(i, 2964.to_s)
            sheet.columns << col
          end
        else
          min_cols = csv[0].length
        end
        
        # Grab rows
        row_index = 0
        csv.each_with_index do |r, index|
          # row = Row.new(row_index, r['height'])
          row_index = index + 1
          row = Row.new(row_index)
          sheet.rows[row_index] = row
          # Add cells
          r.each_with_index do |c, index|
            # col_index = c['column'].to_i
            col_index = index + 1
            content = c
            # csv won't have formulas or style
            cell = Cell.new(content, row_index, col_index, nil, 'default')
            row.cells[col_index] = cell
          end
        end

        # Pad rows
        if row_index < min_rows
          for i in ((row_index + 1)..min_rows)
            row = Row.new(i, 1000.to_s)
            sheet.rows << row
          end
          min_rows = MIN_ROWS
        else
          min_rows = row_index
        end
        sheet.last_row = min_rows
        sheet.last_col = min_cols

        workbook
      end


      # Turns a numeric column ID into an Excel letter representation
      # eg. 1 > A, 10 > J, 28 > AB etc.
      def to_alpha(col)
        result = ''
        col -= 1
        while (col >= 0)
          result = ((col % 26) + 65).chr + result
          col = (col / 26) - 1
        end
        result
      end

      # Does the opposite of the above
      # eg. A > 1, J > 10, AB > 28 etc.
      def from_alpha(col)
        result = 0
        col = col.split(//)
        col.each_with_index do |c, i|
          result += (c.ord - 64) * (26**(col.length - (i + 1)))
        end
        result
      end

      class Workbook
        attr_accessor :sheets
        attr_accessor :styles
        attr_accessor :annotations

        def initialize
          @sheets = []
          @styles = {}
          @annotations = []
        end

        def [](x)
          sheet(x)
        end

        def sheet(x)
          if x.class.name == 'String'
            @sheets.find { |s| s.name == x }
          elsif x.class.name == 'Fixnum'
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

        def [](attribute)
          @attributes[attribute]
        end
      end

      class Sheet
        attr_accessor :rows
        attr_accessor :columns
        attr_accessor :name
        attr_accessor :last_row
        attr_accessor :last_col

        def initialize(n = nil, h = 0)
          @rows = []
          @columns = []
          @name = n
          @hidden = h
        end

        def row(x)
          @rows[x]
        end

        def [](x)
          @rows[x]
        end

        def cell(x, y)
          @rows[x].cells[y]
        end

        def hidden?
          @hidden == 1
        end

        def very_hidden?
          @hidden == 2
        end

        # Rows with content
        def actual_rows
          @rows.compact
        end
      end

      class Column
        attr_accessor :index
        attr_accessor :width

        def initialize(c = nil, w = nil)
          @index = c
          @width = w unless w.blank?
        end
      end

      class Row
        attr_accessor :cells
        attr_accessor :index
        attr_accessor :height

        def initialize(r = nil, h = nil)
          @cells = []
          @index = r
          @height = h unless h.blank?
        end

        def cell(x)
          @cells[x]
        end

        def [](x)
          @cells[x]
        end

        # Cells with content (present in XML - can still be blank with styles)
        def actual_cells
          @cells.compact
        end
      end

      class Cell
        attr_accessor :value
        attr_accessor :row
        attr_accessor :column
        attr_accessor :formula
        attr_accessor :style

        def initialize(v = nil, r = nil, c = nil, f = nil, s = nil)
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
  end
end
