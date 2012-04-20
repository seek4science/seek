require 'acts_as_asset'
require 'acts_as_versioned_resource'
require 'explicit_versioning'
require 'grouped_pagination'
require 'title_trimmer'

class DataFile < ActiveRecord::Base

  include Seek::DataFileExtraction

  acts_as_asset
  acts_as_trashable

  title_trimmer

  validates_presence_of :title

  after_save :queue_background_reindexing if Seek::Config.solr_enabled

  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a Data file with such title."

  belongs_to :content_blob #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates

  searchable(:auto_index=>false) do
    text :description, :title, :original_filename, :searchable_tags, :spreadsheet_annotation_search_fields,:fs_search_fields, :spreadsheet_contents_for_search,
         :assay_type_titles,:technology_type_titles
  end if Seek::Config.solr_enabled

  has_many :studied_factors, :conditions =>  'studied_factors.data_file_version = #{self.version}'

  explicit_versioning(:version_column => "version") do
    include Seek::DataFileExtraction
    acts_as_versioned_resource
    
    belongs_to :content_blob
    
    has_many :studied_factors, :primary_key => "data_file_id", :foreign_key => "data_file_id", :conditions =>  'studied_factors.data_file_version = #{self.version}'
    
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

  def included_to_be_copied? symbol
     case symbol.to_s
       when "activity_logs","versions","attributions","relationships","inverse_relationships", "annotations"
         return false
       else
         return true
     end
   end

  def convert_to_presentation
     presentation_attrs = self.attributes.delete_if{|k,v|k=="template_id" || k =="id"}
     presentation = Presentation.new presentation_attrs

      DataFile.reflect_on_all_associations.each do |a|
       if presentation.respond_to? "#{a.name.to_s.singularize}_ids=".to_sym and a.macro!=:belongs_to and !a.options.include? :through and included_to_be_copied?(a.name)
          association = self.send a.name

         if a.options.include? :as
           if !association.blank?
             association.each do |item|
               attrs = item.attributes.delete_if{|k,v|k=="id" || k =="#{a.options[:as]}_id" || k =="#{a.options[:as]}_type"}
               if !attrs["person_id"].nil? and Person.find(:first,:conditions => ["id =?",attrs["person_id"].to_i]).nil?
                 attrs["person_id"] = self.contributor.person.id
               end
              presentation.send("#{a.name}".to_sym).send :build,attrs
             end
           end
         else
          presentation.send "#{a.name.to_s.singularize}_ids=".to_sym, association.map(&:id)
         end
       end
     end

      presentation.policy = self.policy.deep_copy
      presentation.orig_data_file_id= self.id

    class << presentation
      def clone_versioned_data_file_model versioned_presentation, versioned_data_file
          versioned_presentation.attributes.keys.each do |key|
            versioned_presentation.send("#{key}=", eval("versioned_data_file.#{key}")) if versioned_data_file.respond_to? key.to_sym  and key!="id"
          end
      end

      def set_new_version
         self.version = DataFile.find(self.orig_data_file_id).version
      end

      def save_version_on_create
         df_versions = DataFile::Version.find(:all,:conditions=>["data_file_id =?",self.orig_data_file_id])
         df_versions.each do |df_version|
            rev = Presentation::Version.new
            self.clone_versioned_data_file_model(rev,df_version)
            rev.presentation_id = self.id
            saved = rev.save
            if saved
              # Now update timestamp columns on main model.
              # Note: main model doesnt get saved yet.
              update_timestamps(rev, self)
            end
         end
      end

      #Need to copy the annotations from the data_file to the presentation after the presentation got saved
      def after_save
        df = DataFile.find_by_id(self.orig_data_file_id)
        unless df.blank?
           df.annotations.each do |a|
             a.annotatable = self
             #need to call update without callbacks, otherwise a new version is created
             a.send(:update_without_callbacks)

             #versions for annotations are no longer enabled in SEEK - but this code is left here incase they are re-enabled in the future.
             a.versions.each do |av|
               av.annotatable =self
               av.save
             end
           end
        end
        super
      end
    end

    presentation
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


  #experimental stuff
  #this will eventually be moved to a generic mix, infact probably acts_as_authorized
  def self.all_authorized_for action, user=User.current_user
    person_id = user.nil? ? 0 : user.person.id
    c = lookup_count_for_action_and_user person_id
    if (c==DataFile.count)
      Rails.logger.warn("Lookup table is complete for person_id = #{person_id}")
      ids = lookup_ids_for_person_and_action action,person_id
      DataFile.find_all_by_id(ids)
    else
      Rails.logger.warn("Lookup table is incomplete for person_id = #{person_id} - doing things the slow way")
      #trigger background task to update table

      DataFile.all.select{|df| df.send("can_#{action}?") }
    end
  end

  def self.lookup_ids_for_person_and_action action,person_id
    ActiveRecord::Base.connection.select_all("select asset_id from data_file_auth_lookup where person_id = #{person_id} and can_#{action}=true").collect{|k| k.values}.flatten
  end

  def self.lookup_count_for_action_and_user person_id
    ActiveRecord::Base.connection.select_one("select count(*) from data_file_auth_lookup where person_id = #{person_id}").values[0].to_i
  end

  
end
