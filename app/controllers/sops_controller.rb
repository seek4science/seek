class SopsController < ApplicationController
  
  include Seek::IndexPager

  include Seek::AssetsCommon

  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_authorize_requested_item, :except => [ :index, :new, :create, :request_resource,:preview, :test_asset_url, :update_annotations_ajax]
  before_filter :find_display_asset, :only=>[:show, :download]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs
  include Seek::DataciteDoi

  include Seek::IsaGraphExtensions

  def new_version
    if handle_upload_data
      comments=params[:revision_comment]


      respond_to do |format|
        if @sop.save_as_new_version(comments)

          create_content_blobs

          #Duplicate experimental conditions
          conditions = @sop.find_version(@sop.version - 1).experimental_conditions
          conditions.each do |con|
            new_con = con.dup
            new_con.sop_version = @sop.version
            new_con.save
          end
          flash[:notice]="New version uploaded - now on version #{@sop.version}"
        else
          flash[:error]="Unable to save new version"          
        end
        format.html {redirect_to @sop }
      end
    else
      flash[:error]=flash.now[:error] 
      redirect_to @sop
    end
    
  end

  # PUT /sops/1
  def update
    update_annotations(params[:tag_list], @sop)
    update_scales @sop

    @sop.attributes = sop_params

    update_sharing_policies @sop

    respond_to do |format|
      if @sop.save
        update_relationships(@sop,params)
        update_assay_assets(@sop,params[:assay_ids])
        flash[:notice] = "#{t('sop')} metadata was successfully updated."
        format.html { redirect_to sop_path(@sop) }

      else
        format.html { 
          render :action => "edit" 
        }
      end
    end
  end

  private

  def sop_params
    params.require(:sop).permit(:title, :description, { project_ids: [] }, :license, :other_creators,
                                { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] })
  end

  alias_method :asset_params, :sop_params

end
