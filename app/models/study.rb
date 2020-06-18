class Study < ApplicationRecord

  include Seek::Rdf::RdfGeneration
  include Seek::ProjectHierarchies::ItemsProjectsExtension if Seek::Config.project_hierarchy_enabled

  searchable(:auto_index => false) do
    text :experimentalists
    text :person_responsible do
      person_responsible.try(:name)
    end
  end if Seek::Config.solr_enabled

  belongs_to :investigation
  has_many :projects, through: :investigation
  has_filter :project

  #FIXME: needs to be declared before acts_as_isa, else ProjectAssociation module gets pulled in
  acts_as_isa
  acts_as_snapshottable

  has_many :assays
  has_many :assay_publications, through: :assays, source: :publications
  has_one :external_asset, as: :seek_entity, dependent: :destroy

  has_one :custom_metadata, as: :item
  accepts_nested_attributes_for :custom_metadata

  belongs_to :person_responsible, :class_name => "Person"

  validates :investigation, presence: { message: "Investigation is blank or invalid" }, projects: true

  enforce_authorization_on_association :investigation, :view

  %w[data_file sop model document].each do |type|
    has_many "#{type}_versions".to_sym, -> { distinct }, through: :assays
    has_many "related_#{type.pluralize}".to_sym, -> { distinct }, through: :assays, source: type.pluralize.to_sym
  end


  def self.extract_study_data_from_file(studies_file)
    parsed_sheet = Seek::Templates::StudiesReader.new(studies_file)

    studies_data_files = {}
    columns = [2, 3, 4, 5]
    data_file_start_row_index = 4
    parsed_sheet.each_record(5, columns) do |index, data|
      if index > data_file_start_row_index

        study_id = data[0].value
        if !studies_data_files.key?(study_id)
          studies_data_files[study_id] = {data_file:[], data_file_description:[], data_file_version:[]}
        end


        data_file = data[1].value
        data_file_description = data[2].value
        data_file_version = data[3].value
        studies_data_files[study_id][:data_file] << data_file
        studies_data_files[study_id][:data_file_description] << data_file_description
        studies_data_files[study_id][:data_file_version] << data_file_version
      end
    end
    studies_data_files
  end

  def self.extract_studies_from_file(studies_file)
    studies = []
    parsed_sheet = Seek::Templates::StudiesReader.new(studies_file)
    metadata_type = CustomMetadataType.new(title: 'MIAPPE metadata', supported_type:'Study')

    columns = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
    study_start_row_index = 4
    parsed_sheet.each_record(3, columns) do |index, data|
      if index > study_start_row_index
        study_id = data[0].value
        studies << Study.new(
          title: data[1].value,
          description: data[2].value,
          custom_metadata: CustomMetadata.new(
              custom_metadata_type: metadata_type,
              data: generate_metadata(data)
          )
        )
        study_exist(study_id)
      end
    end
    studies
  end

  def self.generate_metadata(data)
    metadata = {
        id: data[0].value,
        study_start_date: data[3].value,
        study_end_date: data[4].value,
        contact_institution: data[5].value,
        geographic_location_country: data[6].value,
        experimental_site_name: data[7].value,
        latitude: data[8].value,
        longitude: data[9].value,
        altitude: data[10].value,
        description_of_the_experimental_design: data[11].value,
        type_of_experimental_design: data[12].value,
        observation_unit_level_hierarchy: data[13].value,
        observation_unit_description: data[14].value,
        description_of_growth_facility: data[15].value,
        type_of_growth_facility: data[16].value,
        cultural_practices: data[17].value,
    }
    metadata
  end


  def self.unzip_batch(file_path)
    unzipped_files = Zip::File.open(file_path)
    user_uuid = "#{User.current_user.attributes["uuid"]}"
    Dir.mkdir("#{Rails.root}/tmp/#{user_uuid}_studies_upload") unless File.exists?("#{Rails.root}/tmp/#{user_uuid}_studies_upload")
    tmp_dir = "#{Rails.root}/tmp/#{user_uuid}_studies_upload/"
    study_data = []
    studies = []
    unzipped_files.entries.each do |file|
      if file.name.starts_with?('data') && file.ftype != :directory
        study_data << file
        Dir.mkdir "#{tmp_dir}/data" unless File.exists? "#{tmp_dir}/data"
        file.extract("#{tmp_dir}#{file.name}") unless File.exists? "#{tmp_dir}#{file.name}"
      elsif file.ftype == :file
        studies << file
        file.extract("#{tmp_dir}#{file.name}") unless File.exists? "#{tmp_dir}#{file.name}"
      end
    end
    [study_data, studies]
  end

  def self.study_exist(study_metadata_id)
    existing_studies = []
    find_metadata = CustomMetadata.where("json_metadata LIKE ?", "%#{study_metadata_id}%").last
    if !find_metadata.nil?
      study_id = find_metadata.item_id
      study = Study.where(id: study_id)
      existing_studies << study
    end
  end

  def self.check_study_is_valid(study, metadata)
    mandatory_fields = %w[id title study_start_date contact_institution geographic_location_country experimental_site_name
                        description_of_the_experimental_design observation_unit_description description_of_growth_facility]
    missing_fields = []

    mandatory_fields.each { |mandatory_f|

      if study.attributes[mandatory_f].blank? && metadata[mandatory_f.to_sym].blank?
        missing_fields << mandatory_f
      end
    }

  end

  def assets
    related_data_files + related_sops + related_models + related_publications + related_documents
  end

  def state_allows_delete? *args
    assays.empty? && super
  end

  def clone_with_associations
    new_object = dup
    new_object.policy = policy.deep_copy
    new_object.publications = publications
    new_object
  end

  def external_asset_search_terms
    external_asset ? external_asset.search_terms : []
  end

  def self.filter_by_projects(projects)
    joins(:projects).where(investigations: { investigations_projects: { project_id: projects } })
  end

  def related_publication_ids
    publication_ids | assay_publication_ids
  end

  def related_person_ids
    ids = super
    ids << person_responsible_id if person_responsible_id
    ids.uniq
  end

  def self.user_creatable?
    Seek::Config.studies_enabled
  end
end
