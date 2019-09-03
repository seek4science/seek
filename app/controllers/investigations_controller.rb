class InvestigationsController < ApplicationController

  include Seek::IndexPager
  include Seek::DestroyHandling
  include Seek::AssetsCommon

  before_action :find_assets, :only=>[:index]
  before_action :find_and_authorize_requested_item,:only=>[:edit, :manage, :update, :manage_update, :destroy, :show,:new_object_based_on_existing_one]

  #project_membership_required_appended is an alias to project_membership_required, but is necesary to include the actions
  #defined in the application controller
  before_action :project_membership_required_appended, :only=>[:new_object_based_on_existing_one]

  include Seek::Publishing::PublishingCommon

  include Seek::AnnotationCommon

  include Seek::BreadCrumbs

  include Seek::IsaGraphExtensions

  def new_object_based_on_existing_one
    @existing_investigation =  Investigation.find(params[:id])
    if @existing_investigation.can_view?
      @investigation = @existing_investigation.clone_with_associations
      render :action=>"new"
    else
      flash[:error]="You do not have the necessary permissions to copy this #{t('investigation')}"
      redirect_to @existing_investigation
    end

  end

  def show
    @investigation=Investigation.find(params[:id])
    @investigation.create_from_asset = params[:create_from_asset]

    respond_to do |format|
      format.html
      format.xml
      format.rdf { render :template=>'rdf/show' }
      format.json {render json: @investigation}

      format.ro do
        ro_for_download
      end

    end
  end

  def ro_for_download
    ro_file = Seek::ResearchObjects::Generator.new(@investigation).generate
    send_file(ro_file.path,
              type:Mime::Type.lookup_by_extension("ro").to_s,
              filename: @investigation.research_object_filename)
    headers["Content-Length"]=ro_file.size.to_s
  end

  def create
    @investigation = Investigation.new(investigation_params)
    update_sharing_policies @investigation
    update_relationships(@investigation, params)

    if @investigation.save
      respond_to do |format|
        flash[:notice] = "The #{t('investigation')} was successfully created."
        if @investigation.create_from_asset == "true"
          flash.now[:notice] << "<br/> Now you can create new #{t('study')} for your #{t('assays.assay')} by clicking -Add a #{t('study')}- button".html_safe
          format.html { redirect_to investigation_path(:id => @investigation, :create_from_asset => @investigation.create_from_asset) }
          format.json { render json: @investigation }
        else
          format.html { redirect_to investigation_path(@investigation) }
          format.json { render json: @investigation }
        end
      end
    else
      respond_to do |format|
        format.html { render :action => "new" }
        format.json { render json: json_api_errors(@investigation), status: :unprocessable_entity }
      end
    end

  end

  def new
    @investigation=Investigation.new
    @investigation.create_from_asset = params[:create_from_asset]

    respond_to do |format|
      format.html
      format.xml { render :xml=>@investigation}
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    @investigation=Investigation.find(params[:id])
    @investigation.update_attributes(investigation_params)
    update_sharing_policies @investigation
    update_relationships(@investigation, params)

    respond_to do |format|
      if @investigation.save
        flash[:notice] = "#{t('investigation')} was successfully updated."
        format.html { redirect_to(@investigation) }
        format.json {render json: @investigation}
      else
        format.html { render :action => 'edit' }
        format.json { render json: json_api_errors(@investigation), status: :unprocessable_entity }
      end
    end
  end



  private

  def investigation_params
    params.require(:investigation).permit(:title, :description, { project_ids: [] }, :other_creators,
                                          :create_from_asset, { creator_ids: [] },
                                          { scales: [] }, { publication_ids: [] })
  end

end
