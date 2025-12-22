class ISATagsController < ApplicationController
  respond_to :json
  api_actions :show, :index
  before_action :ensure_json_request
  before_action :isa_json_compliance_enabled?
  before_action :login_required

  def index
    respond_to do |format|
      format.json {
        render json: ISATag.all,
               each_serializer: ISATagSkeletonSerializer,
               meta: {
                 base_url: Seek::Config.site_base_host,
                 api_version: ActiveModel::Serializer.config.api_version
               }
      }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: ISATag.find(params[:id]) }
    end
  end


  private

  def ensure_json_request
    # Accept header or URL format must request JSON
    return if request.format.json?

    render json: {
      error: "Not Acceptable",
      message: "This endpoint only serves application/json."
    }, status: :not_acceptable # 406
  end
end
