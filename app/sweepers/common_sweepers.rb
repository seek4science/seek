# To change this template, choose Tools | Templates
# and open the template in the editor.

# includes some helper methods for commonly used fragament expirations
module CommonSweepers
  def expire_header_and_footer
    expire_fragment(/header.*/)
    expire_fragment(/footer.*/)
  end

  def expire_download_activity
    expire_fragment(/download_activity.*/)
  end

  def expire_create_activity
    expire_fragment(/create_activity.*/)
  end

  def expire_resource_list_item_action_partial
    expire_fragment(/rli_actions.*/)
  end

  def expire_resource_list_item_content(item = nil)
    if item.nil?
      expire_fragment(/rli_.*/)
    else
      expire_fragment(/rli_#{item.cache_key}.*/)
    end
  end

  # fragments that should change due to authorization changes
  def expire_auth_related_fragments
    expire_download_activity
    expire_create_activity
    expire_resource_list_item_action_partial
  end

  def expire_annotation_fragments(name = nil)
    expire_fragment('sidebar_tag_cloud')
    expire_fragment('super_tag_cloud')
    if name.nil?
      expire_fragment(/suggestion_for.*/)
    else
      expire_fragment("suggestions_for_#{name}")
    end
  end

  # expires ALL fragment caches related to favourites
  def expire_all_favourite_fragments
    expire_fragment(/\/favourites\/user\/.*/)
  end

  def expire_organism_gadget
    expire_fragment('organisms_gadget')
  end

  def expire_human_disease_gadget
    expire_fragment('human_diseases_gadget')
  end

  def expire_fragment(frag)
    ActionController::Base.new.expire_fragment(frag)
  end
end
