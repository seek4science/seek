require 'atom'

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
        valid << i if !(projects & i.projects).empty? && i.can_view?
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

  def recently_downloaded_item_logs time=1.month.ago, number_of_item=10
    activity_logs = ActivityLog.find(:all, :include => "activity_loggable", :order => "created_at DESC", :conditions => ["action = ? AND created_at > ?", 'download', time])
    selected_activity_logs = []
    selected_items = []
    count = 0
    activity_logs.each do |activity_log|
       item = activity_log.activity_loggable
       if !item.nil? and item.can_view? and !selected_items.include? item
         selected_items.push item
         selected_activity_logs.push activity_log
         count += 1
       end
       break if count == number_of_item
    end
    #filter by can_view?
    selected_activity_logs
  end

  def recently_added_item_logs time=1.month.ago, number_of_item=10
    item_types = Seek::Util.user_creatable_types.collect{|type| type.name}
    activity_logs = ActivityLog.find(:all, :include => "activity_loggable", :order => "created_at DESC", :conditions => ["action = ? AND created_at > ? AND activity_loggable_type in (?)", 'create', time, item_types])
    selected_activity_logs = []
    count = 0
    activity_logs.each do |activity_log|
       item = activity_log.activity_loggable
       if !item.nil? and item.can_view? and item_types.include?(activity_log.activity_loggable_type)
         selected_activity_logs.push activity_log
         count += 1
       end
       break if count == number_of_item
    end
    selected_activity_logs
  end

  # get multiple feeds from multiple sites
  def get_feed feed_url=nil
    unless feed_url.blank?
      #trim the url element
      feed_url.strip!
      begin
        feed = Atom::Feed.load_feed(URI.parse(feed_url))
      rescue
        feed = nil
      end
      feed
    end
  end

  def filter_feeds_entries_with_chronological_order feeds, number_of_entries=10
    filtered_entries = []
    unless feeds.blank?
      feeds.each do |feed|
         entries = try_block{feed.entries}
         #concat the source of the entry in the entry title, used later on to display
         unless entries.blank?
           entries.each{|entry| entry.title<< "***#{feed.title}" if entry.title}
         end
         filtered_entries |= entries.take(number_of_entries) if entries
      end
    end
    filtered_entries.sort {|a,b| (try_block{b.updated} || try_block{b.published} || try_block{b.last_modified} || 10.year.ago) <=> (try_block{a.updated} || try_block{a.published} || try_block{a.last_modified} || 10.year.ago)}.take(number_of_entries)
  end


  def display_single_entry entry
      html=''
      unless entry.blank?
          #get the link of the entry
          entry_link = try_block{entry.links.alternate.href}
          entry_title = entry.title || "Unknown title"
          feed_title = entry.feed_title || "Unknown publisher"
          entry_date = try_block{entry.updated} || try_block{entry.published} || try_block{entry.last_modified}
          entry_summary = truncate(strip_tags(entry.summary || entry.content),:length=>500)
          tooltip=tooltip_title_attrib("<p>#{entry_summary}</p><p class='feedinfo none_text'>#{entry_date.strftime('%c') unless entry_date.nil?}</p>")
          unless entry_title.blank? || entry_link.blank?
            html << "<li class='homepanel_item'>"
            html << link_to("#{h(entry_title)}", "#{entry_link}", :title => tooltip, :target=>"_blank")
            html << "<div class='feedinfo none_text'>"
            html << feed_title
            html << " - #{time_ago_in_words(entry_date)} ago" unless entry_date.nil?
            html << "</div>"
            html << "</li>"
          end
      end
      html
  end


  def display_single_item item, action, at_time
      html=''
       unless item.blank?
         image=resource_avatar(item,:class=>"home_asset_icon")
          icon  = link_to_draggable(image, show_resource_path(item), :id=>model_to_drag_id(item), :class=> "asset", :title => tooltip_title_attrib(text_for_resource(item)))

          path = url_for(item)
          description = try_block{item.description} || try_block{item.abstract}
          tooltip=tooltip_title_attrib("<p>#{description.blank? ? 'No description' : h(description)}</p><p class='feedinfo none_text'>#{at_time}</p>")
          html << "<li class='homepanel_item'>"
          html << "#{icon} "
          html << link_to("#{h(item.title)}", path, :title => tooltip)
          html << "<div class='feedinfo none_text'>"
          html << "<span>#{text_for_resource(item)} - #{action} #{time_ago_in_words(at_time)} ago</span>"
          html << "</div>"
          html << "</li>"
      end
      html
  end

end


