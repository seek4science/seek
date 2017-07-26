require 'digest/sha1'
class PersonSerializer < AvatarObjSerializer
  attributes :title, :description,
             :first_name, :last_name,
             :webpage,  :orcid
  attribute :email do
    Digest::SHA1.hexdigest(object.email)
  end
  has_many :work_groups, include_data:true

end
