module Seek
  module Rdf
    # W3C Data Privacy Vocabulary (DPV) — https://w3id.org/dpv
    # Not available in rdf-vocab gem; defined manually.
    # Used for personal data categories, legal basis, and processing purpose.
    class Dpv < RDF::Vocabulary('https://w3id.org/dpv#')
      property :hasPersonalData
      property :hasLegalBasis
      property :hasPurpose
      property :LegalBasis
      property :Purpose
      property :PersonalData
    end
  end
end
