module Seek
  module Rdf
    # HealthDCAT-AP vocabulary — Release 6
    # Spec:      https://healthdataeu.pages.code.europa.eu/healthdcat-ap/releases/release-6/
    # Namespace: http://healthdataportal.eu/ns/health#  (prefix: healthdcatap)
    # Examples:  https://code.europa.eu/healthdataeu/healthdcat-ap/-/tree/main/public/releases/release-6/html/examples
    #
    # Properties verified against official TTL example files from the repository.
    # Privacy properties (personal data, legal basis, purpose) are in the DPV vocabulary —
    # use dpv:hasPersonalData, dpv:hasLegalBasis, dpv:hasPurpose (https://w3id.org/dpv#).
    class HDCATVocab < RDF::Vocabulary('http://healthdataportal.eu/ns/health#')
      # --- Mandatory dataset properties ---
      # healthdcataphealthCategory.ttl  → IRI (skos:Concept from health categories authority table)
      property :healthCategory
      # healthdcataphdab.ttl            → foaf:Agent blank node with cv:contactPoint
      property :hdab

      # --- Recommended/optional dataset properties ---
      # healthdcataphealththeme.ttl     → IRI (skos:Concept from health theme authority table)
      property :healthTheme
      # healthdcatappopulationCoverage.ttl → lang-tagged literal
      property :populationCoverage
      # healthdcatapretentionperiod.ttl → dct:PeriodOfTime blank node (dcat:startDate / dcat:endDate)
      property :retentionPeriod
      # healthdcatapminTypicalAge.ttl   → xsd:integer
      property :minTypicalAge
      # healthdcatapmaxTypicalAge.ttl   → xsd:integer
      property :maxTypicalAge
      # healthdcatapnumberOfRecords.ttl → xsd:nonNegativeInteger
      property :numberOfRecords
      # healthdcatapnumberOfUniqueIndividuals.ttl → xsd:nonNegativeInteger
      property :numberOfUniqueIndividuals
      # healthdcataphasCodingSystem.ttl → IRI of dct:Standard (e.g. Wikidata ICD-10/SNOMED entry)
      property :hasCodingSystem
      # healthdcataphasCodeValues.ttl   → lang-tagged literal (e.g. ICD code "U07.1"@en)
      property :hasCodeValues
      # healthdcatapanalytics.ttl       → dcat:Distribution blank node (technical report/CSV)
      property :analytics
      # healthdcatappublishernote.ttl   → lang-tagged literal describing the publisher
      property :publisherNote
      # healthdcatappublishertype.ttl   → IRI from publisher-type authority table
      property :publisherType
      # healthdcataptrusteddataholder.ttl → xsd:boolean
      property :trusteddataholder
    end
  end
end
