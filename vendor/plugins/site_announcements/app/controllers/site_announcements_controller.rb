class SiteAnnouncementsController < ApplicationController
  before_filter :login_required, :except=>[:feed,:notification_settings,:update_notification_settings]
  
  before_filter :check_manage_announcements,:only=>[:new,:create,:edit,:update,:destroy]
  
  def feed
    limit=params[:limit]
    limit||=10
    @site_announcements=SiteAnnouncement.feed_announcements :limit=>limit
    respond_to do |format|
      format.atom
    end
  end
  
  def update_notification_settings
    receive_notifications = params[:receive_notifications]
    receive_notifications ||= false
    @info = NotifieeInfo.find_by_unique_key(params[:key])
    @info.receive_notifications = receive_notifications unless @info.nil?
    respond_to do |format|
      if @info && @info.save
        flash[:notice]="Email announcement setting updated. You will now #{"not " if !@info.receive_notifications?}receive notification emails."
        format.html { redirect_to(root_url) }
      else
        flash[:error]="Unable to update your settings"
        flash[:error]+=", the key presented wasn't recognised."
        format.html { render :action => :notification_settings}
      end
    end
  end
  
  def destroy 
    @site_announcement=SiteAnnouncement.find(params[:id])
    
    respond_to do |format|
      if @site_announcement.destroy
        flash[:notice]="Announcement destroyed"
        format.html {redirect_to site_announcements_path}
      else        
        flash[:error]="There was a problem destroying the announcement"        
        format.html { render :action=>:edit }
      end
    end
  end
  
  def notification_settings
    key=params[:key]
    error=false
    @info=NotifieeInfo.find_by_unique_key(key) 
    error=true if !@info.nil?
    
    respond_to do |format|
      if error 
        format.html
      else
        flash[:error]="Invalid Key"
        redirect_to root_url
      end
      
    end
  end
  
  def new
    @site_announcement=SiteAnnouncement.new
  end
  
  def create
    @site_announcement=SiteAnnouncement.new(params[:site_announcement])
    @site_announcement.announcer = currently_logged_in
    
    if (@site_announcement.email_notification?)
      send_announcement_emails(@site_announcement)
    end
    
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
  
  def send_announcement_emails site_announcement
    if email_enabled?
      NotifieeInfo.find(:all,:conditions=>["receive_notifications=?",true]).each do |notifiee_info|
        Mailer.deliver_announcement_notification(site_announcement, notifiee_info,base_host)                     
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
    @site_announcements=SiteAnnouncement.find(:all,:order=>"created_at DESC")
  end
  
  def check_manage_announcements    
    if !can_manage_announcements?
      flash[:error] = "Admin rights required"
      redirect_to root_url
    end
  end
   
end
