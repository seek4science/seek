
require 'simple-spreadsheet-extractor'

class DataFilesController < ApplicationController

  include Seek::IndexPager
  include SysMODB::SpreadsheetExtractor
  include MimeTypesHelper

  include Seek::AssetsCommon

  before_filter :find_assets, only: [:index]
  before_filter :find_and_authorize_requested_item, except: [:index, :new, :upload_for_tool, :upload_from_email, :create, :request_resource, :preview, :test_asset_url, :update_annotations_ajax]
  before_filter :find_display_asset, only: [:show, :explore, :download, :matching_models]
  skip_before_filter :verify_authenticity_token, only: [:upload_for_tool, :upload_from_email]
  before_filter :xml_login_only, only: [:upload_for_tool, :upload_from_email]
  before_filter :get_sample_type, only: :extract_samples
  before_filter :check_already_extracted, only: :extract_samples
  before_filter :forbid_new_version_if_samples, :only => :new_version	

  # has to come after the other filters
  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  include Seek::DataciteDoi

  include Seek::IsaGraphExtensions

  def plot
    sheet = params[:sheet] || 2
    @csv_data = spreadsheet_to_csv(open(@data_file.content_blob.filepath), sheet, true)
    respond_to do |format|
      format.html
    end
  end

  def destroy
    if @data_file.extracted_samples.any? && !params[:destroy_extracted_samples]
      redirect_to destroy_samples_confirm_data_file_path(@data_file)
    else
      if params[:destroy_extracted_samples] == '1'
        @data_file.extracted_samples.destroy_all
      end
      super
    end
  end

  def destroy_samples_confirm
    if @data_file.can_delete?
      respond_to do |format|
        format.html
      end
    end
  end

  def new_version
    if handle_upload_data
      comments = params[:revision_comment]

      respond_to do |format|
        if @data_file.save_as_new_version(comments)
          create_content_blobs
          # Duplicate studied factors
          factors = @data_file.find_version(@data_file.version - 1).studied_factors
          factors.each do |f|
            new_f = f.dup
            new_f.data_file_version = @data_file.version
            new_f.save
          end
          flash[:notice] = "New version uploaded - now on version #{@data_file.version}"
          if @data_file.is_with_sample?
            bio_samples = @data_file.bio_samples_population @data_file.samples.first.institution_id if @data_file.samples.first
            unless bio_samples.errors.blank?
              flash[:notice] << '<br/> However, Sample database population failed.'
              flash[:error] = bio_samples.errors.html_safe
            end
          end
        else
          flash[:error] = 'Unable to save new version'
        end
        format.html { redirect_to @data_file }
      end
    else
      flash[:error] = flash.now[:error]
      redirect_to @data_file
    end
  end

  def upload_for_tool
    if handle_upload_data
      params[:data_file][:project_ids] = [params[:data_file].delete(:project_id)] if params[:data_file][:project_id]
      @data_file = DataFile.new(data_file_params)

      @data_file.policy = Policy.new_for_upload_tool(@data_file, params[:recipient_id])

      if @data_file.save
        @data_file.creators = [current_person]
        create_content_blobs
        # send email to the file uploader and receiver
        Mailer.file_uploaded(current_user, Person.find(params[:recipient_id]), @data_file).deliver_now

        flash.now[:notice] = "#{t('data_file')} was successfully uploaded and saved." if flash.now[:notice].nil?
        render text: flash.now[:notice]
      else
        errors = (@data_file.errors.map { |e| e.join(' ') }.join("\n"))
        render text: errors, status: 500
      end
    end
  end

  def upload_from_email
    if current_user.is_admin? && Seek::Config.admin_impersonation_enabled
      User.with_current_user Person.find(params[:sender_id]).user do
        if handle_upload_data
          @data_file = DataFile.new(data_file_params)

          @data_file.policy = Policy.new_from_email(@data_file, params[:recipient_ids], params[:cc_ids])

          if @data_file.save
            @data_file.creators = [User.current_user.person]
            create_content_blobs

            flash.now[:notice] = "#{t('data_file')} was successfully uploaded and saved." if flash.now[:notice].nil?
            render text: flash.now[:notice]
          else
            errors = (@data_file.errors.map { |e| e.join(' ') }.join("\n"))
            render text: errors, status: 500
          end
        end
      end
    else
      render text: 'This user is not permitted to act on behalf of other users', status: :forbidden
    end
  end

  def create
    @data_file = DataFile.new(data_file_params)

    if handle_upload_data
      update_sharing_policies(@data_file)

      if @data_file.save
        update_annotations(params[:tag_list], @data_file)
        update_scales @data_file

        create_content_blobs

        update_relationships(@data_file, params)

        if !@data_file.parent_name.blank?
          render partial: 'assets/back_to_fancy_parent', locals: { child: @data_file, parent_name: @data_file.parent_name, is_not_fancy: true }
        else
          respond_to do |format|
            flash[:notice] = "#{t('data_file')} was successfully uploaded and saved." if flash.now[:notice].nil?
            # parse the data file if it is with sample data
            if @data_file.is_with_sample
              bio_samples = @data_file.bio_samples_population params[:institution_id]

              unless  bio_samples.errors.blank?
                flash[:notice] << '<br/> However, Sample database population failed.'
                flash[:error] = bio_samples.errors.html_safe
              end
            end
            # the assay_id param can also contain the relationship type
            assay_ids, relationship_types = determine_related_assay_ids_and_relationship_types(params)
            update_assay_assets(@data_file, assay_ids, relationship_types)
            format.html { redirect_to data_file_path(@data_file) }
          end
      end
      else
        respond_to do |format|
          format.html do
            render action: 'new'
          end
        end

      end
    else
      handle_upload_data_failure
    end
  end

  def determine_related_assay_ids_and_relationship_types(params)
    assay_ids = []
    relationship_types = []
    (params[:assay_ids] || []).each do |assay_type_text|
      assay_id, relationship_type = assay_type_text.split(',')
      assay_ids << assay_id
      relationship_types << relationship_type
    end
    [assay_ids, relationship_types]
  end

  def update
    @data_file.attributes = data_file_params

    update_annotations(params[:tag_list], @data_file)
    update_scales @data_file

    respond_to do |format|
      update_sharing_policies @data_file

      if @data_file.save
        update_relationships(@data_file, params)

        # the assay_id param can also contain the relationship type
        assay_ids, relationship_types = determine_related_assay_ids_and_relationship_types(params)
        update_assay_assets(@data_file, assay_ids, relationship_types)

        flash[:notice] = "#{t('data_file')} metadata was successfully updated."
        format.html { redirect_to data_file_path(@data_file) }

      else
        format.html do
          render action: 'edit'
        end
      end
    end
  end

  def data
    @data_file =  DataFile.find(params[:id])
    sheet = params[:sheet] || 1
    trim = params[:trim] || false
    content_blob = @data_file.content_blob
    file = open(content_blob.filepath)
    mime_extensions = mime_extensions(content_blob.content_type)
    if !(%w(xls xlsx) & mime_extensions).empty?
      respond_to do |format|
        format.html # currently complains about a missing template, but we don't want people using this for now - its purely XML
        format.xml { render xml: spreadsheet_to_xml(file) }
        format.csv { render text: spreadsheet_to_csv(file, sheet, trim) }
      end
    else
      respond_to do |format|
        flash[:error] = 'Unable to view contents of this data file'
        format.html { redirect_to @data_file, format: 'html' }
      end
    end
  end

  def explore
    if @display_data_file.contains_extractable_spreadsheet?
      respond_to do |format|
        format.html
      end
    else
      respond_to do |format|
        flash[:error] = 'Unable to view contents of this data file'
        format.html { redirect_to data_file_path(@data_file, version: @display_data_file.version) }
      end
    end
  end

  def matching_models
    # FIXME: should use the correct version
    @matching_model_items = @data_file.matching_models
    # filter authorization
    ids = @matching_model_items.collect(&:primary_key)
    models = Model.where(id: ids)
    authorised_ids = Model.authorize_asset_collection(models, 'view').collect(&:id)
    @matching_model_items = @matching_model_items.select { |mdf| authorised_ids.include?(mdf.primary_key.to_i) }

    flash.now[:notice] = "#{@matching_model_items.count} #{t('model').pluralize}  were found that may be relevant to this #{t('data_file')} "
    respond_to do |format|
      format.html
    end
  end

  def filter
    if params[:with_samples]
      scope = DataFile.with_extracted_samples
    else
      scope = DataFile
    end

    @data_files = DataFile.authorize_asset_collection(
      scope.where('data_files.title LIKE ?', "#{params[:filter]}%"), 'view'
    ).first(20)

    respond_to do |format|
      format.html { render partial: 'data_files/association_preview', collection: @data_files, locals: { hide_sample_count: !params[:with_samples] } }
    end
  end

  def samples_table
    respond_to do |format|
      format.html do
        render(partial: 'samples/table_view', locals: {
                 samples: @data_file.extracted_samples.includes(:sample_type),
                 source_url: samples_table_data_file_path(@data_file)
               })
      end
      format.json { @samples = @data_file.extracted_samples.select([:id, :title, :json_metadata]) }
    end
  end

  def select_sample_type
    @possible_sample_types = @data_file.possible_sample_types

    respond_to do |format|
      format.html
    end
  end

  def extract_samples
    if params[:confirm]
      extractor = Seek::Samples::Extractor.new(@data_file, @sample_type)
      @samples = extractor.persist.select(&:persisted?)
      extractor.clear
      flash[:notice] = "#{@samples.count} samples extracted successfully"
    else
      SampleDataExtractionJob.new(@data_file, @sample_type, false).queue_job
    end

    respond_to do |format|
      format.html { redirect_to @data_file }
    end
  end

  def confirm_extraction
    @samples, @rejected_samples = Seek::Samples::Extractor.new(@data_file).fetch.partition(&:valid?)
    @sample_type = @samples.first.sample_type if @samples.any?
    @sample_type ||= @rejected_samples.first.sample_type if @rejected_samples.any?

    respond_to do |format|
      format.html
    end
  end

  def cancel_extraction
    Seek::Samples::Extractor.new(@data_file).clear

    respond_to do |format|
      flash[:notice] = 'Sample extraction cancelled'
      format.html { redirect_to @data_file }
    end
  end

  def extraction_status
    @previous_status = params[:previous_status]
    @job_status = SampleDataExtractionJob.get_status(@data_file)

    respond_to do |format|
      format.html { render partial: 'data_files/sample_extraction_status', locals: { data_file: @data_file } }
    end
  end

  protected

  def xml_login_only
    unless session[:xml_login]
      flash[:error] = 'Only available when logged in via xml'
      redirect_to root_url
    end
  end

  def get_sample_type
    if params[:sample_type_id] || @data_file.possible_sample_types.count == 1
      if params[:sample_type_id]
        @sample_type = SampleType.includes(:sample_attributes).find(params[:sample_type_id])
      else
        @sample_type = @data_file.possible_sample_types.last
      end
    elsif @data_file.possible_sample_types.count > 1
      # Redirect to sample type selector
      respond_to do |format|
        format.html { redirect_to select_sample_type_data_file_path(@data_file) }
      end
    else
      flash[:error] = "Couldn't determine the sample type of this data"
      respond_to do |format|
        format.html { redirect_to @data_file }
      end
    end
  end

  def check_already_extracted
    if @data_file.extracted_samples.any?
      flash[:error] = 'Already extracted samples from this data file'
      respond_to do |format|
        format.html { redirect_to @data_file }
      end
    end
  end

  def forbid_new_version_if_samples
    if @data_file.extracted_samples.any?
      flash[:error] = "Cannot upload a new version if samples have been extracted"
      respond_to do |format|
        format.html { redirect_to @data_file }
      end
    end
  end

  private

  def data_file_params
    params.require(:data_file).permit(:title, :description, { project_ids: [] }, :license, :other_creators,
                                      :parent_name, { event_ids: [] },
                                      { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] })
  end

end
