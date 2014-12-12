class SopsController < ApplicationController
  
  include IndexPager
  include DotGenerator

  include Seek::AssetsCommon

  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_authorize_requested_item, :except => [ :index, :new, :create, :request_resource,:preview, :test_asset_url, :update_annotations_ajax]
  before_filter :find_display_asset, :only=>[:show, :download]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs
  include Seek::DataciteDoi

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

      respond_to do |format|
        if @sop.save
          create_content_blobs
          update_relationships(@sop,params)
          update_assay_assets(@sop,params[:assay_ids])
          flash[:notice] = "#{t('sop')} was successfully uploaded and saved."
          format.html { redirect_to sop_path(@sop) }
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
    sop_params=filter_protected_update_params(params[:sop])
    
    update_annotations @sop
    update_scales @sop

    @sop.attributes = sop_params

    if params[:sharing]
      @sop.policy_or_default
      @sop.policy.set_attributes_with_sharing params[:sharing], @sop.projects
    end

    respond_to do |format|
      if @sop.save
        update_relationships(@sop,params)
        update_assay_assets(@sop,params[:assay_ids])
        flash[:notice] = "#{t('sop')} metadata was successfully updated."
        format.html { redirect_to sop_path(@sop) }

      else
        format.html { 
          render :action => "edit" 
        }
      end
    end
  end
 

end
