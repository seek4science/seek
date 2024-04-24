class ObservationUnitsController < ApplicationController

  include Seek::DestroyHandling

  before_action :organisms_enabled?
  before_action :find_requested_item, :only=>[:show,:edit,:destroy, :update]
  before_action :login_required,:except=>[:show,:index]

  include Seek::IndexPager

  api_actions :index, :show

  def show
    respond_to do |format|
      format.html
      format.rdf { render :template=>'rdf/show'}
      format.json {render json: @observation_unit, include: [params[:include]]}
    end
  end

end
