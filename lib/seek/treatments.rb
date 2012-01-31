require 'libxml'

module Seek

  class Treatments

    attr_reader :sample_names,:values

    def initialize xml
      doc = LibXML::XML::Parser.string(xml).parse
      doc.root.namespaces.default_prefix="ss"
      @sample_names = []
      @values = {}

      sample_sheet = find_samples_sheet doc
      unless sample_sheet.nil?
        row,first_col,last_col = find_treatment_row_and_columns_in_sheet sample_sheet
        unless row.nil?
          collect_values row,first_col,last_col,sample_sheet
          collect_sample_names row,1,sample_sheet
        end
      end
    end

    private

    def collect_sample_names first_row,col,sheet
      sheet_name = sheet.attributes["name"]
      @sample_names = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row >= '#{(first_row+1).to_s}' and @column = '#{col.to_s}']").collect do |cell|
        cell.content
      end
    end

    def collect_values row,first_col,last_col,sheet
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
        row = treatment_cell_element.attributes["row"]
        col = treatment_cell_element.attributes["column"]
        next_cell_element = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row='#{row}' and @column > '#{col}']").find do |cell|
          !cell.content.blank?
        end

        end_column=next_cell_element.attributes["column"] unless next_cell_element.nil?

        return row.to_i+1,col.to_i,end_column.to_i-1

      end
    end

    def find_samples_sheet doc
      sheet = doc.find_first("//ss:sheet[@name='Organism_Sample']")
      sheet = doc.find_first("//ss:sheet[@name='Organism_sample']") if sheet.nil?
      sheet = doc.find_first("//ss:sheet[@name='organism_sample']") if sheet.nil?
      sheet = doc.find_first("//ss:sheet[@name='organism_Sample']") if sheet.nil?
      sheet
    end

  end

end
