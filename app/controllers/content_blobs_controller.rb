class ContentBlobsController < ApplicationController
  before_action :find_and_authorize_associated_asset, only: %i[get_pdf view_content download show update]
  before_action :find_and_authorize_content_blob, only: %i[get_pdf view_content download show update]
  before_action :set_asset_version, only: %i[get_pdf download]

  skip_before_action :check_json_id_type, only: [:update]

  include RawDisplay
  include Seek::AssetsCommon
  include Seek::UploadHandling::ExamineUrl

  api_actions :show, :update, :download

  def update
    if @content_blob.no_content?
      @content_blob.tmp_io_object = get_request_payload
      @content_blob.save
      @asset.touch
      respond_to do |format|
        format.all { render plain: @content_blob.file_size, status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: {}, status: :bad_request }
      end
    end
  end

  def view_content
    opts = {}
    opts[:code] = params[:code] if params[:code]
    render_display(@content_blob, url_options: opts)
  end

  def csv_data
    if @content_blob.no_content?
      render plain: 'No content, Content blob does not have content', content_type: 'text/csv', status: :not_found
    elsif @content_blob.is_csv?
        render plain: File.read(@content_blob.filepath, encoding: 'iso-8859-1'), layout: false, content_type: 'text/csv'
    elsif @content_blob.is_excel?
        sheet = params[:sheet] || 1
        trim = params[:trim] || false
        render plain: @content_blob.to_csv(sheet, trim), content_type: 'text/csv'
    else
        render plain: 'Unable to view contents of this data file,', content_type: 'text/csv', status: :not_acceptable
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @content_blob, include: [params[:include]] }
      format.html { render plain: 'Format not supported', status: :not_acceptable }
      format.csv { csv_data }
    end
  end

  def get_pdf
    if @content_blob.file_exists?
      pdf_or_convert
    elsif @content_blob.cachable?
      @content_blob.remote_content_fetch_task&.cancel
      @content_blob.retrieve
      pdf_or_convert
    else
      raise('This remote file is too big to be displayed as PDF.')
    end
  end

  def download

    if @asset.respond_to?(:openbis?) && @asset.openbis?
      respond_to do |format|
        format.html { handle_openbis_download(@asset, params[:perm_id]) }
      end
    else
      if render_display?
        render_display(@content_blob)
      else
        disposition = params[:disposition] || 'attachment'
        image_size = params[:image_size]

        respond_to do |format|
          format.html { handle_download(disposition, image_size) }
          format.pdf { get_pdf }
          format.json { handle_download(disposition, image_size) }
        end
      end
    end
  end

  private

  def pdf_url
    polymorphic_path([@asset, @content_blob], action: 'download', intent: :inline_view, format: 'pdf', code: params[:code])
  end

  # check whether the file is pdf, otherwise convert to pdf
  # then return the pdf file
  def pdf_or_convert(filepath = @content_blob.filepath)
    if @content_blob.is_pdf?
      pdf_filepath = @content_blob.filepath
      pdf_filename = @content_blob.original_filename
    else
      pdf_filepath = @content_blob.filepath('pdf')
      unless File.exist?(pdf_filepath)
        @content_blob.convert_to_pdf(filepath, pdf_filepath)
        raise "Couldn't find converted PDF file." unless File.exist?(pdf_filepath) # If conversion didn't work somehow?
      end

      pdf_filename = File.basename(@content_blob.original_filename, File.extname(@content_blob.original_filename)) + '.pdf'
    end

    send_file pdf_filepath, filename: pdf_filename, type: 'application/pdf', disposition: 'attachment'

    headers['Content-Length'] = File.size(pdf_filepath).to_s
  end

  def get_file_from_jerm
    project = @asset_version.projects.first
    downloader = Jerm::DownloaderFactory.create project.title
    resource_type = @asset_version.class.name.split('::')[0] # need to handle versions, e.g. Sop::Version
    begin
      data_hash = downloader.get_remote_data @content_blob.url, project.site_username, project.site_password, resource_type
      data_hash
    rescue Seek::DownloadException => de
      nil
    end
  end

  def find_and_authorize_associated_asset
    asset = asset_object
    if asset
      if asset.can_edit? || (action_name != 'update' && (asset.can_download? || (params[:code] && asset.auth_by_code?(params[:code]))))
        @asset = asset
      else
        respond_to do |format|
          flash[:error] = 'You are not authorized to perform this action'
          format.html { redirect_to asset }
          format.json do
            render json: { "title": 'Forbidden',
                           "detail": "You are not authorized to download the asset linked to content_blob:#{params[:id]}" },
                   status: :forbidden
          end
        end
        return false
      end
    else
      flash[:error] = 'The asset could not be found'
      respond_to do |format|
        format.json do
          render json: { "title": 'Not found',
                         "detail": 'The asset could not be found' }, status: :not_found
        end
        format.html { redirect_to root_url }
      end
    end
  end

  def asset_object
    params.each do |param, value|
      if param.end_with?('_id')
        begin
          c = safe_class_lookup(param.chomp('_id').classify)
        rescue NameError
        else
          if c.method_defined?(:content_blob) || c.method_defined?(:content_blobs)
            return c.find_by_id(value)
          end
        end
      end
    end

    nil # If nothing found
  end

  def find_and_authorize_content_blob
    content_blob = content_blob_object
    if content_blob && content_blob.asset == @asset
      @content_blob = content_blob
    else
      flash[:error] = 'The blob was not found, or is not associated with this asset'
      respond_to do |format|
        format.json do
          render json: { "title": 'Not found',
                         "detail": 'The content blob was not found, or not related to the asset' }, status: :not_found
        end
        format.html { redirect_to root_url }
      end
      return false
    end
  end

  def content_blob_object
    ContentBlob.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def set_asset_version
    if @content_blob.asset_version
      begin
        @asset_version = @content_blob.asset.find_version(@content_blob.asset_version)
      rescue Exception => e
        error('Unable to find asset version', 'is invalid')
        return false
      end
    end
  end

  def get_request_payload
    if request.content_type == 'multipart/form-data'
      # "Unwrap" multipart requests to get at the content.
      params.values.detect { |v| v.is_a?(ActionDispatch::Http::UploadedFile) }
    else
      request.body
    end
  end
end
