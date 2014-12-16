
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
    text :spreadsheet_annotation_search_fields,:fs_search_fields
  end if Seek::Config.solr_enabled

  acts_as_asset

  include Seek::Dois::DoiGeneration

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

    def to_presentation_version
      Presentation::Version.new.tap do |presentation_version|
        presentation_version.attributes.keys.each do |attr|
          presentation_version.send("#{attr}=", send("#{attr}")) if respond_to? attr and attr!="id"
        end
        DataFile::Version.reflect_on_all_associations.select { |a| [:has_many, :has_and_belongs_to_many, :has_one].include?(a.macro) }.each do |a|
          disable_authorization_checks do
            presentation_version.send("#{a.name}=", send(a.name)) if presentation_version.respond_to?("#{a.name}=")
            #asset_type: 'DataFile' --> 'Presentation'. As the above assignment only change the asset_id
            if a.name == :content_blob
              presentation_version.send(a.name).send "asset_type=", "Presentation"
            end
          end
        end

      end
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

  def to_presentation
    presentation_attrs = attributes.delete_if { |k, v| !(::Presentation.new.attributes.include?(k))}

    Presentation.new(presentation_attrs).tap do |presentation|
      DataFile.reflect_on_all_associations.select { |a| [:has_many, :has_and_belongs_to_many, :has_one].include?(a.macro) && !a.through_reflection }.each do |a|
        #disabled, because even if the user doing the conversion would not normally
        #be able to associate an item with his data_file/presentation, the pre-existing
        #association created by someone who was allowed, should carry over to the presentation
        #based on the data file.
        disable_authorization_checks do
          #annotations and versions have to be handled specially
          presentation.send("#{a.name}=", send(a.name)) if presentation.respond_to?("#{a.name}=") and a.name != :annotations and a.name != :versions
        end
      end

      disable_authorization_checks { presentation.versions = versions.map(&:to_presentation_version) }
      presentation.policy = policy.deep_copy
      presentation.orig_data_file_id = id

      class << presentation
        #disabling versioning, since I have manually copied the versions of the data file over
        def save_version_on_create
        end

        def set_new_version
          self.version = DataFile.find(self.orig_data_file_id).version
        end
      end

      #TODO: should we throw an exception if the user isn't authorized to make these changes?
      if User.current_user.admin? || self.can_delete?
        disable_authorization_checks {
          presentation.save!
          #TODO: perhaps the deletion of the data file should also be here? We are already throwing an exception if save fails for some reason
        }
      end

      #copying annotations has to be done after saving the presentation due to limitations of the annotation plugin
      disable_authorization_checks do #disabling because annotations should be copied over even if the user would normally lack permission to do so
        presentation.annotations = self.annotations.select{|a| a.attribute_name == 'tag' || a.attribute_name == "scale"}
        presentation.save!
      end
    end
  end

  #a simple container for handling the matching results returned from #matching_data_files
  class ModelMatchResult < Struct.new(:search_terms,:score,:primary_key); end

  #return a an array of ModelMatchResult where the model id is the key, and the matching terms/values are the values
  def matching_models

    results = {}

    if Seek::Config.solr_enabled && contains_extractable_spreadsheet?
      search_terms = spreadsheet_annotation_search_fields | content_blob_search_terms | fs_search_fields | searchable_tags
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
