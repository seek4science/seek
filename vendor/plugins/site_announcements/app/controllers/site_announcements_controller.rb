class SiteAnnouncementsController < ApplicationController
  before_filter :login_required

  #this must be implemented in your ApplicationController and determines if the current user can create or edit announcements
  before_filter :can_create_announcements,:only=>[:new,:create,:edit,:update]

  def new
    @site_announcement=SiteAnnouncement.new
  end

  def create
    @site_announcement=SiteAnnouncement.new(params[:site_announcement])
    respond_to do |format|
    if @site_announcement.save
        flash[:notice] = 'The Announcement was successfully announced.'
        format.html { redirect_to(@site_announcement) }
        format.xml  { render :xml => @site_announcement, :status => :created, :location => @site_announcement }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @site_announcement.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @site_announcement=SiteAnnouncement.find(params[:id])
  end

  def index
    @site_announcements=SiteAnnouncement.find(:all)
  end

end
