class PersonSerializer < BaseSerializer
  attributes :id, :title,
             :first_name, :last_name,
             :email, :description, :avatars

  # attribute :myattr do
  #   object.title.upcase
  # end

  has_many :work_groups
  has_many :associated do
    #object.institutions
    associated_resources(object) # ||  { "data": [] }
  end

end
