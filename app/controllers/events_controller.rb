class EventsController < ApplicationController
  before_filter :login_required
  before_filter :find_and_auth, :except =>  [ :index, :new, :create, :preview]

  before_filter :find_assets

  before_filter :check_events_enabled

  include IndexPager
  
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
      if Authorization.is_member?(current_user.person_id, nil, nil)
        format.html {render "events/form"}
      else
        flash[:error] = "You are not authorized to create new Events. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html { redirect_to events_path}
      end
    end
  end

  def create
    @event = Event.new params[:event]
    @event.contributor=current_user
    data_file_ids = params[:data_file_ids] || []
    data_file_ids.each do |text|
      a_id, r_type = text.split(",")
      @event.data_files << DataFile.find(a_id)
    end
    params.delete :data_file_ids

    publication_ids = params[:related_publication_ids] || []
    publication_ids.each do |id|
      @event.publications << Publication.find(id)
    end
    params.delete :related_publication_ids

    respond_to do | format |
      if @event.save
        policy_err_msg = Policy.create_or_update_policy(@event, current_user, params)

        if policy_err_msg.blank?
          flash.now[:notice] = 'Event was successfully saved.' if flash.now[:notice].nil?
          format.html { redirect_to @event }
        else
          flash[:notice] = "Event was successfully created. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
          format.html { redirect_to event_edit_path(@event)}
        end
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
    data_file_ids = params[:data_file_ids] || []
    @event.data_files = []
    data_file_ids.each do |text|
      a_id, r_type = text.split(",")
      @event.data_files << DataFile.find(a_id)
    end
    params.delete :data_file_ids

    publication_ids = params[:related_publication_ids] || []
    @event.publications = []
    publication_ids.each do |id|
      @event.publications << Publication.find(id)
    end
    params.delete :related_publication_ids

    respond_to do | format |
      if @event.update_attributes params[:event]
        policy_err_msg = Policy.create_or_update_policy(@event, current_user, params)
 
        if policy_err_msg.blank?
          flash.now[:notice] = 'Event was updated successfully.' if flash.now[:notice].nil?
          format.html { redirect_to @event }
        else
          flash[:notice] = "Event metadata was successfully updated. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
          format.html { redirect_to event_edit_path(@event)}
        end
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
      if event && Authorization.is_authorized?("show", nil, event, current_user)
        page.replace_html element,:partial=>"events/resource_list_item",:locals=>{:resource=>event}
      else
        page.replace_html element,:text=>"Nothing is selected to preview."
      end
    end
    end
  
  private

  #filter to check if events are enabled using the EVENTS_ENABLED configuration flag
  def check_events_enabled
    if !Seek::ApplicationConfiguration.events_enabled
      respond_to do |format|
        flash[:error]="Events are currently disabled"
        format.html { redirect_to root_path }
      end
      return false
    end
    true
  end

end
