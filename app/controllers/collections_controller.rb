class CollectionsController < ApplicationController
  include Seek::IndexPager
  include Seek::AssetsCommon

  before_action :collections_enabled?
  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item, except: [:index, :new, :create, :preview, :update_annotations_ajax]

  include Seek::Publishing::PublishingCommon

  include Seek::IsaGraphExtensions

  api_actions :index, :show, :create, :update, :destroy

  def show
    respond_to do |format|
      format.html
      format.rdf { render template: 'rdf/show' }
      format.json { render json: @collection, include: json_api_include_param }
    end
  end

  def create
    item = initialize_asset
    create_asset_and_respond(item)
  end

  def update
    update_annotations(params[:tag_list], @collection) if params.key?(:tag_list)
    update_sharing_policies @collection
    update_relationships(@collection, params)

    respond_to do |format|
      if @collection.update(collection_params)
        flash[:notice] = "#{t('collection')} metadata was successfully updated."
        format.html { redirect_to collection_path(@collection) }
        format.json { render json: @collection, include: json_api_include_param }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@collection), status: :unprocessable_entity }
      end
    end
  end

  def collection_params
    params.require(:collection).permit(:title, :description, { project_ids: [] }, :license, *creator_related_params,
                                       { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                       { publication_ids: [] },
                                       { extended_metadata_attributes: determine_extended_metadata_keys },
                                       { items_attributes: [:id, :asset_type, :asset_id, :order, :comment, :_destroy]})
  end

  alias_method :asset_params, :collection_params

  def json_api_include_param
    [params[:include] || 'items']
  end
end
