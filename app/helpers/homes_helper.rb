
module HomesHelper
  include UsersHelper
  include AssetsHelper
  include ImagesHelper

  RECENT_SIZE = 5

  def home_description_text
    Seek::Config.home_description.html_safe
  end

  def imprint_text
    simple_format(auto_link(Seek::Config.imprint_description.html_safe, sanitize: false), {}, sanitize: false)
  end

  def show_announcements?
    logged_in_and_registered? && Seek::Config.show_announcements
  end

  # get multiple feeds from multiple sites
  def get_feed(feed_url = nil)
    unless feed_url.blank?
      # trim the url element
      feed_url.strip!
      begin
        feed = Atom::Feed.load_feed(URI.parse(feed_url))
      rescue
        feed = nil
      end
      feed
    end
  end

  def filter_feeds_entries_with_chronological_order(feeds, number_of_entries = 10)
    filtered_entries = []
    unless feeds.blank?
      feeds.each do |feed|
        entries = try_block { feed.entries }
        # concat the source of the entry in the entry title, used later on to display
        unless entries.blank?
          entries.each { |entry| entry.title << "***#{feed.title}" if entry.title }
        end
        filtered_entries |= entries.take(number_of_entries) if entries
      end
    end
    sort_filtered_entries(filtered_entries, number_of_entries)
  end

  def sort_filtered_entries(entries, _number_of_entries)
    entries.sort do |entry_a, entry_b|
      entry_sort_criteria(entry_a) <=> entry_sort_criteria(entry_b)
    end.take(number_of_entries)
  end

  def entry_sort_criteria(entry)
    entry.updated || entry.published || entry.last_modified || 10.years.ago
  end

  def display_single_entry(entry)
    return '' if entry.nil? || entry.url.blank?

    entry_date, entry_title, feed_title, tt = feed_item_content_for_html(entry)
    html = '<li>'
    html << link_to(entry_title.html_safe, entry.url, 'data-tooltip' => tt, target: '_blank')
    html << "<br/><span class='subtle'>"
    html << feed_title
    html << " - #{time_ago_in_words(entry_date)} ago" unless entry_date.nil?
    html << '</span>'
    html << '</li>'
    html.html_safe

  end

  def determine_entry_date(entry)
    entry_date = entry.try(:published) if entry.respond_to?(:published)
    entry_date ||= entry.try(:updated) if entry.respond_to?(:updated)
    entry_date ||= entry.try(:last_modified) if entry.respond_to?(:last_modified)
    entry_date
  end

  def feed_item_content_for_html(entry)
    entry_title = entry.title || 'Unknown title'
    feed_title = entry.feed_title || 'Unknown publisher'
    entry_date = determine_entry_date(entry)
    entry_summary = truncate(strip_tags(entry.summary || entry.content), length: 500)
    tt = tooltip("<p>#{entry_summary}</p><p class='feedinfo none_text'>#{entry_date.strftime('%c') unless entry_date.nil?}</p>")
    [entry_date, entry_title, feed_title, tt]
  end

  def recently_downloaded_item_logs_hash(time = 1.month.ago, number_of_item = 10)
    Rails.cache.fetch("download_activity_#{current_user_id}") do
      activity_logs = ActivityLog.no_spider.where(['action = ? AND created_at > ?', 'download', time]).order('created_at DESC')
      selected_activity_logs = []
      activity_logs.each do |activity_log|
        included = selected_activity_logs.index { |log| log.activity_loggable == activity_log.activity_loggable }
        if !included && activity_log.activity_loggable && activity_log.activity_loggable.can_view?
          selected_activity_logs << activity_log
        end
        break if selected_activity_logs.length >= number_of_item
      end
      convert_logs_to_hash selected_activity_logs
    end
  end

  def recently_added_item_logs_hash(time = 1.month.ago, number_of_item = 10)
    Rails.cache.fetch("create_activity_#{current_user_id}") do
      item_types = Seek::Util.user_creatable_types.collect(&:name) | [Project, Programme].collect(&:name)
      activity_logs = ActivityLog.where(['action = ? AND created_at > ? AND activity_loggable_type in (?)', 'create', time, item_types]).order('created_at DESC')
      selected_activity_logs = []
      activity_logs.each do |log|
        if log.activity_loggable && item_types.include?(log.activity_loggable_type) && log.activity_loggable.can_view?
          selected_activity_logs << log
        end
        break if selected_activity_logs.length >= number_of_item
      end
      convert_logs_to_hash selected_activity_logs
    end
  end

  def convert_logs_to_hash(logs)
    logs.collect do |log|
      item = log.activity_loggable
      {
        type: text_for_resource(item),
        title: item.title,
        action: log.action,
        description: item.respond_to?(:description) ? item.description : nil,
        abstract: item.respond_to?(:abstract) ? item.abstract : nil,
        created_at: log.created_at,
        avatar_image: resource_avatar(item, class: 'home_asset_icon'),
        url: show_resource_path(item),
        log_id: log.id
      }
    end
  end

  def display_single_log_item_hash(item, action)
    html = ''
    html << construct_html_for_log_item(item, action) unless item.blank?
    html.html_safe
  end

  def construct_html_for_log_item(item, action)
    icon, tt = log_item_content_for_html(item)
    html = '<li>'
    html << "#{icon} "
    html << link_to(item[:title], item[:url], 'data-tooltip' => tt)
    html << "<br/><span class='subtle'>#{item[:type]} - #{action} #{time_ago_in_words(item[:created_at])} ago</span>"
    html << '</li>'
    html
  end

  def log_item_content_for_html(item)
    image = item[:avatar_image]
    icon = link_to(image, item[:url], class: 'file-type-icon', 'data-tooltip' => tooltip(item[:type]))
    description = item[:description] || item[:abstract]
    tt = tooltip("<p>#{description.blank? ? 'No description' : description}</p><p class='feedinfo none_text'>#{item[:created_at]}</p>")
    [icon, tt]
  end

  def guest_login_link(text)
    link_to(text, session_path(login: 'guest', password: 'guest'), method: :post)
  end

  def frontpage_button(link, image_path, &block)
    link_to link, class: 'seek-homepage-button', target: :_blank do
      image_tag(image_path) +
          content_tag(:span) do
            block.call
          end
    end
  end
end
