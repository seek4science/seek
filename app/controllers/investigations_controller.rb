class InvestigationsController < ApplicationController

  include Seek::IndexPager
  include Seek::DestroyHandling
  include Seek::AssetsCommon

  before_action :investigations_enabled?
  before_action :find_assets, :only=>[:index]
  before_action :find_and_authorize_requested_item,:only=>[:edit, :manage, :update, :manage_update, :destroy, :show,:new_object_based_on_existing_one]

  #project_membership_required_appended is an alias to project_membership_required, but is necesary to include the actions
  #defined in the application controller
  before_action :project_membership_required_appended, :only=>[:new_object_based_on_existing_one]

  before_action :check_studies_are_for_this_investigation, only: %i[update]

  include Seek::Publishing::PublishingCommon

  include Seek::AnnotationCommon

  include Seek::IsaGraphExtensions

  require "isatab_converter"
  include IsaTabConverter

  api_actions :index, :show, :create, :update, :destroy

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

  def export_isatab_json
    the_hash = convert_investigation Investigation.find(params[:id])
    send_data JSON.pretty_generate(the_hash) , filename: 'isatab.json'
  end

  def show
    @investigation=Investigation.find(params[:id])

    respond_to do |format|
      format.html { render(params[:only_content] ? { layout: false } : {})}
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
        format.html { redirect_to investigation_path(@investigation) }
        format.json { render json: @investigation }
      end
    else
      respond_to do |format|
        format.html { render :action => "new" }
        format.json { render json: json_api_errors(@investigation), status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def order_studies
    @investigation = Investigation.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def update
    @investigation=Investigation.find(params[:id])
    if params[:investigation][:ordered_study_ids]
      a1 = params[:investigation][:ordered_study_ids]
      a1.permit!
      pos = 0
      a1.each_pair do |key, value |
        study = Study.find (value)
        study.position = pos
        pos += 1
        study.save!
      end
      respond_to do |format|
        format.html { redirect_to(@investigation) }
      end
    else
      @investigation.update_attributes(investigation_params)
      update_sharing_policies @investigation
      update_relationships(@investigation, params)

      respond_to do |format|
        if @investigation.save
          flash[:notice] = "#{t('investigation')} was successfully updated."
          format.html {redirect_to(@investigation)}
          format.json {render json: @investigation}
        else
          format.html {render :action => 'edit'}
          format.json {render json: json_api_errors(@investigation), status: :unprocessable_entity}
        end
      end
    end
  end



  private

  def investigation_params
    params.require(:investigation).permit(:title, :description, { project_ids: [] }, *creator_related_params,
                                          :position, { scales: [] }, { publication_ids: [] },
                                          { discussion_links_attributes:[:id, :url, :label, :_destroy] },
                                          { custom_metadata_attributes: determine_custom_metadata_keys })
  end

  def check_studies_are_for_this_investigation
    investigation_id = params[:id]
    if params[:investigation][:ordered_study_ids]
      a1 = params[:investigation][:ordered_study_ids]
      a1.permit!
      valid = true
      a1.each_pair do |key, value |
        a = Study.find (value)
        valid = valid && !a.investigation.nil? && a.investigation_id.to_s == investigation_id
      end
      unless valid
        error("Each ordered #{"Study"} must be associated with the Investigation", "is invalid (invalid #{"Study"})")
        return false
      end
    end
    return true
  end


end
