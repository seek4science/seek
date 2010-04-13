module ForumsHelper
  
  # used to know if a topic has changed since we read it last
  def recent_topic_activity(topic)
    return false if not logged_in?
    return topic.replied_at > ((session[:topics] && session[:topics][topic.id]) || 3.days.ago) # was: last_active.  TODO: Could implement something to look at the user
  end 
  
  # used to know if a forum has changed since we read it last
  def recent_forum_activity(forum)
		return false unless logged_in? && forum.recent_topic
    return forum.recent_topic.replied_at > ((session[:forums] && session[:forums][forum.id]) || 3.days.ago) # was: last_active.  TODO: Could implement something to look at the user
  end
  
end
