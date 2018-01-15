class ProjectSerializer < AvatarObjSerializer

  # class ProjectSerializer < ActiveModel::Serializer
  attributes :title, :description,
             :web_page, :wiki_page

  attribute :default_policy, if: :show_default_policy?

  def default_policy
    convert_policy object.default_policy
  end

  has_many :organisms,  include_data: true

  has_many :people
  has_many :institutions
  has_many :programmes
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :data_files
  has_many :models
  has_many :sops
  has_many :publications
  has_many :presentations
  has_many :events

  def show_default_policy?
    has_default_policy = !object.default_policy.nil?
    respond_to_manage = object.respond_to?('can_manage?')
    current_user = User.current_user
    can_manage = object.can_manage?(current_user)
    return has_default_policy && respond_to_manage && can_manage
  end
end
