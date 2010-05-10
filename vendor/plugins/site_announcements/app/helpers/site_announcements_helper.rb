

module SiteAnnouncementsHelper
  
  def site_annoucements_headline
    headline = SiteAnnouncement.headline_announcement
    return "" unless headline #return empty string if there is no announcement
    return render :partial=>"site_announcements/headline_announcement",:object=>headline
  end

end
