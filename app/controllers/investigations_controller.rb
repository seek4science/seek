class InvestigationsController < ApplicationController

  include Seek::IndexPager
  include Seek::DestroyHandling
  include Seek::AssetsCommon

  before_action :investigations_enabled?
  before_action :fair_data_station_enabled?, only: %i[update_from_fairdata_station submit_fairdata_station]
  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item, only: [:edit, :manage, :update, :manage_update, :destroy, :show,
                                                           :update_from_fairdata_station, :submit_fairdata_station, :fair_data_station_update_status,
                                                           :hide_fair_data_station_update_status, :new_object_based_on_existing_one]

  #project_membership_required_appended is an alias to project_membership_required, but is necesary to include the actions
  #defined in the application controller
  before_action :project_membership_required_appended, only: [:new_object_based_on_existing_one]

  before_action :check_studies_are_for_this_investigation, only: %i[update]

  include Seek::Publishing::PublishingCommon

  include Seek::AnnotationCommon

  include Seek::ISAGraphExtensions

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

  def submit_fairdata_station
    error = nil
    in_progress = []
    mismatching_external_id = false
    if params[:datastation_data].present?
      path = params[:datastation_data].path
      fair_data_station_inv = Seek::FairDataStation::Reader.new.parse_graph(path).first

      if fair_data_station_inv.present?
        in_progress = FairDataStationUpload.matching_updates_in_progress(@investigation, fair_data_station_inv.external_id)
        mismatching_external_id = fair_data_station_inv.external_id != @investigation.external_identifier
      else
        error = "Unable to find an #{t('investigation')} within the file"
      end
    else
      error = 'No file was submitted'
    end

    if mismatching_external_id
      error = "#{t('investigation')} external identifiers do not match"
    elsif in_progress.any?
      error = "An existing update of this #{t('investigation')} is currently already in progress."
    end

    if error.nil?
      content_blob = ContentBlob.new(tmp_io_object: params[:datastation_data],
                                     original_filename: params[:datastation_data].original_filename)
      fair_data_station_upload = FairDataStationUpload.new(contributor: current_person,
                                                           investigation: @investigation,
                                                           investigation_external_identifier: fair_data_station_inv.external_id,
                                                           purpose: :update, content_blob: content_blob
      )
      if fair_data_station_upload.save
        FairDataStationUpdateJob.new(fair_data_station_upload).queue_job
        redirect_to update_from_fairdata_station_investigation_path(@investigation)
      else
        error = 'Unable to save the record'
      end
    end

    if error.present?
      flash[:error] = error
      respond_to do |format|
        format.html { render action: :update_from_fairdata_station, status: :unprocessable_entity }
      end
    end

  end

  def fair_data_station_update_status
    upload = FairDataStationUpload.for_investigation_and_contributor(@investigation, current_person).update_purpose.where(id: params[:upload_id]).first
    if upload
      respond_to do |format|
        format.html { render partial: 'fair_data_station_update_status', locals: { upload: upload } }
      end
    else
      respond_to do |format|
        format.html { render plain:'', status: :forbidden }
      end
    end
  end

  def hide_fair_data_station_update_status
    upload = FairDataStationUpload.for_investigation_and_contributor(@investigation, current_person).update_purpose.where(id: params[:upload_id]).first
    if upload && (upload.update_task.completed? || upload.update_task.cancelled?)
      upload.update_attribute(:show_status, false)
      respond_to do |format|
        format.html { render plain:'' }
      end
    else
      respond_to do |format|
        format.html { render plain:'', status: :forbidden }
      end
    end
  end

  def export_isatab_json
    the_hash = ISATabConverter.convert_investigation(Investigation.find(params[:id]))
    send_data JSON.pretty_generate(the_hash) , filename: 'isatab.json'
  end

  def export_isa
    isa = ISAExporter::Exporter.new(Investigation.find(params[:id]), current_user).export
    send_data isa, filename: 'isa.json', type: 'application/json', deposition: 'attachment'
  rescue Exception => e
    respond_to do |format|
      flash[:error] = e.message
      format.html { redirect_to investigation_path(Investigation.find(params[:id])) }
    end
  end

  def show
    @investigation=Investigation.find(params[:id])

    respond_to do |format|
      format.html { render(params[:only_content] ? { layout: false } : {})}
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
    update_annotations(params[:tag_list], @investigation)
    update_relationships(@investigation, params)

    if @investigation.save
      respond_to do |format|
        flash[:notice] = "The #{t('investigation')} was successfully created."
        format.html { redirect_to params[:single_page] ?
          single_page_path(id: params[:single_page], item_type: 'investigation', item_id: @investigation) 
          : investigation_path(@investigation) }
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
    if params[:investigation]&.[](:ordered_study_ids)
      a1 = params[:investigation][:ordered_study_ids]
      a1.permit!
      pos = 0
      a1.each_pair do |key, value |
        disable_authorization_checks {
          study = Study.find (value)
          study.position = pos
          pos += 1
          study.save!
        }
      end
      respond_to do |format|
        format.html { redirect_to(@investigation) }
      end
    else
      @investigation.update(investigation_params)
      update_sharing_policies @investigation
      update_annotations(params[:tag_list], @investigation)
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
                                          :position, { publication_ids: [] },
                                          :is_isa_json_compliant,
                                          { discussion_links_attributes:[:id, :url, :label, :_destroy] },
                                          { extended_metadata_attributes: determine_extended_metadata_keys })
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
