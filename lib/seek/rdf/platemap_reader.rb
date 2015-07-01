class PlatemapReader
  require 'set'
  require 'csv'
  include SysMODB::SpreadsheetExtractor

  def read_in df

    # Would be nice to trim the empty rows here, but that doesn't work with xlsx files.
    csv_data = spreadsheet_to_csv(open(df.content_blob.filepath))

    # Expected [[nil, 'Raf'],[nil, 'Gal'],['WT', 'Raf']...]
    samples = Set.new

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
            sample = [nil, nil]
            # Strain = first word
            strain = cell[/^\w+/]
            sample[0] = strain unless strain == 'null'
            # Sugar = last word
            sugar = cell[/\w+$/]
            sample[1] = sugar
            samples.add(sample)
          end
        end
      end
    end
    samples
  end
end