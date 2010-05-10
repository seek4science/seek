class SiteAnnouncementsController < ApplicationController
  before_filter :login_required

  before_filter :check_manage_announcements,:only=>[:new,:create,:edit,:update]

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

  def edit
    @site_announcement=SiteAnnouncement.find(params[:id])
  end

  def update
    @site_announcement=SiteAnnouncement.find(params[:id])

    respond_to do |format|
      if @site_announcement.update_attributes(params[:site_announcement])
        flash[:notice] = 'Study was successfully updated.'
        format.html { redirect_to(@site_announcement) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
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

  def check_manage_announcements    
    if !can_manage_announcements?
      flash[:error] = notice
      redirect_to root_url
    end
  end
end
