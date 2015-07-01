class PlatemapReader
  require 'set'
  require 'csv'
  include SysMODB::SpreadsheetExtractor

  def read_in df

    # Would be nice to trim the empty rows here, but that doesn't work with xlsx files.
    csv_data = spreadsheet_to_csv(open(df.content_blob.filepath))

    # initialise set of strain names
    strain_names = Set.new
    # initialise set of sugar names
    sugar_names = Set.new

    CSV.parse(csv_data) do |row|
      # if the first cell in the row contains a single letter
      rowname = row[0]
      rowname.strip! unless rowname.nil?
      if (!rowname.nil? && !rowname[/[a-zA-Z]/].nil? && rowname.size == 1)
        # parse each cell in that row
        row.each do |cell|
          cell.strip! unless cell.nil?
          # Example: do want to match 'WT in 2% Raf', don't want to match 'contaminated'
          # If the string matches '...in...%...'
          if (!cell.nil? && !cell[/.+in.+%.+/].nil?)
            # Strain = first word
            strain = cell[/^\w+/]
            strain_names.add(strain) unless strain == 'null'
            # Sugar = last word
            sugar = cell[/\w+$/]
            sugar_names.add(sugar)
          end
        end
      end
    end
    {:sugar_names => sugar_names, :strain_names => strain_names}
  end
end