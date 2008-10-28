module PeopleHelper
  
  def person_full_name person
    return person.profile.first_name + " " + person.profile.last_name
  end
  
  def person_avatar_image person
    return "avatar.png"
  end
  
end
