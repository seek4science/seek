class CollectionsController < ApplicationController

  include Seek::IndexPager

  include Seek::AssetsCommon

  before_action :collections_enabled?
  before_action :find_assets, :only => [ :index ]
  before_action :find_and_authorize_requested_item, :except => [ :index, :new, :create, :request_resource,:preview, :test_asset_url, :update_annotations_ajax]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs
  include Seek::Doi::Minting

  include Seek::IsaGraphExtensions

  api_actions :index, :show, :create, :update, :destroy

  def show
    respond_to do |format|
      format.html
      format.rdf { render template: 'rdf/show' }
      format.json { render json: asset, scope: { requested_version: params[:version] }, include: [params[:include]] }
    end
  end


  def create
    item = initialize_asset
    create_asset_and_respond(item)
  end

  # PUT /collections/1
  def update
    update_annotations(params[:tag_list], @collection) if params.key?(:tag_list)
    update_sharing_policies @collection
    update_relationships(@collection,params)

    respond_to do |format|
      if @collection.update_attributes(collection_params)
        flash[:notice] = "#{t('collection')} metadata was successfully updated."
        format.html { redirect_to collection_path(@collection) }
        format.json { render json: @collection, include: [params[:include]] }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@collection), status: :unprocessable_entity }
      end
    end
  end

  def collection_params
    params.require(:collection).permit(:title, :description, { project_ids: [] }, :license, :other_creators,
                                       { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                       { creator_ids: [] }, { scales: [] }, { publication_ids: [] })
  end

  alias_method :asset_params, :collection_params
end
