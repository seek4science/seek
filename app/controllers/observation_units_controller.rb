class ObservationUnitsController < ApplicationController

  include Seek::DestroyHandling
  include Seek::IndexPager
  include Seek::AssetsCommon

  before_action :organisms_enabled?
  before_action :find_and_authorize_requested_item, :except => [ :index, :new, :create, :preview,:update_annotations_ajax]
  before_action :login_required,:except=>[:show,:index]
  before_action :find_assets, only: [:index]

  #api_actions :index, :show

  def show
    respond_to do |format|
      format.html
      format.rdf { render :template=>'rdf/show'}
      format.json {render json: @observation_unit, include: [params[:include]]}
    end
  end

  def update
    update_annotations(params[:tag_list], @observation_unit) if params.key?(:tag_list)
    update_sharing_policies @observation_unit
    update_relationships(@observation_unit,params)

    respond_to do |format|
      if @observation_unit.update(observation_unit_params)
        flash[:notice] = "#{t('document')} metadata was successfully updated."
        format.html { redirect_to observation_unit_path(@observation_unit) }
        format.json { render json: @observation_unit, include: [params[:include]] }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@observation_unit), status: :unprocessable_entity }
      end
    end
  end

  def observation_unit_params
    params.require(:observation_unit).permit(:title, :description, *creator_related_params, { project_ids: [] },
                                         { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                         { extended_metadata_attributes: determine_extended_metadata_keys })
  end
end
