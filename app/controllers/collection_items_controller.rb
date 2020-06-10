class CollectionItemsController < ApplicationController
  before_action :collections_enabled?
  before_action :find_and_authorize_collection
  before_action :find_collection_item, except: [:index, :create]

  api_actions :index, :show, :create, :update, :destroy

  def index
    @items = @collection.items

    respond_to do |format|
      format.json do
        render json: @items, include: [params[:include]],
               each_serializer: CollectionItemSerializer,
               links: { self: collection_items_path(@collection) },
               meta: {
                   base_url: Seek::Config.site_base_host,
                   api_version: ActiveModel::Serializer.config.api_version
               }
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @item, include: [params[:include]] }
    end
  end

  def create
    @item = @collection.items.build(item_params)

    respond_to do |format|
      if @item.save
        format.html do
          flash[:notice] = "#{@item.asset.title} added to collection"
          redirect_to @collection
        end
        format.json { render json: @item, include: [params[:include]] }
      else
        format.json { render json: json_api_errors(@item), status: :unprocessable_entity }
      end
    end
  end

  # PUT /collections/1
  def destroy
    respond_to do |format|
      if @item.destroy
        format.json { head :ok }
      else
        format.json { render json: json_api_errors(@item), status: :unprocessable_entity }
      end
    end
  end

  def update
    @item = @collection.items.find_by_id(params[:id])

    respond_to do |format|
      if @item.update_attributes(item_params)
        format.json { render json: @item, include: [params[:include]] }
      else
        format.json { render json: json_api_errors(@item), status: :unprocessable_entity }
      end
    end
  end

  private

  def item_params
    params.require(:collection_item).permit(:asset_type, :asset_id, :comment, :order)
  end

  def find_and_authorize_collection
    @collection = Collection.find(params[:collection_id])
    @parent_resource = @collection
    privilege = Seek::Permissions::Translator.translate(action_name)

    return if privilege.nil?

    unless is_auth?(@collection, privilege)
      respond_to do |format|
        flash[:error] = 'You are not authorized to perform this action'
        format.html { redirect_to @collection }
        format.json do
          render json: { "title": 'Forbidden',
                         "detail": "You are not authorized to perform this action." },
                 status: :forbidden
        end
      end
    end
  end

  def find_collection_item
    @item = @collection.items.find(params[:id])
  end
end
