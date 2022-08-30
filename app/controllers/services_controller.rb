class ServicesController < ApplicationController
  include Seek::IndexPager
  include Seek::DestroyHandling
  include Seek::AssetsCommon

  before_action :login_required, except: [:show, :index]
  before_action :find_requested_item, only: [:show, :edit, :update, :destroy]
  before_action :find_assets

#  include Seek::IsaGraphExtensions

  respond_to :html, :json

  api_actions :index, :show, :create, :update, :destroy

  def create
    @service = Service.new
    @service.assign_attributes(service_params)
    update_annotations(params[:tag_list], @service)
    respond_to do |format|
      if @service.save
        flash[:notice] = "#{t('service')} was successfully created."
        format.html { redirect_to(@service) }
        format.json { render json: @service, include: [params[:include]] }
      else
        format.html { render action: 'new' }
        format.json { render json: json_api_errors(@service), status: :unprocessable_entity }
      end
    end
  end

  def update
    update_annotations(params[:tag_list], @service) if params.key?(:tag_list)
    respond_to do |format|
      if @service.update(service_params)
        flash[:notice] = "The #{t('service').capitalize} was successfully updated"
        format.html { redirect_to(@service) }
        format.json { render json: @service, include: [params[:include]] }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@service), status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_with(@service)
  end

  def new
    @service = Service.new
    respond_with(@service)
  end

  def filter
    scope = Service
    @facilities = scope.where('data_files.title LIKE ?', "%#{params[:filter]}%").distinct.authorized_for('view').first(20)

    respond_to do |format|
      format.html { render partial: 'facilities/association_preview', collection: @facilities, locals: { hide_sample_count: !params[:with_samples] } }
    end
  end

  def show
    respond_with do |format|
      format.html
      format.json {render json: @service, include: [params[:include]]}
    end
  end

  private

  def service_params
    params.require(:service).permit(:description, :title, :facility_id)
  end

end
