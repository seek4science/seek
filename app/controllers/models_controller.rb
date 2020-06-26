require 'libxml'
require 'bives'

class ModelsController < ApplicationController
  include Seek::IndexPager
  include Seek::AssetsCommon

  before_action :models_enabled?
  before_action :find_assets, :only => [:index]
  before_action :find_and_authorize_requested_item, :except => [:build, :index, :new, :create, :preview, :test_asset_url, :update_annotations_ajax]
  before_action :find_display_asset, :only => [:show, :download, :execute, :visualise, :export_as_xgmml, :compare_versions]
  before_action :find_other_version, :only => [:compare_versions]

  include Seek::Jws::Simulator
  include Seek::Publishing::PublishingCommon
  include Seek::BreadCrumbs
  include Bives
  include Seek::Doi::Minting

  include Seek::IsaGraphExtensions

  api_actions :index, :show, :create, :update, :destroy

  def find_other_version
    version = params[:other_version]
    @other_version = @model.find_version(version)
    if version.nil? || @other_version.nil?
      flash[:error] = "The other version to compare with was not specified, or it does not exist"
      redirect_to model_path(@model, :version => @display_model.version)
    end
  end

  def compare_versions
    select_blobs_for_comparison
    if @blob1 && @blob2
      begin
        json = compare @blob1.filepath, @blob2.filepath, ["reportHtml", "crnJson", "json", "SBML"]
        @crn = JSON.parse(json)["crnJson"]
        @comparison_html = JSON.parse(json)["reportHtml"]
      rescue StandardError => e
        raise e unless Rails.env.production?
        flash.now[:error]="there was an error trying to compare the two versions - #{e.message}"
      end
    else
      flash.now[:error]="One of the version files could not be found, or you are not authorized to examine it"
    end
  end

  def select_blobs_for_comparison
    blobs = {:other_file_id=>@other_version.sbml_content_blobs,:file_id=>@display_model.sbml_content_blobs}.collect do |param_key,blobs|
      params[param_key] ? blobs.find { |blob| blob.id.to_s == params[param_key] } : blobs.first
    end
    @blob1=blobs[0]
    @blob2=blobs[1]
  end

  def export_as_xgmml
    type = params[:type]
    body = @_request.body.read
    orig_doc = find_xgmml_doc @display_model
    head = orig_doc.to_s.split("<graph").first
    xgmml_doc = head + body

    xgmml_file = "model_#{@model.id}_version_#{@display_model.version}_export.xgmml"
    tmp_file= Tempfile.new("#{xgmml_file}", "#{Rails.root}/tmp/")
    File.open(tmp_file.path, "w") do |tmp|
      tmp.write xgmml_doc
    end

    send_file tmp_file.path, :type => "#{type}", :disposition => 'attachment', :filename => xgmml_file
    tmp_file.close
  end

  def visualise
    raise Exception.new("This #{t('model')} does not support Cytoscape") unless @display_model.contains_xgmml?
    # for xgmml file
    doc = find_xgmml_doc @display_model
    # convert " to \" and newline to \n
    #e.g.  "... <att type=\"string\" name=\"canonicalName\" value=\"CHEMBL178301\"/>\n ...  "
    @graph = %Q("#{doc.root.to_s.gsub(/"/, '\"').gsub!("\n", '\n')}")
    render :cytoscape_web, :layout => false
  end

  # GET /models
  # GET /models.xml

  def new_version
    if handle_upload_data(true)
      comments = params[:revision_comments]

      respond_to do |format|
        create_new_version comments
        create_model_image @model, model_image_params  if model_image_present?
        format.html { redirect_to @model }
      end
    else
      flash[:error]=flash.now[:error]
      redirect_to @model
    end
  end

  def submit_to_sycamore
    @model = Model.find_by_id(params[:id])
    @display_model = @model.find_version(params[:version])
    error_message = nil
    if !Seek::Config.sycamore_enabled
      error_message = "Interaction with Sycamore is currently disabled"
    elsif !@model.can_download? && (params[:code].nil? || (params[:code] && !@model.auth_by_code?(params[:code])))
      error_message = "You are not allowed to simulate this #{t('model')} with Sycamore"
    end

    if error_message.blank?
      respond_to do |format|
        format.js
      end
    else
      render js: "alert(#{error_message})"
    end
  end

  # PUT /models/1
  # PUT /models/1.xml
  def update
    update_annotations(params[:tag_list], @model)
    update_sharing_policies @model
    update_relationships(@model, params)
    respond_to do |format|
      if @model.update_attributes(model_params)
        flash[:notice] = "#{t('model')} metadata was successfully updated."
        format.html { redirect_to model_path(@model) }
        format.json {render json: @model, include: [params[:include]]}
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@model), status: :unprocessable_entity }
      end
    end
  end

  protected

  def create_new_version comments
    if @model.save_as_new_version(comments)
      flash[:notice]="New version uploaded - now on version #{@model.version}"
    else
      flash[:error]="Unable to save new version"
    end
  end

  def jws_enabled
    unless Seek::Config.jws_enabled
      respond_to do |format|
        flash[:error] = "Interaction with JWS Online is currently disabled"
        format.html { redirect_to model_path(@model, :version => @display_model.version) }
      end
      return false
    end
  end

  def build_model_image model_object, params_model_image
    # the creation of the new Avatar instance needs to have only one parameter - therefore, the rest should be set separately
    @model_image = model_object.build_model_image(params_model_image.merge(
        model: model_object,
        content_type: params_model_image[:image_file].content_type,
        original_filename: params_model_image[:image_file].original_filename))
  end

  def find_xgmml_doc model
    xgmml_content_blob = model.xgmml_content_blobs.first
    file = open(xgmml_content_blob.filepath)
    doc = LibXML::XML::Parser.string(file.read).parse
    doc
  end

  def create_model_image model_object, params_model_image
    build_model_image model_object, params_model_image if model_image_present?
    model_object.save(:validate => false)
    latest_version = model_object.latest_version
    latest_version.model_image_id = model_object.model_image_id
    latest_version.save
  end

  private

  def model_params
    params.require(:model).permit(:imported_source, :imported_url, :title, :description, { project_ids: [] }, :license,
                                  :model_type_id, :model_format_id, :recommended_environment_id, :organism_id,
                                  :other_creators,
                                  { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                  { creator_ids: [] }, { assay_assets_attributes: [:assay_id] }, { scales: [] },
                                  { scale_extra_params: [] }, { publication_ids: [] },
                                  discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

  alias_method :asset_params, :model_params

  def model_image_params
    params.require(:model_image).permit(:image_file)
  end
end
