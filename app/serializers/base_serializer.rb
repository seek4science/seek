class BaseSerializer < SimpleBaseSerializer
  include ApiHelper
  include RelatedItemsHelper

  # has_many :assays, include_data:true do
  #   @associated["Assay"][:items]
  # end
  # has_many :data_files, include_data:true do
  #   @associated["DataFile"][:items]
  # end
  # has_many :events, include_data:true do
  #   @associated["Event"][:items]
  # end
  # has_many :investigations, include_data:true do
  #   @associated["Investigation"][:items]
  # end
  # has_many :institutions, include_data:true do
  #   @associated["Institution"][:items]
  # end
  # has_many :models, include_data:true do
  #   @associated["Model"][:items]
  # end
  # has_many :people, include_data:true  do
  #    @associated["Person"][:items]
  #  end
  # has_many :presentations, include_data:true do
  #   @associated["Presentation"][:items]
  # end
  #  has_many :projects, include_data:true do
  #    @associated["Project"][:items]
  #  end
  # has_many :publications, include_data:true do
  #   @associated["Publication"][:items]
  # end
  # has_many :samples, include_data:true do
  #   @associated["Sample"][:items]
  # end
  # has_many :sops, include_data:true do
  #   @associated["Sop"][:items]
  # end
  #  has_many :studies, include_data:true do
  #    @associated["Study"][:items]
  #  end

  def self.rels(c, s)
    if c.name.blank?
      return
    end
    method_hash = {}
    begin
      resource_klass = c
      ['Person', 'Project', 'Institution', 'Investigation',
       'Study','Assay', 'DataFile', 'Model', 'Sop', 'Publication', 'Presentation', 'Event',
       'Workflow', 'TavernaPlayer::Run', 'Sweep', 'Strain', 'Sample'].each do |item_type|
        if item_type == 'TavernaPlayer::Run'
          method_name = 'runs'
        else
          method_name = item_type.underscore.pluralize
        end

        if resource_klass.method_defined? "related_#{method_name}"
          method_hash[item_type] = "related_#{method_name}"
        elsif resource_klass.method_defined?  "related_#{method_name.singularize}"
          method_hash[item_type] = "related_#{method_name.singularize}"
        elsif resource_klass.method_defined? method_name
          method_hash[item_type] = method_name
          # elsif item_type != 'Person' && resource_klass.method_defined? method_name.singularize # check is to avoid Person.person
          #   method_hash[item_type] = method_name
        else
          []
        end
      end
    rescue
    end
    method_hash
    unless  method_hash.blank?
      method_hash.each do |k, v|
        begin
          s.has_many v, key: k.pluralize.downcase, include_data: true
        end
      end
    end

  end

  #avoid dash-erizing attribute names
  def format_name(attribute_name)
    attribute_name.to_s
  end

  def meta
    #content-blob doesn't have timestamps
    if object.respond_to?('created_at')
      created = object.created_at
      updated = object.updated_at
    end
    if object.respond_to?('uuid')
      uuid = object.uuid
    end
    {
        created: created || "",
        modified: updated || "",
        uuid: uuid || "",
        base_url: base_url
    }
  end

  # def initialize(object, options = {})
  #   super
  #   @associated = associated_resources(object)
  # end
end