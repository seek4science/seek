#require "flash_tool"
class PresentationsController < ApplicationController

  include Seek::IndexPager

  include Seek::AssetsCommon

  before_action :find_assets, :only => [ :index ]
  before_action :find_and_authorize_requested_item, :except => [ :index, :new, :create, :preview,:update_annotations_ajax]
  before_action :find_display_asset, :only=>[:show, :download]

  include Seek::Publishing::PublishingCommon

  include Seek::IsaGraphExtensions

  api_actions :index, :show, :create, :update, :destroy

  def create_version
    if handle_upload_data(true)
      comments=params[:revision_comments]

      respond_to do |format|
        if @presentation.save_as_new_version(comments)
          flash[:notice]="New version uploaded - now on version #{@presentation.version}"
        else
          flash[:error]="Unable to save new version"
        end
        format.html {redirect_to @presentation }
      end
    else
      flash[:error]=flash.now[:error]
      redirect_to @presentation
    end

  end

 # PUT /presentations/1
  # PUT /presentations/1.xml
  def update
    @presentation.update_attributes(presentation_params)
    update_annotations(params[:tag_list], @presentation) if params.key?(:tag_list)
    update_sharing_policies @presentation
    update_relationships(@presentation,params)

    respond_to do |format|
      if @presentation.save
        # Update new assay_asset
        assay_ids = params[:assay_ids] || []
        Assay.find(assay_ids).each do |assay|
          if assay.can_edit?
            assay.relate(@presentation)
          end
        end
        #Destroy AssayAssets that aren't needed
        assay_assets = @presentation.assay_assets
        assay_assets.each do |assay_asset|
          if assay_asset.assay.can_edit? and !assay_ids.include?(assay_asset.assay_id.to_s)
            AssayAsset.destroy(assay_asset.id)
          end
        end
        flash[:notice] = "#{t('presentation')} metadata was successfully updated."
        format.html { redirect_to presentation_path(@presentation) }
        format.json { render json: @presentation, include: [params[:include]] }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@presentation), status: :unprocessable_entity }
      end
    end
  end

  private

  def presentation_params
    params.require(:presentation).permit(:title, :description, *creator_related_params, :license, :parent_name,
                                         { event_ids: [] }, { project_ids: [] },
                                         { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                         { publication_ids: [] }, { workflow_ids: [] },
                                         discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

  alias_method :asset_params, :presentation_params

end
