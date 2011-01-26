class EventsController < ApplicationController
  before_filter :login_required
  before_filter :find_event_auth, :except =>  [ :index, :new, :create, :request_resource, :preview, :test_asset_url]

  
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
        format.html
      else
        flash[:error] = "You are not authorized to create new Events. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html { redirect_to events_path}
      end
    end
  end

  def create
    @event = Event.new params[:event]
    @event.contributor=current_user

    respond_to do | format |
      if @event.save
        flash.now[:notice] = 'Event was successfully saved.'
        format.html { redirect_to @event}
      else
        @new = true
        format.html {render :action => "new"}
      end
    end
  end

  def find_event_auth
    @event = Event.find(params[:id])
  end

  def edit
    @new = false
    render "new"
  end

  def update
    if @event.update_attributes params[:event]
      respond_to do | format |
        flash[:notice] = "The Event was updated successfully."
        format.html {redirect_to @event}
      end
    else
      @new = false
      render "new"
    end
  end

end
