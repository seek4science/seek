atom_feed(:url => site_announcements_url(:format => :atom),
          :root_url => site_announcements_url,
          :schema_date => "2009") do |feed|

  feed.title("SEEK Announcements")
  if @site_announcements.empty?
    feed.updated Time.now
  else
    feed.updated @site_announcements.first.updated_at
  end

  for announcement in @site_announcements
    next if announcement.updated_at.blank?
    feed.entry(announcement) do |entry|
      entry.title(announcement.title)
      entry.content(announcement.body_html, :type =>'html')      
      entry.author do |author|
        author.name(announcement.announcer.name)        
      end
    end
  end
end