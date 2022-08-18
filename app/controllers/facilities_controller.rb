class FacilitiesController < ApplicationController
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
    @facility = Facility.new
    @facility.assign_attributes(facility_params)
    respond_to do |format|
      if @facility.save
        flash[:notice] = "#{t('facility')} was successfully created."
        format.html { redirect_to(@facility) }
        format.json { render json: @facility, include: [params[:include]] }
      else
        format.html { render action: 'new' }
        format.json { render json: json_api_errors(@facility), status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @facility.update(facility_params)
        flash[:notice] = "The #{t('facility').capitalize} was successfully updated"
        format.html { redirect_to(@facility) }
        format.json { render json: @facility, include: [params[:include]] }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@facility), status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_with(@facility)
  end

  def new
    @facility = Facility.new
    respond_with(@facility)
  end

  def filter
    scope = Facility
    @facilities = scope.where('data_files.title LIKE ?', "%#{params[:filter]}%").distinct.authorized_for('view').first(20)

    respond_to do |format|
      format.html { render partial: 'facilities/association_preview', collection: @facilities, locals: { hide_sample_count: !params[:with_samples] } }
    end
  end

  def show
    respond_with do |format|
      format.html
      format.json {render json: @facility, include: [params[:include]]}
    end
  end

  private

  def facility_params
    params.require(:facility).permit(:description, :title, :web_page, :address, :city, :country, { institution_ids: [] })
  end

end
