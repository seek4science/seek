module PeopleHelper
  
  def person_full_name person
    return person.profile.first_name + " " + person.profile.last_name
  end
  
end
