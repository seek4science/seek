module AdminHelper

  #true for tags with a name longer than 50chars or containing a semi-colon, comma, forward slash, colon or pipe character
  def dubious_tag?(tag)
    tag.name.length>50 || [";",",",":","/","|"].detect{|c| tag.name.include?(c)}
  end

  #returns a list of people where their is_pal? flag doesn't match their profile role
  def pal_mismatchces
      pal_role=Role.find(:first,:conditions=>{:name=>"Sysmo-DB Pal"})
      Person.find(:all).select do |p|
        p.is_pal? != p.roles.include?(pal_role)        
      end
  end
end
