require_dependency 'seek/util'

class DataFile < ApplicationRecord
  include Seek::Rdf::RdfGeneration
  include Seek::BioSchema::Support
  include Seek::DataFiles::Unzip

  acts_as_asset

  acts_as_doi_parent

  has_controlled_vocab_annotations :data_types, :data_formats

  validates :projects, presence: true, projects: { self: true }

  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a Data file with such title."

  has_one :content_blob, ->(r) { where('content_blobs.asset_version =? AND deleted =?', r.version, false) }, as: :asset, foreign_key: :asset_id
  has_one :external_asset, as: :seek_entity, dependent: :destroy

  belongs_to :file_template
  has_many :extracted_samples, class_name: 'Sample', foreign_key: :originating_data_file_id
  has_many :sample_resource_links, -> { where(resource_type: 'DataFile') }, foreign_key: :resource_id
  has_many :linked_samples, through: :sample_resource_links, source: :sample
  
  has_many :unzipped_files, class_name: 'DataFile', foreign_key: :zip_origin_id
  belongs_to :zip_origin, class_name: 'DataFile', optional: true

  has_many :observation_unit_assets, dependent: :delete_all, as: :asset, foreign_key: :asset_id, autosave: true, inverse_of: :asset
  has_many :observation_units, through: :observation_unit_assets

  has_many :workflow_data_files, dependent: :destroy, autosave: true
  has_many :workflows, ->{ distinct }, through: :workflow_data_files

  has_one :placeholder
  scope :with_extracted_samples, -> { joins(:extracted_samples).distinct }

  scope :simulation_data, -> { where(simulation_data: true) }

  has_filter assay_type: Seek::Filtering::Filter.new(
      value_field: 'assays.assay_type_uri',
      label_mapping: Seek::Filterer::MAPPINGS[:assay_type_label],
      joins: [:assays]
  )
  has_filter technology_type: Seek::Filtering::Filter.new(
      value_field: 'assays.technology_type_uri',
      label_mapping: Seek::Filterer::MAPPINGS[:technology_type_label],
      joins: [:assays]
  )

  explicit_versioning(version_column: 'version', sync_ignore_columns: ['doi', 'file_template_id']) do

    acts_as_doi_mintable(proxy: :parent, type: 'Dataset', general_type: 'Dataset')
    acts_as_versioned_resource
    acts_as_favouritable

    has_one :content_blob, ->(r) { where('content_blobs.asset_version =? AND content_blobs.asset_type =?', r.version, r.parent.class.name) },
            primary_key: :data_file_id, foreign_key: :asset_id

    def relationship_type(assay)
      parent.relationship_type(assay)
    end

    def external_asset
      parent.external_asset if parent.respond_to?(:external_asset)
    end
  end

  if Seek::Config.events_enabled
    has_and_belongs_to_many :events
  else
    def events
      []
    end

    def event_ids
      []
    end

    def event_ids=(_events_ids); end
  end

  def workflow_data_files_attributes=(attributes)
    self.workflow_data_files.each do |link|
      if link.workflow_data_file_relationship
        link.mark_for_destruction unless attributes.include?({"workflow_id"=>link.workflow.id.to_s,"workflow_data_file_relationship_id"=>link.workflow_data_file_relationship.id.to_s })
      else
        link.mark_for_destruction unless attributes.include?({"workflow_id"=>link.workflow.id.to_s})
      end
    end
    attributes.each do |attr|
      if self.workflow_data_files.where(attr).empty?
        self.workflow_data_files.build(attr)
      end
    end
  end

  def included_to_be_copied?(symbol)
    case symbol.to_s
    when 'activity_logs', 'versions', 'attributions', 'relationships', 'inverse_relationships', 'annotations'
      return false
    else
      true
    end
  end

  def relationship_type(assay)
    # FIXME: don't like this hardwiring to assay within data file, needs abstracting
    assay_assets.find_by_assay_id(assay.id).try(:relationship_type)
  end

  def use_mime_type_for_avatar?
    true
  end

  def supports_spreadsheet_explore?
    true
  end
  
  def zipped_folder?
    return false if external_asset.is_a? OpenbisExternalAsset
    content_blob&.is_unzippable_datafile?
  end

  def matching_sample_type?
    return false if external_asset.is_a? OpenbisExternalAsset

    possible_sample_types.any?
  end

  # returns all matching sample types
  def possible_sample_types(user = User.current_user)
    SampleType.sample_types_matching_content_blob(content_blob,user)
  end


  def related_samples
    extracted_samples + linked_samples
  end

  
  def related_data_files
    zip_origin.nil? ? unzipped_files : [zip_origin] + unzipped_files
  end

  # Extracts samples using the given sample_type
  # Returns a list of extracted samples, including
  def extract_samples(sample_type, confirm = false, overwrite = false)
    samples = sample_type.build_samples_from_template(content_blob)
    extracted = []

    # If the overwrite flag is set, find existing samples by their title and update their sample data.
    if overwrite
      samples = samples.map do |new_sample|
        existing = extracted_samples.find_by_title(new_sample.title_from_data)

        if existing
          existing.data.clear
          existing.data.mass_assign(new_sample.data, pre_process: false)
          existing
        else
          new_sample
        end
      end
    end

    samples.each do |sample|
      sample.project_ids = project_ids
      sample.contributor = contributor
      sample.originating_data_file = self
      sample.policy = policy.deep_copy
      sample.save if sample.valid? && confirm

      extracted << sample
    end

    extracted
  end

  def external_asset_search_terms
    external_asset ? external_asset.search_terms : []
  end

  # indicates that this is an openBIS based DataFile
  def openbis?
    external_asset.is_a? OpenbisExternalAsset
  end

  def openbis_dataset
    openbis? ? external_asset.content : nil
  end

  def openbis_size_download_restricted?
    openbis? && openbis_dataset.size > Seek::Config.openbis_download_limit
  end

  def download_disabled?
    super || openbis_size_download_restricted?
  end

  def nels?
    content_blob && content_blob.nels?
  end

  def openbis_dataset_json_details
    openbis? ? openbis_dataset.json : nil
  end

  # overides that from Seek::RDF::RdfGeneration, as simulation data needs to be #Simulation_data
  def rdf_type_entity_fragment
    if simulation_data
      'Simulation_data'
    else
      super
    end
  end

  # Copy the AssayAsset associations to each of the given resources (usually Samples).
  # If an array of `assays` is specified (must be assay instances or IDs), only copy associations to these assays.
  def copy_assay_associations(resources, assays = nil)
    aa = assay_assets
    if assays
      assay_ids = assays.map { |a| a.is_a?(Assay) ? a.id : a }
      assays = Assay.where(id: assay_ids).authorized_for(:edit)
      aa = assay_assets.where(assay: assays)
    end

    AssayAsset.transaction do
      resources.in_groups_of(500).each do |group|
        inserts = group.compact.map do |resource|
          aa.map do |aa|
            {assay_id: aa.assay.id, direction: aa.direction, asset_id: resource.id, asset_type: resource.class.name}
          end
        end.flatten
        AssayAsset.insert_all(inserts)
      end
    end

    queue_rdf_generation(true, true)
  end

  def populate_metadata_from_template
    if contains_extractable_excel?
      Seek::Templates::Extract::DataFileRightFieldExtractor.new(self).populate(self)
    else
      Set.new
    end
  end

  def initialise_assay_from_template
    assay = Assay.new
    if contains_extractable_excel?
      warnings = Seek::Templates::Extract::AssayRightfieldExtractor.new(self).populate(assay)
      return assay, warnings
    else
      return assay, Set.new
    end
  end

  has_task :sample_extraction
  has_task :sample_persistence
  has_task :unzip
  has_task :unzip_persistence
end
