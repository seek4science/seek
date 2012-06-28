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
          collect_treatment_values_and_title treatments_heading_row, treatments_first_col, treatments_last_col, sample_sheet
          if sample_col > 0
            collect_sample_names treatments_heading_row, sample_col, treatments_first_col, treatments_last_col,sample_sheet
          else
            @sample_names = [].fill("", 0, values.first ? values.first[1].length : 0)
          end
          strip_trailing_blank_items
        end
      end
    end

    def strip_trailing_blank_items
      max_len=-1

      keys = values.keys
      keys.each do |key|
        values[key].each_with_index do |val, i|
          if (i>max_len)
            unless val.blank?
              max_len=i
            end
          end
        end
      end

      if max_len>0
        keys.each do |key|
          values[key]=values[key][0..max_len]
        end
        @sample_names = @sample_names[0..max_len]
      end
    end

    def collect_sample_names first_row, col, treatments_first_col, treatments_last_col,sheet

      sheet_name = sheet.attributes["name"]
      next_row = first_row + 1
      @sample_names = []
      sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row >= '#{(next_row).to_s}' and @column = '#{col.to_s}']").each do |cell|
        row = cell.attributes["row"].to_i
        if row > next_row
          #fill missing rows
          (next_row...row).to_a.each do |missing_row|
            if treatments_exist_for_row? missing_row,treatments_first_col,treatments_last_col,sheet
              @sample_names << ""
            end
          end
        else
          treatments_exist = treatments_exist_for_row? row,treatments_first_col,treatments_last_col,sheet
          #only include samples where at least one of the treatments cells contain content
          if treatments_exist
            @sample_names << cell.content
          end
        end

        next_row = row + 1
      end

    end

    def treatments_exist_for_row? row,treatments_first_col,treatments_last_col, sheet
      treatment_content_count = 0
      sheet_name = sheet.attributes["name"]
      #count them to take into account blank cells that may be missing from the XML
      sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row = '#{row}' and @column >= '#{treatments_first_col.to_s}' and @column <= '#{treatments_last_col.to_s}']").each do |treatment_cell|
        treatment_content_count+=1 if (!treatment_cell.content.blank?)
      end
      treatment_content_count > 0
    end

    def collect_treatment_values_and_title treatments_heading_row, first_col, last_col, sheet
      #FIXME: this needs simplifying - maybe by copying all into a matrix first and dealing with that
      sheet_name = sheet.attributes["name"]
      col_keys = {}

      rows = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row[@index>= '#{treatments_heading_row.to_s}']")
      rows.each do |row|
        values = {}
        row.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row = '#{row.attributes["index"]}' and @column >= '#{first_col.to_s}' and @column <= '#{last_col.to_s}']").each do |cell|
          this_col_alpha = cell.attributes["column_alpha"]
          values[this_col_alpha]=cell.content
        end
        if row.attributes["index"]==treatments_heading_row.to_s
          values.keys.each do |col_alpha|
            content = values[col_alpha]
            @values[content]=[]
            col_keys[col_alpha]=content
          end

        else
          if (!values.values.select { |v| !v.blank? }.empty?)
            values.keys.each do |col_alpha|
              key = col_keys[col_alpha]
              @values[key] << values[col_alpha]
            end
          else
            break #stop once encountering a row with no treatments defined. Subsequent rows will not be included (solves an issue where there is more information below the sample table)
          end
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
  end
end
