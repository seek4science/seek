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
        row, first_col, last_col = find_treatment_row_and_columns_in_sheet sample_sheet
        unless row.nil?
          collect_values row, first_col, last_col, sample_sheet
          sample_col = hunt_for_sample_name_column sample_sheet
          if sample_col > 0
            collect_sample_names row, sample_col, sample_sheet
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

    def collect_sample_names first_row, col, sheet
      sheet_name = sheet.attributes["name"]
      @sample_names = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row >= '#{(first_row+1).to_s}' and @column = '#{col.to_s}']").collect do |cell|
        cell.content
      end
    end

    def collect_values row, first_col, last_col, sheet
      sheet_name = sheet.attributes["name"]
      col_keys = {}
      sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row >= '#{row.to_s}' and @column >= '#{first_col.to_s}' and @column <= '#{last_col.to_s}']").each do |cell|
        this_col_alpha = cell.attributes["column_alpha"]
        if cell.attributes["row"]==row.to_s

          @values[cell.content]=[]
          col_keys[this_col_alpha]=cell.content
        else
          @values[col_keys[this_col_alpha]] << cell.content
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
