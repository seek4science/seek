module IsaTabConverter

  JERM_ONTOLOGY_URL = 'http://jermontology.org/ontology/JERMOntology'

  OBJECT_MAP = Hash.new

  def convert_investigation (investigation)
    if OBJECT_MAP.has_key? (investigation)
      return OBJECT_MAP[investigation]
    end

    isa_investigation = {}

    isa_investigation[:identifier] = investigation.id
    isa_investigation[:title] = investigation.title
    isa_investigation[:description] = investigation.description
    isa_investigation[:submission_date] = investigation.created_at.to_date.iso8601
    isa_investigation[:public_release_date] = investigation.created_at.to_date.iso8601

    # ontologySourceReferences pre-defined
    # Note can only map once as experiment type and technology type have the same URL
    isa_investigation[:ontologySourceReferences] = [
        {:file => JERM_ONTOLOGY_URL,
         :name => 'jerm_ontology'}]

    # map publications from publications
    # publications = []
    # investigation.publications.each { |p|
    #   publications << convert_publication(p)
    # }
    # isa_investigation[:publications] = publications

    # map people from people
    # people = []
    # investigation.people.each { |p|
    #   people << convert_persion (p)
    # }
    # isa_investigation[:people] = people

    # map studies from studies
    studies = []
    investigation.studies.each do |s|
      studies << convert_study(s)
    end
    isa_investigation[:studies] = studies

    OBJECT_MAP[investigation] = isa_investigation

    return isa_investigation
  end

  def convert_study (study)
    if OBJECT_MAP.has_key? (study)
      return OBJECT_MAP[study]
    end

    isa_study = {}

    isa_study[:identifier] = study.id
    isa_study[:title] = study.title
    isa_study[:description] = study.description
    isa_study[:submission_date] = study.created_at.to_date.iso8601
    isa_study[:public_release_date] = study.created_at.to_date.iso8601

    # map publications from publications
    # publications = []
    # study.publications.each { |p|
    #   publications << convert_publication(p)
    # }
    # isa_study[:publications] = publications

    # map people from people
    # people = []
    # study.people.each { |p|
    #   people << convert_persion (p)
    # }
    # isa_study[:people] = people

    # studyDesignDescriptors not yet mapped

    # materials not yet mapped

    # processSequence not yet mapped

    # map assays from assays
    # for seek_assay_ref in seek_study['assays']['data']:
    #   assay = translate_assay (seek_assay_ref)
    #   study.assays.append(assay)

    # map protocols from the sops referenced by the assays
    # must be done after mapping of assays
    #   for seek_assay_ref in seek_study['assays']['data']:
    #     u, seek_assay = read_seek_object (seek_assay_ref)
    #     for seek_sop_ref in seek_assay['sops']['data']:
    #       protocol = translate_sop (seek_sop_ref)
    #       study.protocols.append(protocol)

    # factors not yet mapped

    # characteristicCategories not yet mapped

    # unitCategories not yet mapped

    # comments are not mapped

    OBJECT_MAP[study] = isa_study

    return isa_study

  end

  def convert_annotation(term_uri)
    isa_annotation = {}
    term = term_uri.split('#')[1]
    isa_annotation[:annotationValue] = term
    isa_annotation[:termAccession] = term_uri
    isa_annotation[:termSource] = 'jerm_ontology'
    return isa_annotation
  end

end