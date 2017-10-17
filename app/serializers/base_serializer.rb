class BaseSerializer < SimpleBaseSerializer
  include ApiHelper
  include RelatedItemsHelper
  include Rails.application.routes.url_helpers

  # has_many :people
  # has_many :projects
  # has_many :institutions
  # has_many :investigations
  # has_many :studies
  # has_many :assays
  # has_many :data_files
  # has_many :models
  # has_many :sops
  # has_many :publications
  # has_many :presentations
  # has_many :events
  # has_many :strains
  # has_many :samples

  def associated(name)
    unless @associated[name].blank?
      items = @associated[name][:items]
      unless items.blank?
        items = items.sort { |x, y| x.id <=> y.id }
      end
      items
    else
      nil
    end
  end

  def people
    associated('Person')
   end

  def projects
    associated('Project')
  end

  def institutions
    associated('Institution')
  end

  def investigations
    associated('Investigation')
  end

  def studies
    associated('Study')
   end

  def assays
    associated('Assay')
  end

  def data_files
    associated('DataFile')
  end

  def models
    associated('Model')
  end

  def sops
    associated('Sop')
  end

  def publications
    associated('Publication')
  end

  def presentations
    associated('Presentation')
  end

  def events
    associated('Event')
  end

  def strains
    associated('Strain')
  end

  def samples
    associated('Sample')
  end


  def self_link
    polymorphic_path(object)
  end

  def _links
      {self: self_link}
  end

  #avoid dash-erizing attribute names
  def format_name(attribute_name)
    attribute_name.to_s
  end

  def _meta
    meta = super
    if object.respond_to?('uuid')
      meta[:uuid] = object.uuid
    end
    meta[:base_url]=base_url
    meta
  end

  def initialize(object, options = {})
    super

    #access related resources with proper authorization & ignore version subclass
    if (object.class.to_s.include?("::Version"))
      @associated = associated_resources(object.parent)
    else
      @associated = associated_resources(object)
    end
  end

end
