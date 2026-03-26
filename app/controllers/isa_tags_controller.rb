class ISATagsController < ApplicationController
  include Seek::IndexPager
  respond_to :json
  api_actions :show, :index
  before_action :ensure_json_request
  before_action :ensure_isa_json_compliance_enabled?
  before_action :ensure_logged_in

  def index
    respond_to do |format|
      format.json {
        render json: ISATag.all.sort,
               each_serializer: ISATagSkeletonSerializer,
               meta: {
                 base_url: Seek::Config.site_base_host,
                 api_version: ActiveModel::Serializer.config.api_version
               },
               links: json_api_links
      }
    end
  end

  def show
    respond_to do |format|
      format.json {
        render json: ISATag.find(params[:id]),
               serializer: ISATagSkeletonSerializer,
               meta: {
                 base_url: Seek::Config.site_base_host,
                 api_version: ActiveModel::Serializer.config.api_version
               },
               links: json_api_links
      }
    end
  end

  def isa_tag_options_for_attributes
    level = params[:level]
    allowed_isa_tags = ISATag.allowed_isa_tags_for_level(level)
    isa_tags_options = allowed_isa_tags.map { |it| { text: it.title, value: it.id } }

    render json: { result: isa_tags_options }
  end

  private

  def ensure_json_request
    # Accept header or URL format must request JSON
    return if request.format.json?

    render json: {
      errors: [
        {
          title: "Not Acceptable",
          detail: "This endpoint only serves application/json."
        }
      ]
    }, status: :not_acceptable # 406
  end

  def ensure_isa_json_compliance_enabled?
    return if Seek::Config.isa_json_compliance_enabled

    render json: {
      errors:[
        {
          title: "Not Available",
          detail: "ISA-JSON compliance is disabled. Endpoint not available."
        }
      ]
    }, status: :forbidden
  end

  def ensure_logged_in
    return if logged_in?

    render json: {
      errors: [
        {
          title: "Not Authenticated",
          detail: "Please log in."
        }
      ]
    }, status: :unauthorized
  end
end
