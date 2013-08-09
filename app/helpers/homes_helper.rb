
module HomesHelper

  include UsersHelper
  include AssetsHelper
  include ImagesHelper

  RECENT_SIZE=5

  def home_description_text
    simple_format(auto_link(Seek::Config.home_description.html_safe,:sanitize=>false),{},:sanitize=>false)
  end

  def recent_project_changes_hash

    projects=current_user.person.projects
    
    people=Person.order('updated_at DESC')
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
      c.order('updated_at DESC').each do |i|
        valid << i if !(projects & i.projects).empty? && i.can_view?
        break if valid.size >= RECENT_SIZE
      end
      item_hash.merge! classify_for_tabs(valid)
    end

    item_hash

  end

  def recent_changes_hash

    item_hash=classify_for_tabs(Person.order('updated_at DESC').limit(RECENT_SIZE))
    item_hash.merge! classify_for_tabs(Project.order('updated_at DESC').limit(RECENT_SIZE))

    classes=Seek::Util.persistent_classes.select do |c|
        c.is_isa? || c.is_asset?
    end

    classes << Event if Seek::Config.events_enabled

    classes.each do |c|
      valid=[]
      c.order("updated_at DESC").each do |i|
        valid << i if !i.authorization_supported? || i.can_view?(current_user)
        break if valid.size>=RECENT_SIZE
      end
      item_hash.merge! classify_for_tabs(valid)
    end

    item_hash
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
            html << link_to("#{(entry_title)}", "#{entry_link}", :title => tooltip, :target=>"_blank")
            html << "<div class='feedinfo none_text'>"
            html << feed_title
            html << " - #{time_ago_in_words(entry_date)} ago" unless entry_date.nil?
            html << "</div>"
            html << "</li>"
          end
      end
      html.html_safe
  end

  def recently_downloaded_item_logs_hash time=1.month.ago, number_of_item=10
    Rails.cache.fetch("download_activity_#{current_user_id}") do
      activity_logs = ActivityLog.where(["action = ? AND created_at > ?", 'download', time]).order("created_at DESC")
      selected_activity_logs = []
      selected_items = []
      count = 0
      activity_logs.each do |activity_log|
        item = activity_log.activity_loggable
        if !item.nil? && !selected_items.include?(item) && item.can_view?
          selected_items.push item
          selected_activity_logs.push activity_log
          count += 1
        end
        break if count == number_of_item
      end
      convert_logs_to_hash selected_activity_logs
    end
  end

  def recently_added_item_logs_hash time=1.month.ago, number_of_item=10
    Rails.cache.fetch("create_activity_#{current_user_id}") do
      item_types = Seek::Util.user_creatable_types.collect{|type| type.name}
      activity_logs = ActivityLog.where(["action = ? AND created_at > ? AND activity_loggable_type in (?)", 'create', time, item_types]).order("created_at DESC")
      selected_activity_logs = []
      count = 0
      activity_logs.each do |activity_log|
        item = activity_log.activity_loggable
        if !item.nil? && item_types.include?(activity_log.activity_loggable_type) && item.can_view?
          selected_activity_logs.push activity_log
          count += 1
        end
        break if count == number_of_item
      end
      convert_logs_to_hash selected_activity_logs
    end
  end

  def convert_logs_to_hash logs
    logs.collect do |log|
      item = log.activity_loggable
      {
          type: text_for_resource(item),
          title: item.title,
          action: log.action,
          description: item.respond_to?(:description) ? item.description : nil,
          abstract: item.respond_to?(:abstract) ? item.abstract : nil,
          created_at: log.created_at,
          avatar_image: resource_avatar(item,:class=>"home_asset_icon"),
          url: show_resource_path(item),
          log_id: log.id
      }
    end
  end

  def display_single_log_item_hash item, action
      html=''
       unless item.blank?
         image=item[:avatar_image]
          icon  = link_to(image, item[:url], :class=> "asset", :title => tooltip_title_attrib(item[:type]))

          description = item[:description] || item[:abstract]

          tooltip=tooltip_title_attrib("<p>#{description.blank? ? 'No description' : description}</p><p class='feedinfo none_text'>#{item[:created_at]}</p>")
          html << "<li class='homepanel_item'>"
          html << "#{icon} "
          html << link_to(h(item[:title]), item[:url], :title => tooltip)
          html << "<div class='feedinfo none_text'>"
          html << "<span>#{item[:type]} - #{action} #{time_ago_in_words(item[:created_at])} ago</span>"
          html << "</div>"
          html << "</li>"
      end
      html.html_safe
  end

end


