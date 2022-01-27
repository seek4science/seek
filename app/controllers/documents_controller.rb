class DocumentsController < ApplicationController

  include Seek::IndexPager

  include Seek::AssetsCommon

  before_action :documents_enabled?
  before_action :find_assets, :only => [ :index ]
  before_action :find_and_authorize_requested_item, :except => [ :index, :new, :create,:preview, :update_annotations_ajax]
  before_action :find_display_asset, :only=>[:show, :download]

  include Seek::Publishing::PublishingCommon

  include Seek::Doi::Minting

  include Seek::IsaGraphExtensions

  api_actions :index, :show, :create, :update, :destroy

  def create_version
    if handle_upload_data(true)
      comments = params[:revision_comments]

      respond_to do |format|
        if @document.save_as_new_version(comments)
          flash[:notice] = "New version uploaded - now on version #{@document.version}"
        else
          flash[:error] = "Unable to save new version"
        end

        format.html { redirect_to @document }
      end
    else
      flash[:error] = flash.now[:error]
      redirect_to @document
    end
  end

  # PUT /documents/1
  def update
    update_annotations(params[:tag_list], @document) if params.key?(:tag_list)
    update_sharing_policies @document
    update_relationships(@document,params)

    respond_to do |format|
      if @document.update_attributes(document_params)
        flash[:notice] = "#{t('document')} metadata was successfully updated."
        format.html { redirect_to document_path(@document) }
        format.json { render json: @document, include: [params[:include]] }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@document), status: :unprocessable_entity }
      end
    end
  end

  private

  def document_params
    params.require(:document).permit(:title, :description, { project_ids: [] }, :license, *creator_related_params,
                                { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                { assay_assets_attributes: [:assay_id] }, { scales: [] },
                                { publication_ids: [] }, { event_ids: [] }, { workflow_ids: [] },
                                discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

  alias_method :asset_params, :document_params
end
