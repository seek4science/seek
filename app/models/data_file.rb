require 'acts_as_asset'
require 'acts_as_versioned_resource'
require 'explicit_versioning'
require 'grouped_pagination'
require 'title_trimmer'

class DataFile < ActiveRecord::Base

  include SpreadsheetUtil

  acts_as_asset
  acts_as_trashable

  title_trimmer

   def included_to_be_copied? symbol
     case symbol.to_s
       when "activity_logs","versions","attributions","relationships","inverse_relationships","annotations"
         return false
       else
         return true
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

  validates_presence_of :title

  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a Data file with such title."

  has_one :content_blob, :as => :asset, :foreign_key => :asset_id ,:conditions => 'asset_version= #{self.version}'

  acts_as_solr(:fields=>[:description,:title,:original_filename,:searchable_tags,:spreadsheet_annotation_search_fields,:fs_search_fields]) if Seek::Config.solr_enabled

  has_many :studied_factors, :conditions =>  'studied_factors.data_file_version = #{self.version}'

  explicit_versioning(:version_column => "version") do
    include SpreadsheetUtil
    acts_as_versioned_resource
    
    has_many :studied_factors, :primary_key => "data_file_id", :foreign_key => "data_file_id", :conditions =>  'studied_factors.data_file_version = #{self.version}'
    
    def relationship_type(assay)
      parent.relationship_type(assay)
    end

    def to_presentation_version
      returning Presentation::Version.new do |presentation_version|
        presentation_version.attributes.keys.each do |attr|
          presentation_version.send("#{attr}=", send("#{attr}")) if respond_to? attr and attr!="id"
          DataFile.reflect_on_all_associations.select { |a| [:has_many, :has_and_belongs_to_many, :has_one].include?(a.macro) }.each do |a|
            disable_authorization_checks do
              presentation_version.send("#{a.name}=", send(a.name)) if presentation_version.respond_to?("#{a.name}=")
            end
          end
        end
      end
    end
  end


  def studies
    assays.collect{|a| a.study}.uniq
  end

  # get a list of DataFiles with their original uploaders - for autocomplete fields
  # (authorization is done immediately to save from iterating through the collection again afterwards)
  #
  # Parameters:
  # - user - user that performs the action; this is required for authorization
  def self.get_all_as_json(user)
    all_datafiles = DataFile.find(:all, :order => "ID asc",:include=>[:policy,{:policy=>:permissions}])
    datafiles_with_contributors = all_datafiles.collect{ |d|
        d.can_view?(user) ?
        (contributor = d.contributor;
        { "id" => d.id,
          "title" => d.title,
          "contributor" => contributor.nil? ? "" : "by " + contributor.person.name,
          "type" => self.name } ) :
        nil }

    datafiles_with_contributors.delete(nil)

    return datafiles_with_contributors.to_json
  end

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

  def to_presentation!
    returning self.to_presentation do |presentation|
      class << presentation
        #disabling versioning, since I have manually copied the versions of the data file over
        def save_version_on_create
        end
      end

      #TODO: should we throw an exception if the user isn't authorized to make these changes?
      if User.current_user.admin? or self.can_delete?
        disable_authorization_checks {
          presentation.save!
          #TODO: perhaps the deletion of the data file should also be here? We are already throwing an exception if save fails for some reason
        }
      end

      #copying annotations has to be done after saving the presentation due to limitations of the annotation plugin
      disable_authorization_checks do #disabling because annotations should be copied over even if the user would normally lack permission to do so
        presentation.annotations = self.annotations
      end
    end
  end

  def to_presentation
    presentation_attrs = attributes.delete_if { |k, v| k=="template_id" || k =="id" }

    returning Presentation.new(presentation_attrs) do |presentation|
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
    end
  end
end
