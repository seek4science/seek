class EventsController < ApplicationController
  include Seek::PreviewHandling
  include Seek::AssetsStandardControllerActions

  before_filter :find_and_authorize_requested_item, except: [:index, :new, :create, :preview]

  before_filter :find_assets

  before_filter :events_enabled?

  include Seek::IndexPager

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  def show
  end

  def new
    @event = Event.new
    @new = true
    respond_to do |format|
      if User.logged_in_and_member?
        format.html { render 'events/form' }
      else
        flash[:error] = 'You are not authorized to create new Events. Only members of known projects, institutions or work groups are allowed to create new content.'
        format.html { redirect_to events_path }
      end
    end
  end

  def create
    @event = Event.new(event_params)
    handle_update_or_create(true)
  end

  def edit
    @new = false
    render 'events/form'
  end

  def update
    @new = false
    handle_update_or_create(false)
  end

  def handle_update_or_create(is_new)
    @new = is_new
    data_files = params.delete(:data_files) || []
    data_files.map! { |d| d['id'] }
    @event.data_files = DataFile.find(data_files)

    publication_ids = params.delete(:related_publication_ids) || []
    @event.publications = Publication.find(publication_ids)

    @event.attributes = event_params

    update_sharing_policies @event

    respond_to do | format |
      if @event.save
        flash.now[:notice] = "#{t('event')} was updated successfully." if flash.now[:notice].nil?
        format.html { redirect_to @event }
      else
        format.html { render 'events/form' }
      end
    end
  end

  private

  def event_params
    params.require(:event).permit(:title, :description, :start_date, :end_date, :url, :address, :city, :country,
                                  { project_ids: [] }, { publication_ids: [] }, { presentation_ids: [] },
                                  { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] })
  end

end
