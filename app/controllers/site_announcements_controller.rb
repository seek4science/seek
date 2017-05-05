class SiteAnnouncementsController < ApplicationController
  include Seek::BreadCrumbs

  before_filter :login_required, except: %i[feed notification_settings update_notification_settings]

  before_filter :check_manage_announcements, only: %i[new create edit update destroy]

  def feed
    limit = params[:limit]
    limit ||= 10
    @site_announcements = SiteAnnouncement.feed_announcements limit: limit
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
        flash[:notice] = "Email announcement setting updated. You will now #{'not ' unless @info.receive_notifications?}receive notification emails."
        format.html { redirect_to(root_url) }
      else
        flash[:error] = 'Unable to update your settings'
        flash[:error] += ", the key presented wasn't recognised."
        format.html { render action: :notification_settings }
      end
    end
  end

  def destroy
    @site_announcement = SiteAnnouncement.find(params[:id])

    respond_to do |format|
      if @site_announcement.destroy
        flash[:notice] = 'Announcement destroyed'
        format.html { redirect_to site_announcements_path }
      else
        flash[:error] = 'There was a problem destroying the announcement'
        format.html { render action: :edit }
      end
    end
  end

  def notification_settings
    @info = NotifieeInfo.find_by_unique_key(params[:key])

    respond_to do |format|
      if @info.nil?
        flash[:error] = 'Invalid Key'
        format.html { redirect_to root_url }
      else
        format.html
      end
    end
  end

  def new
    @site_announcement = SiteAnnouncement.new
  end

  def create
    @site_announcement = SiteAnnouncement.new(site_announcement_params)
    @site_announcement.announcer = current_person

    respond_to do |format|
      if @site_announcement.save
        flash[:notice] = 'The Announcement was successfully announced.'
        format.html { redirect_to(@site_announcement) }
        format.xml  { render xml: @site_announcement, status: :created, location: @site_announcement }
      else
        format.html { render action: 'new' }
        format.xml  { render xml: @site_announcement.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @site_announcement = SiteAnnouncement.find(params[:id])
  end

  def update
    @site_announcement = SiteAnnouncement.find(params[:id])

    respond_to do |format|
      if @site_announcement.update_attributes(site_announcement_params)
        flash[:notice] = 'Announcement was successfully updated.'
        format.html { redirect_to(@site_announcement) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @site_announcement.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @site_announcement = SiteAnnouncement.find(params[:id])
  end

  def index
    @site_announcements = if params[:feed_only]
                            SiteAnnouncement.feed_announcements(limit: 1000)
                          else
                            SiteAnnouncement.order('created_at DESC')
                          end
  end

  def check_manage_announcements
    unless can_manage_announcements?
      flash[:error] = 'Admin rights required'
      redirect_to root_url
    end
  end

  private

  def site_announcement_params
    params.require(:site_announcement).permit(:title, :body, :show_in_feed, :is_headline,
                                              'expires_at(1i)', 'expires_at(2i)', 'expires_at(3i)',
                                              'expires_at(4i)', 'expires_at(5i)', :email_notification)
  end
end
