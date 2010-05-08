class SiteAnnouncementsController < ApplicationController
  before_filter :login_required

  #this must be implemented in your ApplicationController and determines if the current user can create or edit announcements
  before_filter :can_create_announcements,:only=>[:new,:create,:edit,:update]

  def new
    @site_announcement=SiteAnnouncement.new
  end

end
