
class ContentBlobsController < ApplicationController

  before_filter :find_and_authorize_associated_asset, :only=>[:get_pdf, :view_pdf_content, :download]
  before_filter :find_and_authorize_content_blob, :only=>[:get_pdf, :view_pdf_content, :download]
  before_filter :set_asset_version, :only=>[:get_pdf, :download]

  include Seek::AssetsCommon
  include Seek::UploadHandling::ExamineUrl
  include Seek::ContentBlobCommon

  def view_pdf_content
    #param code is used for temporary link
    @pdf_url = polymorphic_path([@asset,@content_blob], :action => 'download',:intent=>:inline_view, :format => 'pdf', :code => params[:code])
    respond_to do |format|
      format.html { render :layout=>false }
    end
  end

  def examine_url
    #check content type and size
    url = params[:data_url]
    begin
      code = check_url_response_code(url)
      if code == 200
        process_view_for_successful_url(url)
      else
        handle_non_200_response(code)
      end
    rescue Exception=>e
      handle_exception_response(e)
    end
  end

  def get_pdf
    if @content_blob.url.blank?
      begin
        pdf_or_convert
      rescue Exception=>e
        raise ("#{e}")
      end
    else
      begin
        if @asset_version.contributor.nil? #A jerm generated resource
          get_and_process_file(false, true)  #from jerm
        else
          get_and_process_file(true, false)  #from url
        end
      rescue Seek::DownloadException=>de
        raise ("#{de}")
      rescue Jerm::JermException=>de
        raise ("#{de}")
      end
    end
  end


  def download

    @asset.just_used

    disposition = params[:disposition] || 'attachment'
    image_size = params[:image_size]

    respond_to do |format|
      format.html {handle_download(disposition, image_size)}
      format.pdf {get_pdf}
    end
  end

  private



  #check whether the file is pdf, otherwise convert to pdf
  #then return the pdf file
  def pdf_or_convert dat_filepath=@content_blob.filepath

    if @content_blob.is_pdf?
      send_file dat_filepath, :filename => @content_blob.original_filename, :type => "application/pdf", :disposition => 'attachment'
      headers["Content-Length"]=File.size(dat_filepath).to_s
    else
      pdf_filepath = @content_blob.filepath("pdf")
      @content_blob.convert_to_pdf(dat_filepath,pdf_filepath)

      if File.exists?(pdf_filepath)
        filename = File.basename(@content_blob.original_filename,File.extname(@content_blob.original_filename))+".pdf"
        send_file pdf_filepath, :filename =>filename , :type => "application/pdf", :disposition => 'attachment'
        headers["Content-Length"]=File.size(pdf_filepath).to_s
      else
        raise Exception.new('Unable to convert the file for display')
      end
    end
  end

  def get_and_process_file from_url=true,from_jerm=false
    if from_url
      data_hash = get_data_hash_from_url
      #delete the previous conversion to refresh, but only if a copy of the original exists
      pdf_path = @content_blob.filepath("pdf")
      FileUtils.rm pdf_path if File.exist?(pdf_path) && @content_blob.file_exists?
    else
      begin
        data_hash = get_data_hash_from_jerm
      rescue Jerm::JermException=>e
        if @content_blob.file_exists?
          data_hash = nil
        else
          raise e
        end
      end
    end

    if data_hash
      pdf_or_convert data_hash[:data_tmp_path]
    elsif File.exists?(@content_blob.filepath)
      pdf_or_convert
    else
      redirect_on_error @asset_version,"Unable to find a copy of the file for viewing, or an alternative location. Please contact an administrator of #{Seek::Config.application_name}."
    end
  end

  def get_data_hash_from_url
    code = check_url_response_code(@content_blob.url)
    if code == 200
      downloader=Seek::RemoteDownloader.new
      begin
        data_hash = downloader.get_remote_data @content_blob.url
        data_hash
      rescue Exception=>e
        nil
      end
    end
  end

  def get_data_hash_from_jerm
    project=@asset_version.projects.first
    project.decrypt_credentials
    downloader=Jerm::DownloaderFactory.create project.title
    resource_type = @asset_version.class.name.split("::")[0] #need to handle versions, e.g. Sop::Version
    begin
      data_hash = downloader.get_remote_data @content_blob.url,project.site_username,project.site_password, resource_type
      data_hash
    rescue Seek::DownloadException=>de
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
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to asset}
        end
        return false
      end
    end


  end

  def asset_object
    begin
      case
        when params[:data_file_id] then
          DataFile.find(params[:data_file_id])
        when params[:model_id] then
          Model.find(params[:model_id])
        when params[:sop_id] then
          Sop.find(params[:sop_id])
        when params[:presentation_id] then
          Presentation.find(params[:presentation_id])
      end
    rescue ActiveRecord::RecordNotFound
      error("Unable to find the asset", "is invalid")
      return false
    end
  end

  def find_and_authorize_content_blob
    content_blob = content_blob_object
    if content_blob.asset.id == @asset.id
      @content_blob = content_blob
    else
      error("You are not authorized to see this content blob", "is invalid")
      return false
    end

  end

  def content_blob_object
    begin
      ContentBlob.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error("Unable to find content blob", "is invalid")
      return false
    end
  end

  def set_asset_version
    begin
      @asset_version = @content_blob.asset.find_version(@content_blob.asset_version)
    rescue Exception=>e
      error("Unable to find asset version", "is invalid")
      return false
    end
  end
end
