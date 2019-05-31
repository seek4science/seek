# noinspection ALL
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
    isa_investigation[:submissionDate] = investigation.created_at.to_date.iso8601
    isa_investigation[:publicReleaseDate] = investigation.created_at.to_date.iso8601

    # ontologySourceReferences pre-defined
    # Note can only map once as experiment type and technology type have the same URL
    # Need to check version of JERM
    isa_investigation[:ontologySourceReferences] = [
        {:file => JERM_ONTOLOGY_URL,
         :name => 'jerm_ontology',
        :version => '1.0',
        :description => ''}]

    # map publications from publications
    publications = []
    investigation.publications.each do |p|
      publications << convert_publication(p)
    end
    isa_investigation[:publications] = publications

    # map people from people
    people = []
    investigation.related_people.each do |p|
      people << convert_person(p)
    end
    isa_investigation[:people] = people

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
    isa_study[:submissionDate] = study.created_at.to_date.iso8601
    isa_study[:publicReleaseDate] = study.created_at.to_date.iso8601
    isa_study[:filename] = nil

    # map publications from publications
    publications = []
    study.publications.each do |p|
      publications << convert_publication(p)
    end
    isa_study[:publications] = publications

    # map people from people
    people = []
    study.related_people.each do |p|
      people << convert_person(p)
    end
    isa_study[:people] = people

    # studyDesignDescriptors not yet mapped
    isa_study[:studyDesignDescriptors] = []

    # materials not yet mapped
    isa_study[:materials] = {:sources => [], :samples => [], :otherMaterials => []}

    # processSequence not yet mapped
    isa_study[:processSequence] = []

    # map assays from assays
    assays = []
    study.assays.each do |a|
      assays << convert_assay(a)
    end
    isa_study[:assays] = assays

    protocols = []
    # map protocols from the sops referenced by the assays
    # must be done after mapping of assays
    study.assays.each do |a|
      a.sops.each do |s|
        protocols << convert_sop(s)
      end
    end
    isa_study[:protocols] = protocols

    # factors not yet mapped
    isa_study[:factors] = []

    # characteristicCategories not yet mapped
    isa_study[:characteristicCategories] = []

    # unitCategories not yet mapped
    isa_study[:unitCategories] = []

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

  def convert_assay (assay)
    if OBJECT_MAP.has_key? (assay)
      return OBJECT_MAP[assay]
    end

    isa_assay = {}
    # @id not yet mapped

    isa_assay[:description] = assay.description

    # comments are not mapped

    # filename not yet mapped
    isa_assay[:filename] = nil

    # mao measurementType from assay_type
    if assay.assay_type_uri
        isa_assay[:measurementType]= convert_annotation(assay.assay_type_uri)
    end

    # map technologyType from technology_type
    if assay.technology_type_uri
        isa_assay[:technologyType] = convert_annotation(assay.technology_type_uri)
    end

    # technologyPlatform not yet mapped
    isa_assay[:technologyPlatform] = nil

    # map dataFiles from data_files
    dataFiles = []
    assay.data_files.each do |d|
      dataFiles << convert_data_file(d)
    end
    isa_assay[:dataFiles] = dataFiles


    # materials not yet mapped
    isa_assay[:materials] = {:sources => [], :samples => [], :otherMaterials => []}

    # characteristicCategories not yet mapped
    isa_assay[:characteristicCategories] = []

    # unitCategories not yet mapped
    isa_assay[:unitCategories] = []

    # processSequence not yet mapped
    isa_assay[:processSequence] = []

    OBJECT_MAP[assay] = isa_assay

    return isa_assay
  end

  def convert_person(person)
    if OBJECT_MAP.has_key? (person)
      return OBJECT_MAP[person]
    end

    isa_person = {}

    # @id not yet mapped

    isa_person[:lastName] = person.last_name
    isa_person[:firstName] = person.first_name
    isa_person[:midInitials] = ''
    # eMail is not mapped
    isa_person[:email] = ''
    isa_person[:phone] = person.phone
    # fax is not mapped
    isa_person[:fax] = nil
    isa_person[:address] = nil

    # affiliation is not yet mapped
    isa_person[:affiliation] = nil

    # roles are not yet mapped
    isa_person[:roles] = []
    # comments are not mapped


    OBJECT_MAP[person] = isa_person

    return isa_person

  end

  def convert_publication(publication)

    if OBJECT_MAP.has_key? (publication)
      return OBJECT_MAP[publication]
    end

    isa_publication = {}

    # comments are not mapped

    isa_publication[:pubMedID] = publication.pubmed_id
    isa_publication[:doi] = publication.doi
    isa_publication[:author_list] = publication.authors.map { |a| a.full_name }.join(', ')

    isa_publication[:title] = publication.title
    # status not yet mapped

    OBJECT_MAP[publication] = isa_publication

    return publication
  end

  def convert_sop(sop)
    if OBJECT_MAP.has_key? (sop)
      return OBJECT_MAP[sop]
    end

    isa_protocol = {}

    isa_protocol['@id'] = URI.join(Seek::Config.site_base_host + '/sops/', sop.id.to_s).to_s

    # comments are not mapped

    isa_protocol[:name] = sop.title

    # protocol_type not yet mapped
    isa_protocol[:protocolType] = {:annotationValue => nil}

    isa_protocol[:description] = sop.description

    # uri cannot be mapped
    isa_protocol[:uri] = nil

    isa_protocol[:version] = sop.version.to_s

    # parameters cannot be mapped
    isa_protocol[:parameters] = []

    # components not yet mapped
    isa_protocol[:components] = []

    OBJECT_MAP[sop] = isa_protocol

    return isa_protocol
  end

  def convert_data_file(data_file)
    if OBJECT_MAP.has_key? (data_file)
      return OBJECT_MAP[data_file]
    end

    isa_data_file = {}

    if data_file.content_blob.url
      isa_data_file['@id'] = data_file.content_blob.url
    else
      isa_data_file['@id'] = URI.join(Seek::Config.site_base_host + '/data_files/', data_file.id.to_s).to_s
    end

    # comments are not mapped

    isa_data_file[:name] = data_file.title

    # data_file_type fixed at raw data file
    isa_data_file[:type] = 'Raw Data File'

    OBJECT_MAP[data_file] = isa_data_file

    return isa_data_file
  end

end