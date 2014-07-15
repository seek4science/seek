class SopsController < ApplicationController
  
  include IndexPager
  include DotGenerator

  include Seek::AssetsCommon
  include Seek::UploadHandling
  
  #before_filter :login_required
  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_authorize_requested_item, :except => [ :index, :new, :create, :request_resource,:preview, :test_asset_url, :update_annotations_ajax]
  before_filter :find_display_asset, :only=>[:show, :download]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  def new_version
    if handle_upload_data
      comments=params[:revision_comment]


      respond_to do |format|
        if @sop.save_as_new_version(comments)

          create_content_blobs

          #Duplicate experimental conditions
          conditions = @sop.find_version(@sop.version - 1).experimental_conditions
          conditions.each do |con|
            new_con = con.dup
            new_con.sop_version = @sop.version
            new_con.save
          end
          flash[:notice]="New version uploaded - now on version #{@sop.version}"
        else
          flash[:error]="Unable to save new version"          
        end
        format.html {redirect_to @sop }
      end
    else
      flash[:error]=flash.now[:error] 
      redirect_to @sop
    end
    
  end

  # GET /sops/1
  def show
    # store timestamp of the previous last usage
    @last_used_before_now = @sop.last_used_at
    
    # update timestamp in the current SOP record 
    # (this will also trigger timestamp update in the corresponding Asset)
    if @sop.instance_of?(Sop)
      @sop.just_used
    end  
    
    respond_to do |format|
      format.html
      format.xml
      format.rdf { render :template=>'rdf/show'}
    end
  end

  # GET /sops/new
  def new
    @sop=Sop.new
    respond_to do |format|
      if User.logged_in_and_member?
        format.html # new.html.erb
      else
        flash[:error] = "You are not authorized to upload new SOPs. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html { redirect_to sops_path }
      end
    end
  end
  
  # GET /sops/1/edit
  def edit
    
  end

  # POST /sops
  def create    

    if handle_upload_data
      @sop = Sop.new(params[:sop])
      @sop.policy.set_attributes_with_sharing params[:sharing], @sop.projects

      update_annotations @sop
      update_scales @sop
      assay_ids = params[:assay_ids] || []
      respond_to do |format|
        if @sop.save

          create_content_blobs

          # update attributions
          Relationship.create_or_update_attributions(@sop, params[:attributions])
          
          #Add creators
          AssetsCreator.add_or_update_creator_list(@sop, params[:creators])
          
          flash[:notice] = "#{t('sop')} was successfully uploaded and saved."
          format.html { redirect_to sop_path(@sop) }
          Assay.find(assay_ids).each do |assay|
            if assay.can_edit?
              assay.relate(@sop)
            end
          end
        else
          format.html { 
            render :action => "new" 
          }
        end
      end
    else
      handle_upload_data_failure
    end
  end
  
  
  # PUT /sops/1
  def update
    # remove protected columns (including a "link" to content blob - actual data cannot be updated!)
    if params[:sop]
      [:contributor_id, :contributor_type, :original_filename, :content_type, :content_blob_id, :created_at, :updated_at, :last_used_at].each do |column_name|
        params[:sop].delete(column_name)
      end
      
      # update 'last_used_at' timestamp on the SOP
      params[:sop][:last_used_at] = Time.now
    end

    update_annotations @sop
    update_scales @sop

    assay_ids = params[:assay_ids] || []

    @sop.attributes = params[:sop]

    if params[:sharing]
      @sop.policy_or_default
      @sop.policy.set_attributes_with_sharing params[:sharing], @sop.projects
    end

    respond_to do |format|
      if @sop.save
        # update attributions
        Relationship.create_or_update_attributions(@sop, params[:attributions])
        
        #update authors
        AssetsCreator.add_or_update_creator_list(@sop, params[:creators])
        
        flash[:notice] = "#{t('sop')} metadata was successfully updated."
        format.html { redirect_to sop_path(@sop) }
        # Update new assay_asset
        Assay.find(assay_ids).each do |assay|
          if assay.can_edit?
            assay.relate(@sop)
          end
        end

        #Destroy AssayAssets that aren't needed
        assay_assets = @sop.assay_assets
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
  
  # DELETE /sops/1
  def destroy
    @sop.destroy
    
    respond_to do |format|
      format.html { redirect_to(sops_path) }
    end
  end

  
  def preview
    
    element=params[:element]
    sop=Sop.find_by_id(params[:id])
    
    render :update do |page|
      if sop.try :can_view?
        page.replace_html element,:partial=>"assets/resource_preview",:locals=>{:resource=>sop}
      else
        page.replace_html element,:text=>"Nothing is selected to preview."
      end
    end
  end
  
  def request_resource
    resource = Sop.find(params[:id])
    details = params[:details]
    
    Mailer.request_resource(current_user,resource,details,base_host).deliver
    
    render :update do |page|
      page[:requesting_resource_status].replace_html "An email has been sent on your behalf to <b>#{resource.managers.collect{|m| m.name}.join(", ")}</b> requesting the file <b>#{h(resource.title)}</b>."
    end
  end
end
