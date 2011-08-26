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
       when "activity_logs","versions","attributions","relationships"
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
      presentation
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

  belongs_to :content_blob #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates

  acts_as_solr(:fields=>[:description,:title,:original_filename,:tag_counts,:annotations,:fs_search_fields]) if Seek::Config.solr_enabled

  has_many :studied_factors, :conditions =>  'studied_factors.data_file_version = #{self.version}'

  acts_as_uniquely_identifiable

  explicit_versioning(:version_column => "version") do

    include SpreadsheetUtil
    acts_as_versioned_resource
    
    belongs_to :content_blob
    
    has_many :studied_factors, :primary_key => "data_file_id", :foreign_key => "data_file_id", :conditions =>  'studied_factors.data_file_version = #{self.version}'
    
    def relationship_type(assay)
      parent.relationship_type(assay)
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
    all_datafiles = DataFile.find(:all, :order => "ID asc")
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
  def annotations
    annotations = []
    content_blob.worksheets.each do |ws|
      ws.cell_ranges.each do |cell_range|
        annotations = annotations | cell_range.annotations.collect{|a| a.value.text}
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
end
