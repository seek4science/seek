#require "flash_tool"
class PresentationsController < ApplicationController

  include Seek::IndexPager

  include Seek::AssetsCommon

  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_authorize_requested_item, :except => [ :index, :new, :create, :preview,:update_annotations_ajax]
  before_filter :find_display_asset, :only=>[:show, :download]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  include Seek::IsaGraphExtensions

  def new_version
    if handle_upload_data
      comments=params[:revision_comment]

      respond_to do |format|
        if @presentation.save_as_new_version(comments)
          create_content_blobs
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
    update_annotations(params[:tag_list], @presentation)
    update_scales @presentation

    @presentation.attributes = presentation_params

    update_sharing_policies @presentation

    assay_ids = params[:assay_ids] || []
    respond_to do |format|
      if @presentation.save

        update_relationships(@presentation,params)

        flash[:notice] = "#{t('presentation')} metadata was successfully updated."
        format.html { redirect_to presentation_path(@presentation) }
        # Update new assay_asset
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
      else
        format.html {
          render :action => "edit"
        }
      end
    end
  end

  private

  def presentation_params
    params.require(:presentation).permit(:title, :description, :other_creators, :license, :parent_name,
                                         { event_ids: [] }, { project_ids: [] },
                                         { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] })
  end

  alias_method :asset_params, :presentation_params

end
