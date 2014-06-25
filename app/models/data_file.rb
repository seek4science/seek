require 'acts_as_asset'
require 'acts_as_versioned_resource'
require 'explicit_versioning'
require 'title_trimmer'

class DataFile < ActiveRecord::Base

  include Seek::Data::DataFileExtraction
  include Seek::Data::SpreadsheetExplorerRepresentation
  include Seek::Rdf::RdfGeneration

  attr_accessor :parent_name

  #searchable must come before acts_as_asset call
  searchable(:auto_index=>false) do
    text :spreadsheet_annotation_search_fields,:fs_search_fields,
         :assay_type_titles,:technology_type_titles, :spreadsheet_contents_for_search, :other_creators
  end if Seek::Config.solr_enabled

  acts_as_asset
  acts_as_trashable

  scope :default_order, order('title')

  title_trimmer

  validates_presence_of :title

  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a Data file with such title."

    has_one :content_blob, :as => :asset, :foreign_key => :asset_id ,:conditions => Proc.new{["content_blobs.asset_version =?", version]}

  has_many :studied_factors, :conditions => Proc.new{["studied_factors.data_file_version =?", version]}

  explicit_versioning(:version_column => "version") do
    include Seek::Data::DataFileExtraction
    include Seek::Data::SpreadsheetExplorerRepresentation
    acts_as_versioned_resource
    acts_as_favouritable
    
    has_one :content_blob,:primary_key => :data_file_id,:foreign_key => :asset_id,:conditions => Proc.new{["content_blobs.asset_version =? AND content_blobs.asset_type =?", version,parent.class.name]}
    
    has_many :studied_factors, :primary_key => "data_file_id", :foreign_key => "data_file_id", :conditions => Proc.new{["studied_factors.data_file_version =?", version]}
    
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

    def event_ids= events_ids

    end
  end

  def included_to_be_copied? symbol
     case symbol.to_s
       when "activity_logs","versions","attributions","relationships","inverse_relationships", "annotations"
         return false
       else
         return true
     end
   end

  has_many :sample_assets,:dependent=>:destroy,:as => :asset
  has_many :samples, :through => :sample_assets

    




  def relationship_type(assay)
    #FIXME: don't like this hardwiring to assay within data file, needs abstracting
    assay_assets.find_by_assay_id(assay.id).relationship_type  
  end

  def use_mime_type_for_avatar?
    true
  end

  #defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end

  #the annotation string values to be included in search indexing
  def spreadsheet_annotation_search_fields
    annotations = []
    unless content_blob.nil?
      content_blob.worksheets.each do |ws|
        ws.cell_ranges.each do |cell_range|
          annotations = annotations | cell_range.annotations.collect{|a| a.value.text}
        end
      end
    end
    annotations
  end

    #factors studied, and related compound text that should be included in search
  def fs_search_fields
    flds = studied_factors.collect do |fs|
      [fs.measured_item.title,
       fs.substances.collect do |sub|
         #FIXME: this makes the assumption that the synonym.substance appears like a Compound
         sub = sub.substance if sub.is_a?(Synonym)
         [sub.title] |
             (sub.respond_to?(:synonyms) ? sub.synonyms.collect { |syn| syn.title } : []) |
             (sub.respond_to?(:mappings) ? sub.mappings.collect { |mapping| ["CHEBI:#{mapping.chebi_id}", mapping.chebi_id, mapping.sabiork_id.to_s, mapping.kegg_id] } : [])
       end
      ]
    end
    flds.flatten.uniq
  end

  #a simple container for handling the matching results returned from #matching_data_files
  class ModelMatchResult < Struct.new(:search_terms,:score,:primary_key); end

  #return a an array of ModelMatchResult where the model id is the key, and the matching terms/values are the values
  def matching_models

    results = {}

    if Seek::Config.solr_enabled && contains_extractable_spreadsheet?
      search_terms = spreadsheet_annotation_search_fields | spreadsheet_contents_for_search | fs_search_fields | searchable_tags
      #make the array uniq! case-insensistive whilst mainting the original case
      dc = []
      search_terms = search_terms.inject([]) do |r,v|
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
            query.keywords key, :fields=>[:model_contents_for_search, :description, :searchable_tags]
          end.hits.each do |hit|
            unless hit.score.nil?
              results[hit.primary_key]||=ModelMatchResult.new([],0,hit.primary_key)
              results[hit.primary_key].search_terms << key
              results[hit.primary_key].score += hit.score
            end
          end
        end
      end
    end

    results.values.sort_by{|a| -a.score}
  end

end
