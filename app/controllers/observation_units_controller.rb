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

end
