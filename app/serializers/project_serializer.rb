class ProjectSerializer < AvatarObjSerializer

  # class ProjectSerializer < ActiveModel::Serializer
  attributes :title, :description,
             :web_page, :wiki_page, :default_license, :start_date, :end_date

  attribute :default_policy, if: :show_default_policy?

  attribute :members

  def members
    current_members = []
    object.current_group_memberships.each { |membership|
      current_members << {:person_id => "#{membership.person_id}",
                          :institution_id => "#{membership.institution.id}" }
    }
    current_members
  end

  attribute :use_default_policy, if: :show_use_default_policy?

  has_many :project_administrators
  has_many :pals
  has_many :asset_housekeepers
  has_many :asset_gatekeepers

  def default_policy
    BaseSerializer.convert_policy object.default_policy
  end

  attribute :edam_topics do
    edam_annotations('edam_topics')
  end

  include_related_items

  def show_default_policy?
    has_default_policy = !object.default_policy.nil?
    respond_to_manage = object.respond_to?('can_manage?')
    current_user = User.current_user
    can_manage = object.can_manage?(current_user)
    return has_default_policy && respond_to_manage && can_manage
  end

  def show_use_default_policy?
    return show_default_policy? && !object.use_default_policy.nil?
  end
end
