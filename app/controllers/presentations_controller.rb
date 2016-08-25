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
    # remove protected columns (including a "link" to content blob - actual data cannot be updated!)
    if params[:presentation]
      [:contributor_id, :contributor_type, :original_filename, :content_type, :content_blob_id, :created_at, :updated_at, :last_used_at].each do |column_name|
        params[:presentation].delete(column_name)
      end

      # update 'last_used_at' timestamp on the Presentation
      params[:presentation][:last_used_at] = Time.now
    end

    update_annotations(params[:tag_list], @presentation)
    update_scales @presentation

    @presentation.attributes = params[:presentation]

    update_sharing_policies @presentation,params

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


end
