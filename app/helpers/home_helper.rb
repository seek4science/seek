require 'feedzirra'

module HomeHelper

  RECENT_SIZE=5

  def recent_project_changes_hash

    projects=current_user.person.projects
    
    people=Person.find(:all,:order=>'updated_at DESC')
    selected_people=[]

    people.each do |p|      
      selected_people << p if !(projects & p.projects).empty?
      break if selected_people.size>=RECENT_SIZE
    end
    item_hash=classify_for_tabs(selected_people)

    classes=Seek::Util.persistent_classes.select do |c|
        c.is_isa? || c.is_asset?
    end

    classes << Event if Seek::Config.events_enabled

    classes.each do |c|
      valid=[]
      c.find(:all,:order=>'updated_at DESC').each do |i|
        valid << i if projects.include?(i.project) && (!i.authorization_supported? || i.can_view?(current_user))
        break if valid.size >= RECENT_SIZE
      end
      item_hash.merge! classify_for_tabs(valid)
    end

    item_hash

  end

  def recent_changes_hash

    item_hash=classify_for_tabs(Person.find(:all,:order=>'updated_at DESC',:limit=>RECENT_SIZE))
    item_hash.merge! classify_for_tabs(Project.find(:all,:order=>'updated_at DESC',:limit=>RECENT_SIZE))

    classes=Seek::Util.persistent_classes.select do |c|
        c.is_isa? || c.is_asset?
    end

    classes << Event if Seek::Config.events_enabled

    classes.each do |c|
      valid=[]
      c.find(:all,:order=>"updated_at DESC").each do |i|
        valid << i if !i.authorization_supported? || i.can_view?(current_user)
        break if valid.size>=RECENT_SIZE
      end
      item_hash.merge! classify_for_tabs(valid)
    end

    item_hash
  end

  def recently_downloaded_items time=1.month.ago, number_of_item=10
    activity_logs = ActivityLog.find(:all,:group => "activity_loggable_type, activity_loggable_id", :order => "count(*) DESC", :conditions => ["action = ? AND updated_at > ?", 'download', time])
    items = []
    activity_logs.each do |activity_log|
      items.push activity_log.activity_loggable if !activity_log.activity_loggable.nil?
    end
    items.take(number_of_item)
  end

  def recently_viewed_items time=1.month.ago, number_of_item=10
    activity_logs = ActivityLog.find(:all,:group => "activity_loggable_type, activity_loggable_id", :order => "count(*) DESC", :conditions => ["action = ? AND updated_at > ?", 'show', time])
    #take out only Asset and Publication log
    activity_logs = activity_logs.select{|activity_log| ['DataFile', 'Model', 'Sop', 'Publication'].include?(activity_log.activity_loggable_type)}
    items = []
    activity_logs.each do |activity_log|
      items.push activity_log.activity_loggable if !activity_log.activity_loggable.nil?
    end
    items.take(number_of_item)
  end

  # get feeds from multiple sites
  def get_feeds feed_urls=nil
      # fetching multiple feeds
    unless feed_urls.blank?
      #trim the url element
      feed_urls=feed_urls.each{|feed_url| feed_url.strip! }
      feeds = Feedzirra::Feed.fetch_and_parse(feed_urls)
      feeds
    end
  end

  def display_single_feed feed=nil, number_of_entries=3
      html=''
      # atom format use entries while rss format use items
      entries = try_block{feed.entries} || try_block{feed.items}
      unless !entries
        entries.take(number_of_entries).each do |entry|
          #get the link of the entry
          entry_link = (check_entry_link(try_block{entry.url})) || (check_entry_link(try_block{entry.links.first})) || (check_entry_link(try_block{entry.link})) || (check_entry_link(try_block{entry.id})) || ''
          entry_title = try_block{entry.title} || ''
          unless entry_title.blank?
            html << "<li>"
            html << link_to("#{entry_title}", "#{entry_link}")
            html << "</li>"
          end
        end
      end
      html
  end

  private
  def check_entry_link entry_link=nil
    return nil if entry_link.nil? || !entry_link.to_s.start_with?('http://')
    entry_link.to_s
  end

end
