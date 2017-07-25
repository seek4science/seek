class PersonSerializer < AvatarObjSerializer
  attributes :title, :description,
             :first_name, :last_name,
             :email, :webpage,  :orcid

  has_many :work_groups, include_data:true

end
