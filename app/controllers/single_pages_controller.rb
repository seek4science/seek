require 'isatab_converter'
require 'roo'
require 'roo-xls'

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
    return unless Seek::Config.project_single_page_folders_enabled

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
    render json: { data: }
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

    sample_ids, sample_type_id, study_id, assay_id = Rails.cache.read(params[:uuid]).values_at(:sample_ids, :sample_type_id,
                                                                                     :study_id, :assay_id)

    @study = Study.find(study_id)
    @assay = Assay.find(assay_id) unless assay_id.nil?
    @project = @study.projects.first
    @samples = Sample.where(id: sample_ids)&.authorized_for(:view).sort_by(&:id)

    raise "Nothing to export to Excel." if @samples.nil? || @samples == [] || sample_type_id.nil?

    @sample_type = SampleType.find(sample_type_id)

    sample_attributes = @sample_type.sample_attributes.map do |sa|
      obj = if (sa.sample_controlled_vocab_id.nil?)
              { sa_cv_title: sa.title, sa_cv_id: nil }
            else
              { sa_cv_title: sa.title, sa_cv_id: sa.sample_controlled_vocab_id }
            end
      obj.merge({ required: sa.required })
    end

    @sa_cv_terms = [{ "name" => "id", "has_cv" => false, "data" => nil, "allows_custom_input" => nil, "required" => nil },
                    { "name" => "uuid", "has_cv" => false, "data" => nil, "allows_custom_input" => nil, "required" => nil }]

    sample_attributes.map do |sa|
        if sa[:sa_cv_id].nil?
          @sa_cv_terms.push({ "name" => sa[:sa_cv_title], "has_cv" => false, "data" => nil, "allows_custom_input" => nil, "required" => sa[:required] })
        else
          allows_custom_input = SampleControlledVocab.find(sa[:sa_cv_id])&.custom_input
          sa_terms = SampleControlledVocabTerm.where(sample_controlled_vocab_id: sa[:sa_cv_id]).map(&:label)
          @sa_cv_terms.push({ "name" => sa[:sa_cv_title], "has_cv" => true, "data" => sa_terms, "allows_custom_input" => allows_custom_input, "required" => sa[:required] })
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
    id_label = "#{Seek::Config::instance_name} id"
    sample_ids = JSON.parse(params[:sample_data]).map { |sample| sample[id_label] unless sample[id_label] == '#HIDDEN' }
    sample_type_id = JSON.parse(params[:sample_type_id])
    study_id = JSON.parse(params[:study_id])
    assay_id = JSON.parse(params[:assay_id])

    Rails.cache.write(cache_uuid, { "sample_ids": sample_ids.compact, "sample_type_id": sample_type_id, "study_id": study_id, "assay_id": assay_id },
                      expires_in: 1.minute)

    respond_to do |format|
      format.json { render json: { uuid: cache_uuid } }
    end
  end

  def upload_samples
    wb = Roo::Excelx.new(params[:file].path)
    sample_type_id_ui = params[:sample_type_id].to_i

    # Extract Samples metadata from spreadsheet
    study_id = wb.cell(2, 2, sheet = 'Metadata').to_i
    @study = Study.find(study_id)
    sample_type_id = wb.cell(5, 2, sheet = 'Metadata').to_i
    @sample_type = SampleType.find(sample_type_id)
    template_id = wb.cell(8, 2, sheet = 'Metadata').to_i
    @template = Template.find(template_id)
    is_assay = @sample_type.assays.any?
    @assay = @sample_type.assays.first
    @project = @study.projects.first # In Single Page a study can only belong to one project

    # Sample Type validation rules
    unless sample_type_id_ui == @sample_type&.id
      raise "Sample Type #{@sample_type&.id} from spreadsheet doesn't match Sample Type #{sample_type_id_ui} from the table. Please upload in the correct table."
    end
    unless @study.sample_types.include?(@sample_type) || is_assay
      raise "Sample Type '#{@sample_type.id}' doesn't belong to Study #{@study.id}. Sample Upload aborted."
    end
    unless (@assay&.sample_type == @sample_type) || !is_assay
      raise "Sample Type '#{@sample_type.id}' doesn't belong to Assay #{@assay.id}. Sample Upload aborted."
    end

    @multiple_input_fields = @sample_type.sample_attributes.map do |sa_attr|
      sa_attr.title if sa_attr.sample_attribute_type.base_type == 'SeekSampleMulti'
    end

    sample_fields = wb.row(1, sheet = 'Samples').map { |field| field.sub(' *', '') }
    samples_data = (2..wb.last_row(sheet = 'Samples')).map { |i| wb.row(i, sheet = 'Samples') }

    # Compare Excel header row to Sample Type Sample Attributes
    # Should raise an error if they don't match
    sample_type_attributes = %w[id uuid].concat(@sample_type.sample_attributes.map(&:title))
    has_unmapped_sample_attributes = sample_type_attributes.map { |sa| sample_fields.include?(sa) }.include?(false)
    if has_unmapped_sample_attributes
      raise "The Sample Attributes from the excel sheet don't match those of the Sample Type in the database. Sample upload was aborted!"
    end

    # Construct Samples objects from Excel data
    @excel_samples = samples_data.map do |excel_sample|
      obj = {}
      (0..sample_fields.size - 1).map do |i|
        if @multiple_input_fields.include?(sample_fields[i])
          parsed_excel_input_samples = JSON.parse(excel_sample[i].gsub('=>', ':')).map do |subsample|
            # Uploader should at least have viewing permissions for the inputs he's using
            unless Sample.find(subsample['id'])&.authorized_for_view?
              raise "Unauthorized Sample was detected in spreadsheet: #{subsample.inspect}"
            end

            subsample
          end
          obj.merge!(sample_fields[i] => parsed_excel_input_samples)
        else
          obj.merge!(sample_fields[i] => excel_sample[i])
        end
      end
      obj
    end

    @existing_excel_samples = @excel_samples.map { |sample| sample unless sample['id'].nil? }.compact
    @new_excel_samples = @excel_samples.map { |sample| sample if sample['id'].nil? }.compact

    @db_samples = @sample_type.samples&.authorized_for(:edit)&.map do |sample|
      attributes = JSON.parse(sample[:json_metadata])
      { 'id' => sample.id,
        'uuid' => sample.uuid }.merge(attributes)
    end

    # Determine whether samples have been modified or not
    @update_samples = @existing_excel_samples.map do |ees|
      db_sample = @db_samples.select { |s| s['id'] == ees['id'] }.first
      # An exception is raised if the ID of an existing Sample cannot be found in the DB
      raise "Sample with id '#{ees['id']}' does not exist in the database. Sample upload was aborted!" if db_sample.nil?

      is_changed = false

      db_sample.map do |k, v|
        unless ees[k] == v
          is_changed = true
          break
        end
      end

      ees if is_changed
    end
    @update_samples.compact!

    # Determine if the new samples are no duplicates of existing ones,
    # based on the attribute values
    @possible_duplicates = []
    @new_samples = []
    @new_excel_samples.map do |nes|
      is_duplicate = true

      @db_samples.map do |dbs|
        dbs.map do |k, v|
          unless %w[id uuid].include?(k)
            is_duplicate = (nes[k] == v)
            break unless is_duplicate
          end
        end
        if is_duplicate
          @possible_duplicates.append(nes.merge({ 'duplicate' => dbs }))
          break
        end
      end
      @new_samples.append(nes) unless is_duplicate
    end

    upload_data = { study: @study,
                    assay: @assay,
                    sampleType: @sample_type,
                    template: @template,
                    excelSamples: @excel_samples,
                    existingExcelSamples: @existing_excel_samples,
                    newExcelSamples: @new_excel_samples,
                    updateSamples: @update_samples,
                    newSamples: @new_samples,
                    possibleDuplicates: @possible_duplicates,
                    dbSamples: @db_samples }


    respond_to do |format|
      format.json { render json: { uploadData: upload_data } }
      format.html { render 'single_pages/sample_upload_content', { layout: false } }
    end
  rescue StandardError => e
    flash[:error] = e.message
    redirect_to single_page_path(@study.project_ids.first), status: :bad_request
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
