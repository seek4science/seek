class ProjectSerializer < AvatarObjSerializer
#class ProjectSerializer < ActiveModel::Serializer
  attributes :title, :description,
             :web_page, :wiki_page
  has_many :organisms,  include_data:true
end