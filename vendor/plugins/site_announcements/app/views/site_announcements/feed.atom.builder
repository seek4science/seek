atom_feed do |feed|
  feed.title("SEEK Announcements")
  feed.updated(@site_announcements.first.updated_at)

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