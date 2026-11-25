require 'simple-spreadsheet-extractor'

module Seek
  module Data
    module SpreadsheetExplorerRepresentation
      include SysMODB::SpreadsheetExtractor

      MIN_ROWS = 35
      MIN_COLS = 10
      DEFAULT_COLUMN_WIDTH = '2964'.freeze
      # shared by every CSV/TSV cell, rather than allocating a new 'default' string per cell
      DEFAULT_STYLE = 'default'.freeze

      def supported_spreadsheet_format?
        content_blob && content_blob.is_supported_spreadsheet_format?
      end

      def contains_extractable_spreadsheet?
        supported_spreadsheet_format? && content_blob.is_extractable_spreadsheet?
      end

      def contains_extractable_excel?
        content_blob.is_extractable_excel?
      end

      # Return the data file's spreadsheet
      # If it doesn't exist yet, it gets created
      def spreadsheet
        if contains_extractable_spreadsheet?
          workbook = parse_spreadsheet
          if content_blob.worksheets.empty?
            workbook.sheets.each_with_index do |sheet, sheet_number|
              content_blob.worksheets << Worksheet.create(sheet_number: sheet_number, last_row: sheet.last_row,
                                                          last_column: sheet.last_col)
            end
            content_blob.save
          end
          workbook
        end
      end

      # Return the data file's spreadsheet XML
      # If it doesn't exist yet, it gets created
      def spreadsheet_xml
        Rails.cache.fetch("blob_ss_xml-#{content_blob.cache_key}", expires_in: 30.days) do
          content_blob.to_spreadsheet_xml
        end
      end

      private

      def parse_spreadsheet
        if content_blob.is_excel?
          parse_spreadsheet_xml(spreadsheet_xml)
        elsif content_blob.is_csv?
          content_blob.open_as_utf8 { |io| parse_spreadsheet_csv(io) }
        elsif content_blob.is_tsv?
          content_blob.open_as_utf8 { |io| parse_spreadsheet_csv(io, "\t") }
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
            ((col_index + 1)..min_cols).each do |i|
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
              cell = Cell.new(content, c['formula'], c['style'])
              row.cells[col_index] = cell
            end
          end
          # Pad rows
          if row_index < min_rows
            ((row_index + 1)..min_rows).each do |i|
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

      # Reads CSV (or TSV, with col_sep "\t") rows from an IO and returns a Workbook object.
      # Rows are read one at a time rather than parsing the whole file into an array first, so only the
      # Workbook itself is held in memory.
      def parse_spreadsheet_csv(io, col_sep = ',')
        workbook = Workbook.new
        sheet = Sheet.new('Sheet1')
        workbook.sheets << sheet

        # set a default style
        style = Style.new(DEFAULT_STYLE)
        style.attributes['font-size'] = '11pt'
        style.attributes['color'] = '#000000'
        workbook.styles[style.name] = style

        # quoting is disabled, so every line is one row
        csv = CSV.new(io, col_sep: col_sep, quote_char: "\x00")
        row_index = 0
        csv.each do |r|
          # the first row determines the column headings
          add_csv_columns(sheet, r.length) if row_index.zero?
          row_index += 1
          row = Row.new(row_index)
          sheet.rows[row_index] = row
          # csv won't have formulas or style
          r.each_with_index do |content, index|
            row.cells[index + 1] = Cell.new(content, nil, DEFAULT_STYLE)
          end
        end
        add_csv_columns(sheet, 0) if row_index.zero?

        # Pad rows
        if row_index < MIN_ROWS
          ((row_index + 1)..MIN_ROWS).each do |i|
            sheet.rows << Row.new(i, 1000.to_s)
          end
          sheet.last_row = MIN_ROWS
        else
          sheet.last_row = row_index
        end

        workbook
      end

      # Adds a column for each of the column_count columns in the first row, padded so the sheet is at
      # least MIN_COLS wide
      def add_csv_columns(sheet, column_count)
        (1..[column_count, MIN_COLS].max).each do |i|
          sheet.columns << Column.new(i, DEFAULT_COLUMN_WIDTH)
        end
        sheet.last_col = [column_count, MIN_COLS].max
      end

      # Turns a numeric column ID into an Excel letter representation
      # eg. 1 > A, 10 > J, 28 > AB etc.
      def to_alpha(col)
        result = ''
        col -= 1
        while col >= 0
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
        attr_accessor :sheets, :styles

        def initialize
          @sheets = []
          @styles = {}
        end

        def [](x)
          sheet(x)
        end

        def sheet(x)
          if x.instance_of?(String)
            @sheets.find { |s| s.name == x }
          elsif x.instance_of?(Integer)
            @sheets[x]
          end
        end

        def sheet_names
          @sheets.map(&:name)
        end
      end

      class Style
        attr_accessor :name, :attributes

        def initialize(name)
          @name = name
          @attributes = {}
        end

        def [](attribute)
          @attributes[attribute]
        end
      end

      class Sheet
        attr_accessor :rows, :columns, :name, :last_row, :last_col

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
        attr_accessor :index, :width

        def initialize(c = nil, w = nil)
          @index = c
          @width = w unless w.blank?
        end
      end

      class Row
        attr_accessor :cells, :index, :height

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

      # The cell's position is given by where it is stored (sheet.rows[row].cells[column]), so isn't
      # duplicated here - for a large sheet that saves two references in every one of millions of cells
      class Cell
        attr_accessor :value, :formula, :style

        def initialize(v = nil, f = nil, s = nil)
          @value = v
          @formula = f
          @style = s unless s.blank?
        end

        def pretty_value
          if @value.instance_of?(Float)
            @value.round(3)
          else
            @value
          end
        end
      end
    end
  end
end
