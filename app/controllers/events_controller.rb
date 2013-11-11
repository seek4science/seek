class EventsController < ApplicationController
  #before_filter :login_required
  before_filter :find_and_auth, :except =>  [ :index, :new, :create, :preview]

  before_filter :find_assets

  before_filter :check_events_enabled

  include IndexPager

  include Seek::Publishing::GatekeeperPublish
  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs
  
  def show
    
  end

  #DELETE /events/1
  #DELETE /events/1.xml
  def destroy
    @event.destroy
    respond_to do | format |
      format.html { redirect_to events_path }
      format.xml { head :ok }
    end
  end

  def new
    @event = Event.new
    @new = true
    respond_to do |format|
      if current_user.person.member?
        format.html {render "events/form"}
      else
        flash[:error] = "You are not authorized to create new Events. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html { redirect_to events_path}
      end
    end
  end

  def create
    @event = Event.new params[:event]

    data_file_ids = params.delete(:data_file_ids) || []
    data_file_ids.collect! {|text| id, rel = text.split(','); id}
    @event.data_files = DataFile.find(data_file_ids)

    publication_ids = params.delete(:related_publication_ids) || []
    @event.publications = Publication.find(publication_ids)

    @event.policy.set_attributes_with_sharing params[:sharing], @event.projects

    respond_to do | format |
      if @event.save
        flash.now[:notice] = "#{t('event')} was successfully saved." if flash.now[:notice].nil?
        format.html { redirect_to @event }
      else
        @new = true
        format.html {render "events/form"}
      end
    end
  end

  def edit
    @new = false
    render "events/form"
  end

  def update
    data_file_ids = params.delete(:data_file_ids) || []
    data_file_ids.collect! {|text| id, rel = text.split(','); id}
    @event.data_files = DataFile.find(data_file_ids)

    publication_ids = params.delete(:related_publication_ids) || []
    @event.publications = Publication.find(publication_ids)

    @event.attributes = params[:event]

    if params[:sharing]
      @event.policy_or_default
      @event.policy.set_attributes_with_sharing params[:sharing], @event.projects
    end

    respond_to do | format |
      if @event.save
        flash.now[:notice] = "#{t('event')} was updated successfully." if flash.now[:notice].nil?
        format.html { redirect_to @event }
      else
        @new = false
        format.html {render "events/form"}
      end
    end
  end

    def preview
    element=params[:element]
    event=Event.find_by_id(params[:id])

    render :update do |page|
      if event.try :can_view?
        page.replace_html element,:partial=>"events/resource_list_item_preview",:locals=>{:resource=>event}
      else
        page.replace_html element,:text=>"Nothing is selected to preview."
      end
    end
    end
  
  private

  #filter to check if events are enabled using the EVENTS_ENABLED configuration flag
  def check_events_enabled
    if !Seek::Config.events_enabled
      respond_to do |format|
        flash[:error]="#{t('event').pluralize} are currently disabled"
        format.html { redirect_to root_path }
      end
      return false
    end
    true
  end

end
