class Seek::Rdf::PlatemapReader
  require 'set'
  require 'csv'
  include SysMODB::SpreadsheetExtractor

  def file_to_rdf df, rdf_graph

    # Would be nice to trim the empty rows here, but that doesn't work with xlsx files.
    csv_data = spreadsheet_to_csv(open(df.content_blob.filepath))
    if (is_platemap_file? csv_data)
      samples = read_in(csv_data) #[[nil, 'Raf'],[nil, 'Gal'],['WT', 'Raf']...]
      rdf_graph = samples_to_rdf df, samples, rdf_graph
    end
    rdf_graph
  end

  def is_platemap_file? csv_data
    is_platemap = false

    # Check first column has ABCDEFGH
    spreadsheet = CSV.parse(csv_data)
    is_platemap = ((spreadsheet[1][0] == 'A') &&
        (spreadsheet[2][0] == 'B') &&
        (spreadsheet[3][0] == 'C') &&
        (spreadsheet[4][0] == 'D') &&
        (spreadsheet[5][0] == 'E') &&
        (spreadsheet[6][0] == 'F') &&
        (spreadsheet[7][0] == 'G') &&
        (spreadsheet[8][0] == 'H'))
    is_platemap
  end

  def read_in csv_data

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
            sample[0] = strain.upcase unless strain == 'null'
            # Sugar = last word
            sugar = cell[/\w+$/]
            sample[1] = sugar.capitalize
            samples.add(sample)
          end
        end
      end
    end
    samples
  end

  def samples_to_rdf df, samples, rdf_graph
    sample_no = 1
    samples.each do |sample|
      strain = sample.first
      sugar = sample.second
      add_sample_to_rdf_graph(strain, sugar, sample_no, df, rdf_graph)
      sample_no = sample_no + 1
    end
    rdf_graph
  end

  def add_sample_to_rdf_graph strain, sugar, sample_no, data_file, rdf_graph
    # TODO remove hardcoded uris
    sample_uri = RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/sample/DF#{data_file.id}_#{sample_no}")
    strain_uri = RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/peterSwain/strain/#{strain}")
    sugar_uri = RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/peterSwain/sugar/#{sugar}")
    associated_with = RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#associatedWith")
    contains = RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#contains")
    derived_from = RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#derivedFrom")
    data_file_uri = data_file.rdf_resource

    unless strain.nil? && sugar.nil?
      # Data file associated with sample
      rdf_graph << [data_file_uri, associated_with, sample_uri]

      # Sample contains sugar
      unless sugar.nil?
        rdf_graph << [sample_uri, contains, sugar_uri]
      end

      # Sample derived from strain
      unless strain.nil?
        rdf_graph << [sample_uri, derived_from, strain_uri]
      end
    end
  end

end