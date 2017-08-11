class ProjectSerializer < AvatarObjSerializer
#class ProjectSerializer < ActiveModel::Serializer
  attributes :title, :description,
             :webpage, :internal_webpage
  has_many :organisms,  include_data:true
end