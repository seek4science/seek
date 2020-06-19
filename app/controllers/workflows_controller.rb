class WorkflowsController < ApplicationController
  
  include Seek::IndexPager

  include Seek::AssetsCommon

  # before_action Seek::Config.workflows_enabled
  before_action :find_assets, :only => [ :index ]
  before_action :find_and_authorize_requested_item, :except => [ :index, :new, :create, :preview, :test_asset_url, :update_annotations_ajax]
  before_action :find_display_asset, :only=>[:show, :download]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs
  include Seek::Doi::Minting

  include Seek::IsaGraphExtensions

  def new_version
    if handle_upload_data(true)
      comments=params[:revision_comments]


      respond_to do |format|
        if @workflow.save_as_new_version(comments)

          flash[:notice]="New version uploaded - now on version #{@workflow.version}"
        else
          flash[:error]="Unable to save new version"          
        end
        format.html {redirect_to @workflow }
      end
    else
      flash[:error]=flash.now[:error] 
      redirect_to @workflow
    end
    
  end

  # PUT /Workflows/1
  def update
    update_annotations(params[:tag_list], @workflow) if params.key?(:tag_list)
    update_sharing_policies @workflow
    update_relationships(@workflow,params)

    respond_to do |format|
      if @workflow.update_attributes(workflow_params)
        flash[:notice] = "#{t('Workflow')} metadata was successfully updated."
        format.html { redirect_to workflow_path(@workflow) }
        format.json { render json: @workflow, include: [params[:include]] }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@workflow), status: :unprocessable_entity }
      end
    end
  end

  private

  def workflow_params
    params.require(:workflow).permit(:title, :description, { project_ids: [] }, :license, :other_creators,
                                { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                { creator_ids: [] }, { assay_assets_attributes: [:assay_id] }, { scales: [] },
                                { publication_ids: [] })
  end

  alias_method :asset_params, :workflow_params

end
