class PersonSerializer < AvatarObjSerializer
  attributes :id, :title,
             :first_name, :last_name,
             :email, :description

  # attribute :myattr do
  #   object.title.upcase
  # end

  has_many :work_groups

end
