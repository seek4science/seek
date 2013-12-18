 require 'zip/zip'
 require 'zip/zipfilesystem'
 require 'libxml'
 require 'bives'

class ModelsController < ApplicationController

  include WhiteListHelper
  include IndexPager
  include DotGenerator
  include Seek::AssetsCommon
  include AssetsCommonExtension

  before_filter :models_enabled?
  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_authorize_requested_item, :except => [ :build,:index, :new, :create,:create_model_metadata,:update_model_metadata,:delete_model_metadata,:request_resource,:preview,:test_asset_url, :update_annotations_ajax]
  before_filter :find_display_asset, :only=>[:show,:download,:execute,:builder,:simulate,:submit_to_jws,:matching_data,:visualise,:export_as_xgmml,:compare_versions]
    
  before_filter :jws_enabled,:only=>[:builder,:simulate,:submit_to_jws]

  before_filter :find_other_version,:only=>[:compare_versions]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  include Bives

  @@model_builder = Seek::JWS::Builder.new

  def find_other_version
    version = params[:other_version]
    @other_version = @model.find_version(version)
  end

  def compare_versions
    blob1 = @display_model.sbml_content_blobs.first
    blob2 = @other_version.sbml_content_blobs.first
    @file1=blob1.filepath
    @file2=blob2.filepath

    json = compare @file1,@file2,["reportHtml","crnJson","json"]
    @crn = JSON.parse(json)["crnJson"]
    @comparison_html = JSON.parse(json)["reportHtml"]
  end

  def export_as_xgmml
      type =  params[:type]
      body = @_request.body.read
      orig_doc = find_xgmml_doc @display_model
      head = orig_doc.to_s.split("<graph").first
      xgmml_doc = head + body

      xgmml_file =  "model_#{@model.id}_version_#{@display_model.version}_export.xgmml"
      tmp_file= Tempfile.new("#{xgmml_file}","#{Rails.root}/tmp/")
      File.open(tmp_file.path,"w") do |tmp|
        tmp.write xgmml_doc
      end

      send_file tmp_file.path, :type=>"#{type}", :disposition=>'attachment',:filename=>xgmml_file
      tmp_file.close
  end

  def visualise
    raise Exception.new("This #{t('model')} does not support Cytoscape") unless @display_model.contains_xgmml?
     # for xgmml file
     doc = find_xgmml_doc @display_model
     # convert " to \" and newline to \n
     #e.g.  "... <att type=\"string\" name=\"canonicalName\" value=\"CHEMBL178301\"/>\n ...  "
     @graph = %Q("#{doc.root.to_s.gsub(/"/, '\"').gsub!("\n",'\n')}")
     render :cytoscape_web,:layout => false
  end

  # GET /models
  # GET /models.xml
  
  def new_version
    if (handle_batch_data nil)
      comments = params[:revision_comment]

      respond_to do |format|
        create_new_version  comments
        create_content_blobs
        create_model_image @model,params[:model_image]
        format.html {redirect_to @model }
      end
    else
      flash[:error]=flash.now[:error]
      redirect_to @model
    end
  end    
  
  def delete_model_metadata
    attribute=params[:attribute]
    if attribute=="model_type"
      delete_model_type params
    elsif attribute=="model_format"
      delete_model_format params
    end
  end
  
  def builder
    saved_file=params[:saved_file]
    error=nil
    supported=false
    begin
      if saved_file
        supported=true
        @params_hash,@attribution_annotations,@saved_file,@objects_hash,@error_keys = @@model_builder.saved_file_builder_content saved_file
      else
        supported = @display_model.is_jws_supported?
        if supported
          content_blob = @display_model.jws_supported_content_blobs.first
          @params_hash,@attribution_annotations,@saved_file,@objects_hash,@error_keys = @@model_builder.builder_content content_blob
        end
      end
    rescue Exception=>e
      error=e
      logger.error "Error submitting to JWS Online OneStop - #{e.message}"
      raise e unless Rails.env=="production"
    end
    
    respond_to do |format|
      if error
        flash[:error]="JWS Online encountered a problem processing this model."
        format.html { redirect_to model_path(@model,:version=>@display_model.version)}
      elsif !supported
        flash[:error]="This #{t('model')} is of neither SBML or JWS Online (Dat) format so cannot be used with JWS Online"
        format.html { redirect_to model_path(@model,:version=>@display_model.version)}        
      else
        format.html
      end
    end
  end    

  def submit_to_jws
    following_action=params.delete("following_action")    
    error=nil

    #FIXME: currently we have to assume that a model with multiple files only contains 1 model file that would be executed on jws online, and only the first one is chosen
    raise Exception.new("JWS Online is not supported for this model") unless @model.is_jws_supported?
    content_blob = @model.jws_supported_content_blobs.first

    begin
      if following_action == "annotate"
        @params_hash,@attribution_annotations,@species_annotations,@reaction_annotations,@search_results,@cached_annotations,@saved_file,@error_keys = Seek::JWS::Annotator.new.annotate params
      else
        @params_hash,@attribution_annotations,@saved_file,@objects_hash,@error_keys = @@model_builder.construct params
      end
    rescue Exception => e
      error=e
      raise e unless Rails.env == "production"
    end

    if (!error && @error_keys.empty?)
      if following_action == "save_new_version"
        model_format=params.delete("saved_model_format") #only used for saving as a new version
        new_version_filename=params.delete("new_version_filename")
        new_version_comments=params.delete("new_version_comments")
        if model_format == "dat"
          url=@@model_builder.saved_dat_download_url @saved_file
        elsif model_format == "sbml"
          url=@@model_builder.sbml_download_url @saved_file
        end
        if url
          downloader=Seek::RemoteDownloader.new
          data_hash = downloader.get_remote_data url
          File.open(data_hash[:data_tmp_path],"r") do |f|
            content_blob = @model.content_blobs.build(:data=>f.read)
          end
          content_blob.content_type=model_format=="sbml" ? "text/xml" : "text/plain"
          content_blob.original_filename=new_version_filename
        end
      end
    end

    respond_to do |format|
      if error
        flash[:error]="JWS Online encountered a problem processing this model."
        format.html { render :action=>"builder" }
      elsif @error_keys.empty? && following_action == "simulate"
        @modelname=@saved_file
        @no_sidebar=true
        format.html {render :simulate}
      elsif @error_keys.empty? && following_action == "annotate"
        format.html {render :action=>"annotator"}
      elsif @error_keys.empty? && following_action == "save_new_version"
        create_new_version(new_version_comments)
        content_blob.asset_version = @model.version
        content_blob.save!
        format.html {redirect_to  model_path(@model,:version=>@model.version) }
      else
        format.html { render :action=>"builder" }
      end      
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

    render :update do |page|
      if error_message.blank?
        page['sbml_model'].value = IO.read(@display_model.sbml_content_blobs.first.filepath).gsub(/\n/, '')
        page['sycamore-form'].submit()
      else
        page.alert(error_message)
      end
    end
  end

 def simulate
    error=nil
    begin
      if @display_model.is_jws_supported?
        @modelname = Seek::JWS::Simulator.new.simulate(@display_model.jws_supported_content_blobs.first)
      end
    rescue Exception=>e
      Rails.logger.error("Problem simulating #{t('model')} on JWS Online #{e}")
      raise e unless Rails.env=="production"
      error=e
    end

    respond_to do |format|
      if error
        flash[:error]="JWS Online encountered a problem processing this model."
        format.html { redirect_to(@model, :version=>@display_model.version) }
      elsif !@display_model.is_jws_supported?
        flash[:error]="This #{t('model')} is of neither SBML or JWS Online (Dat) format so cannot be used with JWS Online"
        format.html { redirect_to(@model, :version=>@display_model.version) }
      else
        @no_sidebar=true
         format.html { render :simulate }
      end
    end
  end
  
  def update_model_metadata
    attribute=params[:attribute]
    if attribute=="model_type"
      update_model_type params
    elsif attribute=="model_format"
      update_model_format params
    end
  end
  
  def delete_model_type params
    id=params[:selected_model_type_id]
    model_type=ModelType.find(id)
    success=false
    if (model_type.models.empty?)
      if model_type.delete
        msg="OK. #{model_type.title} was successfully removed."
        success=true
      else
        msg="ERROR. There was a problem removing #{model_type.title}"
      end
    else
      msg="ERROR - Cannot delete #{model_type.title} because it is in use."
    end
    
    render :update do |page|
      page.replace_html "model_type_selection",collection_select(:model, :model_type_id, ModelType.all, :id, :title, {:include_blank=>"Not specified"},{:onchange=>"model_type_selection_changed();" })
      page.replace_html "model_type_info","#{msg}<br/>"
      info_colour= success ? "green" : "red"
      page << "$('model_type_info').style.color='#{info_colour}';"
      page.visual_effect :appear, "model_type_info"
    end
    
  end
  
  def delete_model_format params
    id=params[:selected_model_format_id]
    model_format=ModelFormat.find(id)
    success=false
    if (model_format.models.empty?)
      if model_format.delete
        msg="OK. #{model_format.title} was successfully removed."
        success=true
      else
        msg="ERROR. There was a problem removing #{model_format.title}"
      end
    else
      msg="ERROR - Cannot delete #{model_format.title} because it is in use."
    end
    
    render :update do |page|
      page.replace_html "model_format_selection",collection_select(:model, :model_format_id, ModelFormat.all, :id, :title, {:include_blank=>"Not specified"},{:onchange=>"model_format_selection_changed();" })
      page.replace_html "model_format_info","#{msg}<br/>"
      info_colour= success ? "green" : "red"
      page << "$('model_format_info').style.color='#{info_colour}';"
      page.visual_effect :appear, "model_format_info"      
    end    
  end

  
  # GET /models/1
  # GET /models/1.xml
  def show
    # store timestamp of the previous last usage
    @last_used_before_now = @model.last_used_at


    @model.just_used
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml
      format.rdf { render :template=>'rdf/show'}
    end
  end
  
  # GET /models/new
  # GET /models/new.xml
  def new    
    @model=Model.new
    @content_blob= ContentBlob.new
    respond_to do |format|
      if current_user.person.member?
        format.html # new.html.erb
      else
        flash[:error] = "You are not authorized to upload new Models. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html { redirect_to models_path }
      end
    end
  end
  
  # GET /models/1/edit
  def edit

  end
  
  # POST /models
  # POST /models.xml
  def create
    if handle_batch_data
      @model = Model.new(params[:model])

      @model.policy.set_attributes_with_sharing params[:sharing], @model.projects

      update_annotations @model
      update_scales @model
      build_model_image @model,params[:model_image]
      assay_ids = params[:assay_ids] || []
      respond_to do |format|
        if @model.save

          create_content_blobs
          # update attributions
          Relationship.create_or_update_attributions(@model, params[:attributions])
          
          # update related publications
          Relationship.create_or_update_attributions(@model, params[:related_publication_ids].collect {|i| ["Publication", i.split(",").first]}, Relationship::RELATED_TO_PUBLICATION) unless params[:related_publication_ids].nil?
          
          #Add creators
          AssetsCreator.add_or_update_creator_list(@model, params[:creators])
          
          flash[:notice] = "#{t('model')} was successfully uploaded and saved."
          format.html { redirect_to model_path(@model) }
          Assay.find(assay_ids).each do |assay|
            if assay.can_edit?
              assay.relate(@model)
            end
          end
        else
          format.html {
            render :action => "new"
          }
        end
      end
    end
    
  end

  # PUT /models/1
  # PUT /models/1.xml
  def update
    # remove protected columns (including a "link" to content blob - actual data cannot be updated!)
    if params[:model]
      [:contributor_id, :contributor_type, :original_filename, :content_type, :content_blob_id, :created_at, :updated_at, :last_used_at].each do |column_name|
        params[:model].delete(column_name)
      end

      # update 'last_used_at' timestamp on the Model
      params[:model][:last_used_at] = Time.now
    end

    update_annotations @model
    update_scales @model
    publication_params = params[:related_publication_ids].nil? ? [] : params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first] }

    @model.attributes = params[:model]

    if params[:sharing]
      @model.policy_or_default
      @model.policy.set_attributes_with_sharing params[:sharing], @model.projects
    end

    assay_ids = params[:assay_ids] || []
    respond_to do |format|
      if @model.save

        # update attributions
        Relationship.create_or_update_attributions(@model, params[:attributions])

        # update related publications
        Relationship.create_or_update_attributions(@model, publication_params, Relationship::RELATED_TO_PUBLICATION)

        #update creators
        AssetsCreator.add_or_update_creator_list(@model, params[:creators])

        flash[:notice] = "#{t('model')} metadata was successfully updated."
        format.html { redirect_to model_path(@model) }
        # Update new assay_asset
        Assay.find(assay_ids).each do |assay|
          if assay.can_edit?
            assay.relate(@model)
          end
        end
        #Destroy AssayAssets that aren't needed
        assay_assets = @model.assay_assets
        assay_assets.each do |assay_asset|
          if assay_asset.assay.can_edit? and !assay_ids.include?(assay_asset.assay_id.to_s)
            AssayAsset.destroy(assay_asset.id)
          end
        end
      else
        format.html {
          render :action => "edit"
        }
      end
    end
  end
  
  # DELETE /models/1
  # DELETE /models/1.xml
  def destroy
    @model.destroy
    
    respond_to do |format|
      format.html { redirect_to(models_path) }
      format.xml  { head :ok }
    end
  end

  def preview
    
    element = params[:element]
    model = Model.find_by_id(params[:id])
    
    render :update do |page|
      if model.try :can_view?
        page.replace_html element,:partial=>"assets/resource_preview",:locals=>{:resource=>model}
      else
        page.replace_html element,:text=>"Nothing is selected to preview."
      end
    end
  end
  
  def request_resource
    resource = Model.find(params[:id])
    details = params[:details]
    
    Mailer.request_resource(current_user,resource,details,base_host).deliver
    
    render :update do |page|
      page[:requesting_resource_status].replace_html "An email has been sent on your behalf to <b>#{resource.managers.collect{|m| m.name}.join(", ")}</b> requesting the file <b>#{h(resource.title)}</b>."
    end
  end

  def matching_data
    #FIXME: should use the correct version
    @matching_data_items = @model.matching_data_files

    #filter authorization
    ids = @matching_data_items.collect &:primary_key
    data_files = DataFile.find_all_by_id(ids)
    authorised_ids = DataFile.authorize_asset_collection(data_files,"view").collect &:id
    @matching_data_items = @matching_data_items.select{|mdf| authorised_ids.include?(mdf.primary_key.to_i)}

    flash.now[:notice]="#{@matching_data_items.count} #{t('data_file').pluralize} found that may be relevant to this #{t('model')}"
    respond_to do |format|
      format.html
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
  
  def default_items_per_page
    return 2
  end

  def translate_action action
    action="download" if action == "simulate"
    action="edit" if ["submit_to_jws","builder"].include?(action)
    action="view" if ["matching_data"].include?(action)
    super action
  end
  
  def jws_enabled
    unless Seek::Config.jws_enabled
      respond_to do |format|
        flash[:error] = "Interaction with JWS Online is currently disabled"
        format.html { redirect_to model_path(@model,:version=>@display_model.version) }
      end
      return false
    end
  end

   def build_model_image model_object, params_model_image
      unless params_model_image.blank? || params_model_image[:image_file].blank?

      # the creation of the new Avatar instance needs to have only one parameter - therefore, the rest should be set separately
      @model_image = ModelImage.new(params_model_image)
      @model_image.model_id = model_object.id
      @model_image.content_type = params_model_image[:image_file].content_type
      @model_image.original_filename = params_model_image[:image_file].original_filename
      model_object.model_image = @model_image
    end

   end

    def find_xgmml_doc model
      xgmml_content_blob = model.xgmml_content_blobs.first
      file = open(xgmml_content_blob.filepath)
      doc = LibXML::XML::Parser.string(file.read).parse
      doc
    end

  def create_model_image model_object, params_model_image
    build_model_image model_object, params_model_image
    model_object.save(:validate=>false)
    latest_version = model_object.latest_version
    latest_version.model_image_id = model_object.model_image_id
    latest_version.save
  end
end
