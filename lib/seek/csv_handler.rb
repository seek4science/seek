module Seek
  class CSVHandler

    def self.resolve_model_parameter_keys parameter_keys, csv

      matching_columns = {}
      matched_keys = []
      matching_csv = []

      FasterCSV.parse(csv).each do |row|
        matched_row = []
        row.each_with_index do |v, i|
          if matching_columns[i]
            matched_row << v
          end
          k = matching_key? parameter_keys, v
          if k
            matched_row << k
            matching_columns[i]=k
            matched_keys << k
          end
        end
        matching_csv << matched_row unless matched_row.empty?
      end

      result = FasterCSV.generate do |out|
        matching_csv.each do |row|
          out << row
        end
      end

      return result, matched_keys

    end

    def self.matching_key? parameter_keys, v
      v if parameter_keys.include?(v)
    end

  end

end