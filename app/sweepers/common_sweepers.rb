# To change this template, choose Tools | Templates
# and open the template in the editor.

#includes some helper methods for commonly used fragament expirations
module CommonSweepers

  def expire_all_fragments
    expire_annotation_fragments
    expire_all_favourite_fragments
    expire_organism_gadget
    expire_header_and_footer
    expire_new_object_gadget
  end

  def expire_new_object_gadget
    expire_fragment "new_object_gadget"
  end

  def expire_header_and_footer
    expire_fragment "header"
    expire_fragment "header_main"
    expire_fragment "footer"
  end

  def expire_annotation_fragments name=nil
    expire_fragment "sidebar_tag_cloud"
    expire_fragment "super_tag_cloud"
    if (name.nil?)
      expire_fragment(/suggestion_for.*/)
    else
      expire_fragment "suggestions_for_#{name}"
    end
  end

  #expires ALL fragment caches related to favourites
  def expire_all_favourite_fragments
    expire_fragment(/\/favourites\/user\/.*/)
  end
  
  def expire_organism_gadget
    expire_fragment "organisms_gadget"
  end
    
end
