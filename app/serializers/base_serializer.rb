class BaseSerializer < SimpleBaseSerializer
  include ApiHelper
  include RelatedItemsHelper

  has_many :investigations
  has_many :people
  has_many :projects
  has_many :institutions
  has_many :studies
  has_many :assays
  has_many :data_files
  has_many :models
  has_many :sops
  has_many :publications
  has_many :presentations
  has_many :events
  has_many :strains
  has_many :samples

  def people
    @associated['Person'][:items]
  end

  def projects
    @associated['Project'][:items]
  end

  def institutions
    @associated['Institution'][:items]
  end

  def investigations
    @associated['Investigation'][:items]
  end

  def studies
    @associated['Study'][:items]
  end

  def assays
    @associated['Assay'][:items]
  end

  def data_files
    @associated['DataFile'][:items]
  end

  def models
    @associated['Model'][:items]
  end

  def sops
    @associated['Sop'][:items]
  end

  def publications
    @associated['Publication'][:items]
  end

  def presentations
    @associated['Presentation'][:items]
  end

  def events
    @associated['Event'][:items]
  end

  def strains
    @associated['Strain'][:items]
  end

  def samples
    @associated['Sample'][:items]
  end


  def self_link
    #{base_url}//#{type}/#{id}
    "/#{type}/#{object.id}"
  end

  def _links
      {self: self_link}
      end

  #avoid dash-erizing attribute names
  def format_name(attribute_name)
    attribute_name.to_s
  end

  def _meta
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
