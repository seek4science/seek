module Seek
  module Rdf
    # SEEK extension namespace for HealthDCAT-AP terms that have no standard mapping.
    # Only add properties here when no existing vocabulary (DCAT, DCTERMS, HDCAT, PROV, SKOS) covers the concept.
    # URI: https://seek4science.org/vocab/seekh#
    class SeekHealth < RDF::Vocabulary('https://seek4science.org/vocab/seekh#')
    end
  end
end
