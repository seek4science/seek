class SampleAttributeTypesController < ApplicationController

  include Seek::IndexPager

  respond_to :json

  api_actions :index, :show

  def index
    respond_to do |format|
      format.json {
        render json: SampleAttributeType.all,
               each_serializer: SampleAttributeTypeSkeletonSerializer,
               links: json_api_links,
               meta: {
                 base_url: Seek::Config.site_base_host,
                 api_version: ActiveModel::Serializer.config.api_version
               }
      }
    end
  end

  def show
    respond_to do |format|
      format.json {render json: SampleAttributeType.find(params["id"])}
    end
  end
end
