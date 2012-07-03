require 'libxml'

module Seek

  class Treatments

    attr_reader :sample_names, :values

    def initialize xml=nil
      @sample_names = []
      @values = {}
      unless xml.nil?
        begin
          doc = LibXML::XML::Parser.string(xml).parse
        rescue Exception=>e
          doc=nil
          Rails.logger.warn "Invalid xml encountered. - #{e.message}"
        end

        unless doc.nil?
          extract_from_document doc
        end
      end
    end

    private

    def extract_from_document doc
      doc.root.namespaces.default_prefix="ss"
      sample_sheet = find_samples_sheet doc
      unless sample_sheet.nil?
        treatments_heading_row, treatments_first_col, treatments_last_col = find_treatment_row_and_columns_in_sheet sample_sheet
        unless treatments_heading_row.nil?
          sample_col = hunt_for_sample_name_column sample_sheet
          table = extract_as_table treatments_heading_row, sample_col, treatments_first_col,treatments_last_col,sample_sheet
          extract_sample_names_and_values table
        end
      end
    end

    def find_treatment_row_and_columns_in_sheet sheet
      sheet_name = sheet.attributes["name"]
      treatment_cell_element = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell").find do |cell|
        cell.content.match(/treatment.*/i)
      end
      unless treatment_cell_element.nil?
        #find the next column for this row that contains content
        row = treatment_cell_element.attributes["row"].to_i
        col = treatment_cell_element.attributes["column"].to_i
        next_cell_element = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row='#{row}' and @column > '#{col}']").find do |cell|
          !cell.content.blank?
        end


        if next_cell_element.nil?
          next_cell_element = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row='#{row.to_i+1}' and @column > '#{col}']").find do |cell|
            !cell.content.blank?
          end
          end_column = next_cell_element.attributes["column"].to_i unless next_cell_element.nil?
        else
          end_column = next_cell_element.attributes["column"].to_i-1
        end


        return row+1, col, end_column.to_i

      end
    end

    def hunt_for_sample_name_column sheet
      sheet_name = sheet.attributes["name"]
      sample_cell_element = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell").find do |cell|
        cell.content.match(/sample.*name/i) || cell.content.match(/sample.*title/i)
      end
      sample_cell_element.nil? ? 0 : sample_cell_element.attributes["column"].to_i
    end

    def find_samples_sheet doc
      sheet = doc.find_first("//ss:sheet[@name='Organism_Sample']")
      sheet = doc.find_first("//ss:sheet[@name='Organism_sample']") if sheet.nil?
      sheet = doc.find_first("//ss:sheet[@name='organism_sample']") if sheet.nil?
      sheet = doc.find_first("//ss:sheet[@name='organism_Sample']") if sheet.nil?
      sheet = hunt_for_sheet(doc) if sheet.nil?
      sheet
    end

    def hunt_for_sheet doc
      doc.find("//ss:sheet").find do |sheet|
        sheet_name=sheet.attributes["name"]
        possible_cells = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row='1']")
        match = possible_cells.find do |cell|
          cell.content.match(/treatment.*/i)
        end
        !match.nil?
      end
    end

    # reads out the relevant data into a well formed table, with equal length rows and nils replaces with empty strings.
    # stops after a row with no sample name or treatment information
    def extract_as_table treatments_heading_row, sample_col, treatments_first_col,treatments_last_col,sheet
      table = []
      sheet_name = sheet.attributes["name"]
      cells = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row >= '#{(treatments_heading_row).to_s}' and (@column = '#{sample_col.to_s}' or (@column>='#{treatments_first_col.to_s}' and @column<='#{treatments_last_col.to_s}'))]")

      cells.each do |cell|
        row = cell.attributes['row'].to_i
        col = cell.attributes['column'].to_i

        #normalise row and column, to leave a table only containing the required content
        row = row - treatments_heading_row
        if col == sample_col
          col = 0
        else
          col = col - treatments_first_col + 1
        end

        table[row]||=[]
        table[row][col]=cell.content

      end


      #tidy up the table, removing rows once a completely empty row is encountered, and padding rows up to the maximum width, and replacing
      #nils with empty strings
      lasti=table.size
      maxwidth=0
      table.each_with_index do |row,i|
        maxwidth = row.size unless row.nil? || row.size<maxwidth
        if row.nil? || row.empty? || row.select{|v| !v.blank?}.empty?
          lasti=i
          break
        end
      end
      table = table[0...lasti]
      table.each do |row|
        if row.size<maxwidth
          row.fill("",row.size,maxwidth-row.size)
        end
        row.map!{|v| v.nil? ? "" : v}
      end

      table
    end

    def extract_sample_names_and_values table
      heading_row = table[0]
      table = table[1..-1]
      heading_row[1..-1].each do |heading|
        @values[heading]=[]
      end
      table.each do |row|
        row.each_with_index do |v,i|
          if i==0
            @sample_names << v
          else
            @values[heading_row[i]] << v
          end
        end
      end

    end
  end
end
