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
      render plain: @content_blob.file.read.encode('utf-8', 'iso-8859-1', invalid: :replace, undef: :replace),
             layout: false, content_type: 'text/csv'
    elsif @content_blob.is_excel?
      sheet = params[:sheet] || 1
      trim = params[:trim] || false
      begin
        render plain: @content_blob.to_csv(sheet, trim), content_type: 'text/csv'
      rescue SysMODB::SpreadsheetExtractionException => e
        render plain: e.message.lines.first, content_type: 'text/csv', status: :unprocessable_entity
      end
    else
        render plain: 'Unable to view contents of this data file,', content_type: 'text/csv', status: :not_acceptable
    end
  end

  def xml_data
    if @content_blob.no_content?
      render plain: 'No content, Content blob does not have content', content_type: 'text/xml', status: :not_found
    elsif @content_blob.is_excel?

      render plain: @content_blob.to_spreadsheet_xml, content_type: 'text/xml'
    else
      render plain: 'Unable to view contents of this data file,', content_type: 'text/xml', status: :not_acceptable
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @content_blob, include: [params[:include]] }
      format.html { render plain: 'Format not supported', status: :not_acceptable }
      format.csv { csv_data }
      format.xml { xml_data }
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

  # Converts the blob to PDF if necessary, then serves it via the storage adapter.
  # LocalAdapter: send_file with the on-disk path.
  # S3Adapter: redirect to a presigned URL.
  def pdf_or_convert
    if @content_blob.is_pdf?
      # The dat file itself is the PDF — serve it directly via the dat adapter.
      pdf_filename = @content_blob.original_filename
      adapter = @content_blob.storage_adapter
      key = @content_blob.storage_key
    else
      # Convert (adapter-aware, no-ops if pdf key already exists).
      @content_blob.convert_to_pdf
      raise "Couldn't find converted PDF file." unless @content_blob.file_exists?('pdf')

      pdf_filename = "#{File.basename(@content_blob.original_filename, '.*')}.pdf"
      adapter = @content_blob.storage_adapter('pdf')
      key = @content_blob.storage_key('pdf')
    end

    serve_pdf(adapter, key, pdf_filename)
  end


  def serve_pdf(adapter, key, filename)
    local_path = adapter.full_path(key)
    if local_path
      send_file local_path, filename: filename, type: 'application/pdf', disposition: 'attachment'
      headers['Content-Length'] = File.size(local_path).to_s
    else
      redirect_to adapter.presigned_url(key, expires_in: 300), allow_other_host: true
    end
  end

  def get_file_from_jerm
    project = @asset_version.projects.first
    downloader = JERM::DownloaderFactory.create project.title
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
          format.csv do
            render plain: 'Not authorized', status: :forbidden
          end
          format.xml do
            render plain: 'Not authorized', status: :forbidden
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
    if request.media_type == 'multipart/form-data'
      # "Unwrap" multipart requests to get at the content.
      params.values.detect { |v| v.is_a?(ActionDispatch::Http::UploadedFile) }
    else
      request.body
    end
  end
end
