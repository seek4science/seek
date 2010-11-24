module AdminHelper

  #true for tags with a name longer than 50chars or containing a semi-colon, comma, forward slash, colon or pipe character
  def dubious_tag?(tag)
    tag.name.length>50 || [";",",",":","/","|"].detect{|c| tag.name.include?(c)}
  end
  
  def admin_mail_to_links   
    result=""
    admins=Person.admins
    admins.each do |person|
      result << mail_to(person.email,person.name)
      result << ", " unless admins.last==person
    end
    return result    
  end

end
