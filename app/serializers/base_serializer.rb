class BaseSerializer < SimpleBaseSerializer
  include PolicyHelper
  include RelatedItemsHelper
  include Seek::Util.routes

  attribute :policy, if: :show_policy?

  attribute :discussion_links, if: -> { object.is_discussable? } do
    object.discussion_links.collect do |link|
      { id: link.id.to_s, label: link.label, url: link.url }
    end
  end

  attribute :misc_links, if: -> { object.have_misc_links? } do
    object.misc_links.collect do |link|
      { id: link.id.to_s, label: link.label, url: link.url }
    end
  end

  def policy
    BaseSerializer.convert_policy object.policy
  end

  def associated(name)
    @associated ||= {}
    if @associated.key?(name)
      @associated[name]
    else
      items = (object.class.name.include?('::Version') ? object.parent : object).get_related(name).authorized_for('view')
      @associated[name] = items.empty? ? [] : items
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

  def documents
    associated('Document')
  end

  def organisms
    associated('Organism')
  end

  link(:self) { polymorphic_path(object) }

  # avoid dash-erizing attribute names
  def format_name(attribute_name)
    attribute_name.to_s
  end

  def _meta
    meta = super
    meta[:uuid] = object.uuid if object.respond_to?('uuid')
    meta
  end

  def BaseSerializer.convert_policy policy
    { 'access' => (PolicyHelper::access_type_key policy.access_type),
      'permissions' => (BaseSerializer.permits policy) }
  end

  def BaseSerializer.permits policy
    policy.permissions.map do |p|
      resource = { id: p.contributor_id.to_s, type: p.contributor_type.underscore.pluralize }

      { resource: resource, access: (PolicyHelper::access_type_key(p.access_type)) }
    end
  end

  def show_policy?
    return false unless object.respond_to?('can_manage?')
    return false unless object.respond_to?('policy')
    return object.can_manage?(User.current_user)
  end

  def submitter
    result = determine_submitter object
    if result.blank?
      []
    else
      [result]
    end
  end

  private

  def determine_submitter(object)
    return object.owner if object.respond_to?('owner')
    result = object.contributor if object.respond_to?('contributor') && !object.is_a?(Permission)
    return result
  end

  def serialize_assets_creators
    object.assets_creators.map do |c|
      { profile: c.creator_id ? person_path(c.creator_id) : nil,
        family_name: c.family_name,
        given_name: c.given_name,
        affiliation: c.affiliation,
        orcid: c.orcid }
    end
  end

  def controlled_vocab_annotations(property)
    terms = object.annotations_with_attribute(property, true).collect(&:value).sort_by(&:label)
    terms.collect do |term|
      {
        label: term.label,
        identifier: term.iri
      }
    end
  end
end
