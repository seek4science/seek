class EventsController < ApplicationController
  include Seek::PreviewHandling
  include Seek::DestroyHandling

  before_filter :find_and_authorize_requested_item, except: [:index, :new, :create, :preview]

  before_filter :find_assets

  before_filter :events_enabled?

  include IndexPager

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
    @event = Event.new params[:event]
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
    data_file_ids = params.delete(:data_file_ids) || []
    data_file_ids.map! { |text| id, rel = text.split(','); id }
    @event.data_files = DataFile.find(data_file_ids)

    publication_ids = params.delete(:related_publication_ids) || []
    @event.publications = Publication.find(publication_ids)

    @event.attributes = params[:event]

    if params[:sharing]
      @event.policy_or_default unless is_new
      @event.policy.set_attributes_with_sharing params[:sharing], @event.projects
    end

    respond_to do | format |
      if @event.save
        flash.now[:notice] = "#{t('event')} was updated successfully." if flash.now[:notice].nil?
        format.html { redirect_to @event }
      else
        format.html { render 'events/form' }
      end
    end
  end
end
