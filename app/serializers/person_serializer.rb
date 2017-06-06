class PersonSerializer < AvatarObjSerializer
  attributes :id, :title,
             :first_name, :last_name,
             :email, :description

  has_many :work_groups, include_data:true

end
