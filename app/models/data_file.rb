require_dependency 'seek/util'

class DataFile < ActiveRecord::Base
  include Seek::Data::SpreadsheetExplorerRepresentation
  include Seek::Rdf::RdfGeneration

  attr_accessor :parent_name

  # searchable must come before acts_as_asset call
  searchable(auto_index: false) do
    text :spreadsheet_annotation_search_fields, :fs_search_fields
  end if Seek::Config.solr_enabled

  acts_as_asset

  include Seek::Dois::DoiGeneration

  scope :default_order, -> { order('title') }

  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a Data file with such title."

  has_one :content_blob, -> (r) { where('content_blobs.asset_version =?', r.version) }, as: :asset, foreign_key: :asset_id

  has_many :studied_factors, -> (r) { where('studied_factors.data_file_version =?', r.version) }
  has_many :extracted_samples, class_name: 'Sample', foreign_key: :originating_data_file_id

  scope :with_extracted_samples, -> { joins(:extracted_samples).uniq }

  explicit_versioning(version_column: 'version') do
    include Seek::Data::SpreadsheetExplorerRepresentation
    acts_as_doi_mintable(proxy: :parent)
    acts_as_versioned_resource
    acts_as_favouritable

    has_one :content_blob, -> (r) { where('content_blobs.asset_version =? AND content_blobs.asset_type =?', r.version, r.parent.class.name) },
            :primary_key => :data_file_id,:foreign_key => :asset_id

    has_many :studied_factors, -> (r) { where('studied_factors.data_file_version = ?', r.version) },
             primary_key: 'data_file_id', foreign_key: 'data_file_id'

    def relationship_type(assay)
      parent.relationship_type(assay)
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

    def event_ids=(_events_ids)
    end
  end

  def included_to_be_copied?(symbol)
    case symbol.to_s
      when 'activity_logs', 'versions', 'attributions', 'relationships', 'inverse_relationships', 'annotations'
        return false
      else
        return true
    end
  end

  def relationship_type(assay)
    # FIXME: don't like this hardwiring to assay within data file, needs abstracting
    assay_assets.find_by_assay_id(assay.id).try(:relationship_type)
  end

  def use_mime_type_for_avatar?
    true
  end

  # defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end

  # the annotation string values to be included in search indexing
  def spreadsheet_annotation_search_fields
    annotations = []
    if content_blob
      content_blob.worksheets.each do |ws|
        ws.cell_ranges.each do |cell_range|
          annotations = annotations | cell_range.annotations.collect{|a| a.value.text}
        end
      end
    end
    annotations
  end

  # FIXME: bad name, its not whether it IS a template, but whether it originates from a template
  def sample_template?
    possible_sample_types.any?
  end

  def possible_sample_types
    SampleType.sample_types_matching_content_blob(content_blob)
  end

  # a simple container for handling the matching results returned from #matching_data_files
  class ModelMatchResult < Struct.new(:search_terms, :score, :primary_key); end

  # return a an array of ModelMatchResult where the model id is the key, and the matching terms/values are the values
  def matching_models
    results = {}

    if Seek::Config.solr_enabled && contains_extractable_spreadsheet?
      search_terms = spreadsheet_annotation_search_fields | content_blob_search_terms | fs_search_fields | searchable_tags
      # make the array uniq! case-insensistive whilst mainting the original case
      dc = []
      search_terms = search_terms.inject([]) do |r, v|
        unless dc.include?(v.downcase)
          r << v
          dc << v.downcase
        end
        r
      end
      search_terms.each do |key|
        key = Seek::Search::SearchTermFilter.filter(key)
        unless key.blank?
          Model.search do |query|
            query.keywords key, fields: [:model_contents_for_search, :description, :searchable_tags]
          end.hits.each do |hit|
            unless hit.score.nil?
              results[hit.primary_key] ||= ModelMatchResult.new([], 0, hit.primary_key)
              results[hit.primary_key].search_terms << key
              results[hit.primary_key].score += hit.score
            end
          end
        end
      end
    end

    results.values.sort_by { |a| -a.score }
  end

  def related_samples
    extracted_samples
  end

  # Extracts samples using the given sample_type
  # Returns a list of extracted samples, including
  def extract_samples(sample_type, confirm = false)
    samples = sample_type.build_samples_from_template(content_blob)
    extracted = []
    samples.each do |sample|
      sample.project_ids = project_ids
      sample.contributor = contributor
      sample.originating_data_file = self
      sample.policy = self.policy
      sample.save if sample.valid? && confirm

      extracted << sample
    end
    extracted
  end

  #creates a new DataFile that registers an openBIS dataset
  def self.build_from_openbis(openbis_endpoint,dataset_perm_id)
    dataset = Seek::Openbis::Dataset.new(openbis_endpoint,dataset_perm_id)
    df=dataset.create_seek_datafile
    df.policy=openbis_endpoint.policy.deep_copy
    df
  end

  #indicates that this is an openBIS based DataFile
  def openbis?
    content_blob && content_blob.openbis?
  end

  def openbis_size_download_restricted?
    openbis? && content_blob.openbis_dataset.size>Seek::Config.openbis_download_limit
  end

  def download_disabled?
    super || openbis_size_download_restricted?
  end

end
