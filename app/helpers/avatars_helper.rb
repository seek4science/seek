module AvatarsHelper
  
  def all_avatars_link(avatars_for_instance)
    eval("#{avatars_for_instance.class.name.downcase}_avatars_url(#{avatars_for_instance.id})")
  end
  
  def new_avatar_link(avatar_for_instance)
    eval("new_#{avatar_for_instance.class.name.downcase}_avatar_url(#{avatar_for_instance.id})")
  end
  
end
