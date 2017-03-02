class ProjectSerializer < BaseSerializer
  attributes :id, :title, :description,
             :avatars, :organisms

  has_many :associated do
    associated_resources(object)
  end
end