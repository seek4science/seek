class ContentBlobsController < ApplicationController
  before_filter :find_and_authorize_associated_asset, only: %i[get_pdf view_content view_pdf_content download show]
  before_filter :find_and_authorize_content_blob, only: %i[get_pdf view_content view_pdf_content download show]
  before_filter :set_asset_version, only: %i[get_pdf download]

  include Seek::AssetsCommon
  include Seek::UploadHandling::ExamineUrl

  def view_content
    if @content_blob.is_text?
      view_text_content
    else
      @pdf_url = pdf_url
      render action: :view_pdf_content, layout: false
    end
  end

  def view_text_content
    render text: File.read(@content_blob.filepath, encoding: 'iso-8859-1'), layout: false, content_type: 'text/plain'
  end

  def view_pdf_content
    @pdf_url = pdf_url
    respond_to do |format|
      format.html { render layout: false }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @content_blob }
      format.html { render text: 'Format not supported', status: :not_acceptable }
      format.xml { render text: 'Format not supported', status: :not_acceptable }
      format.rdf { render text: 'Format not supported', status: :not_acceptable }
    end
  end

  def examine_url
    # check content type and size
    url = params[:data_url]
    begin
      case scheme = URI(url).scheme
      when 'ftp'
        handler = Seek::DownloadHandling::FTPHandler.new(url)
        info = handler.info
        handle_good_ftp_response(url, info)
      when 'http', 'https', nil
        handler = Seek::DownloadHandling::HTTPHandler.new(url)
        info = handler.info
        if info[:code] == 200
          handle_good_http_response(url, info)
        else
          handle_bad_http_response(info[:code])
        end
      else
        @warning = true
        @warning_msg = "Unhandled URL scheme: #{scheme}. The given URL will be presented as a clickable link."
      end
    rescue Exception => e
      handle_exception_response(e)
    end
  end

  def get_pdf
    if @content_blob.file_exists?
      begin
        pdf_or_convert
      rescue Exception => e
        raise(e)
      end
    elsif @content_blob.cachable?
      if (caching_job = @content_blob.caching_job).exists?
        caching_job.first.destroy
      end
      @content_blob.retrieve
      begin
        pdf_or_convert
      rescue Exception => e
        raise(e)
      end
    else
      raise('This remote file is too big to be displayed as PDF.')
    end
  end

  def download
    @asset.just_used if @asset.respond_to?(:just_used)

    if @asset.respond_to?(:openbis?) && @asset.openbis?
      respond_to do |format|
        format.html { handle_openbis_download(@asset, params[:perm_id]) }
      end
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
      @content_blob.convert_to_pdf(filepath, pdf_filepath)

      if File.exist?(pdf_filepath)
        pdf_filename = File.basename(@content_blob.original_filename, File.extname(@content_blob.original_filename)) + '.pdf'
      else
        raise Exception, "Couldn't find converted PDF file."
      end
    end

    send_file pdf_filepath,
              filename: pdf_filename,
              type: 'application/pdf',
              disposition: 'attachment'

    headers['Content-Length'] = File.size(pdf_filepath).to_s
  end

  def get_file_from_jerm
    project = @asset_version.projects.first
    project.decrypt_credentials
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
      if asset.can_download? || (params[:code] && asset.auth_by_code?(params[:code]))
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
      flash[:error]='The asset could not be found'
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
    if params[:data_file_id]
      DataFile.find(params[:data_file_id])
    elsif params[:model_id]
      Model.find(params[:model_id])
    elsif params[:sop_id]
      Sop.find(params[:sop_id])
    elsif params[:presentation_id]
      Presentation.find(params[:presentation_id])
    elsif params[:sample_type_id]
      SampleType.find(params[:sample_type_id])
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def find_and_authorize_content_blob
    content_blob = content_blob_object
    if content_blob && content_blob.asset == @asset
      @content_blob = content_blob
    else
      flash[:error]='The blob was not found, or is not associated with this asset'
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
end
