module AdminHelper

  #true for tags with a name longer than 50chars or containing a semi-colon, comma, forward slash, colon or pipe character
  def dubious_tag?(tag)
    tag.text.length>50 || [";",",",":","/","|"].detect{|c| tag.text.include?(c)}
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
  
  #takes the terms and scores received from SearchStats, and generates a string
  def search_terms_summary terms_and_scores    
    return "<span class='none_text'>No search queries during this period</span>" if terms_and_scores.empty?
    words=terms_and_scores.collect{|ts| "#{ts[0]}(#{ts[1]})" }
    words.join(", ")
  end



end
