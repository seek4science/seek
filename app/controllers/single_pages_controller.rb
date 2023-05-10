require 'isatab_converter'

class SinglePagesController < ApplicationController
  include Seek::AssetsCommon
  include Seek::Sharing::SharingCommon

  before_action :set_up_instance_variable
  before_action :project_single_page_enabled?
  before_action :find_authorized_investigation, only: :export_isa
  before_action :check_user_logged_in,
                only: %i[batch_sharing_permission_preview batch_change_permission_for_selected_items]
  respond_to :html, :js

  def show
    @project = Project.find(params[:id])
    @folders = project_folders
    respond_to do |format|
      format.html
    end
  end

  def index; end

  def project_folders
    return unless Seek::Config.project_single_page_enabled

    project_folders = ProjectFolder.root_folders(@project)
    if project_folders.empty?
      project_folders = ProjectFolder.initialize_default_folders(@project)
      ProjectFolderAsset.assign_existing_assets @project
    end
    project_folders
  end

  def dynamic_table_data
    data = []
    if params[:sample_type_id]
      sample_type = SampleType.find(params[:sample_type_id]) if params[:sample_type_id]
      data = helpers.dt_data(sample_type)[:rows]
    elsif params[:study_id]
      study = Study.find(params[:study_id]) if params[:study_id]
      assay = Assay.find(params[:assay_id]) if params[:assay_id]
      data = helpers.dt_aggregated(study, assay)[:rows]
    end
    data = data.map { |row| row.unshift('') } if params[:rows_pad]
    render json: { data: data }
  rescue Exception => e
    render json: { status: :unprocessable_entity, error: e.message }
  end

  def export_isa
    raise 'The investigation cannot be found!' if @inv.blank?

    isa = IsaExporter::Exporter.new(@inv).export
    send_data isa, filename: 'isa.json', type: 'application/json', deposition: 'attachment'
  rescue Exception => e
    respond_to do |format|
      flash[:error] = e.message
      format.html { redirect_to single_page_path(Project.find(params[:id])) }
    end
  end

  def download_samples_excel

    sample_ids, sample_type_id, study_id = Rails.cache.read(params[:uuid]).values_at(:sample_ids, :sample_type_id,
                                                                                     :study_id)

    @study = Study.find(study_id)
    @project = @study.projects.first
    @samples = Sample.where(id: sample_ids)&.authorized_for(:view).sort_by(&:id)

    raise "Nothing to export to Excel." if @samples.nil? || @samples == [] || sample_type_id.nil?

    @sample_type = SampleType.find(sample_type_id)

    sample_attributes = @sample_type.sample_attributes.map do |sa|
      if (sa.sample_controlled_vocab_id.nil?)
        { sa.title => nil }
      else
        { sa.title => sa.sample_controlled_vocab_id }
      end
    end

    @sa_cv_terms = [{ "name" => "id", "has_cv" => false, "data" => nil, "allows_custom_input" => nil },
                    { "name" => "uuid", "has_cv" => false, "data" => nil, "allows_custom_input" => nil }]

    sample_attributes.map do |sa_cv|
      sa_cv.map do |title, id|
        if id.nil?
          @sa_cv_terms.push({ "name" => title, "has_cv" => false, "data" => nil, "allows_custom_input" => nil })
        else
          allows_custom_input = SampleControlledVocab.find(id)&.custom_input
          sa_terms = SampleControlledVocabTerm.where(sample_controlled_vocab_id: id).map(&:label)
          @sa_cv_terms.push({ "name" => title, "has_cv" => true, "data" => sa_terms, "allows_custom_input" => allows_custom_input })
        end
      end
    end
    @template = Template.find(@sample_type.template_id)

    render xlsx: 'download_samples_excel', filename: 'samples_table.xlsx', disposition: 'inline'
  rescue StandardError => e
    flash[:error] = e.message
    respond_to do |format|
      format.html { redirect_to single_page_path(@project.id) }
      format.json { render json: { parameters: { sample_ids: sample_ids, sample_type_id: sample_type_id, study_id: study_id } } }
    end
  end

  def export_to_excel
    cache_uuid = UUID.new.generate
    sample_ids = JSON.parse(params[:source_sample_data]).map { |sample| sample['FAIRDOM-SEEK id'] if sample['FAIRDOM-SEEK id'] != '#HIDDEN' }
    sample_type_id = JSON.parse(params[:sample_type_id])
    study_id = JSON.parse(params[:study_id])

    Rails.cache.write(cache_uuid, { "sample_ids": sample_ids.compact, "sample_type_id": sample_type_id, "study_id": study_id },
                      expires_in: 1.minute)

    respond_to do |format|
      format.json { render json: { uuid: cache_uuid } }
    end
  end

  private

  def set_up_instance_variable
    @single_page = true
  end

  def find_authorized_investigation
    investigation = Investigation.find(params[:investigation_id])
    @inv = investigation if investigation.can_edit?
  end

  def check_user_logged_in
    unless current_user
      render json: { status: :unprocessable_entity, error: 'You must be logged in to access batch sharing permission.' }
    end
  end
end
