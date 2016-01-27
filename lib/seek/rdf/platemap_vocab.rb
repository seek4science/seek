module Seek
  module Rdf
    class PlatemapVocab < RDF::Vocabulary("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#")

      property :associatedWith
      property :contains
      property :derivedFrom
      #     sample/
      #         centreOntology#contains
      #     peterSwain/sugar/
      #         centreOntology#derivedFrom
      #     peterSwain/strain/

    end
  end


  # @example Defining a simple vocabulary
  #   class EX < RDF::StrictVocabulay("http://example/ns#")
  #     term :Class,
  #       label: "My Class",
  #       comment: "Good to use as an example",
  #       "rdf:type" => "rdfs:Class",
  #       "rdfs:subClassOf" => "http://example/SuperClass"
  #   end


  # assert reader.has_triple?([RDF::URI.new("http://localhost:3000/data_files/#{df.id}"),
  #                            RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#associatedWith"),
  #                            RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/sample/DF#{df.id}_3"),])
  # assert reader.has_triple?([RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/sample/DF#{df.id}_3"),
  #                            RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#contains"),
  #                            RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/peterSwain/sugar/Raf"),])
  # assert reader.has_triple?([RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/sample/DF#{df.id}_3"),
  #                            RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/centreOntology#derivedFrom"),
  #                            RDF::URI.new("http://www.synthsys.ed.ac.uk/ontology/seek/peterSwain/strain/GAL1"),])
end
