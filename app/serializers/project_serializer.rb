class ProjectSerializer < AvatarObjSerializer
  attributes :title, :description,
             :webpage, :internal_webpage
  has_many :organisms,  include_data:true
end