class EventsController < ApplicationController
  include Seek::PreviewHandling
  include Seek::AssetsCommon

  before_action :find_and_authorize_requested_item, except: [:index, :new, :create, :preview]

  before_action :find_assets

  before_action :events_enabled?

  include Seek::IndexPager

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml
      format.json {render json: @event}
    end
  end

  def create
    @event = Event.new(event_params)
    handle_update_or_create(true)
  end

  def update
    @new = false
    handle_update_or_create(false)
  end

  def handle_update_or_create(is_new)

    re_render_view = is_new ? 'events/new' : 'events/edit'

    update_sharing_policies @event

    respond_to do | format |
      if @event.update(event_params) && @event.save
        flash.now[:notice] = "#{t('event')} was updated successfully." if flash.now[:notice].nil?
        format.html { redirect_to @event }
        format.json { render json: @event }
      else
        format.html { render re_render_view }
        format.json { render json: json_api_errors(@assay), status: :unprocessable_entity }
      end
    end
  end

  private

  def event_params
    params.require(:event).permit(:title, :description, :start_date, :end_date, :url, :address, :city, :country,
                                  { project_ids: [] }, { publication_ids: [] }, { presentation_ids: [] },
                                  { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                  { data_file_ids: [] },{document_ids: []}, { publication_ids: [] })
  end

  def param_converter_options
    { skip: [:data_file_ids] }
  end

end
