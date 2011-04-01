class SopsController < ApplicationController  
  
  include IndexPager
  include DotGenerator
  include Seek::AssetsCommon  
  
  before_filter :login_required
  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_auth, :except => [ :index, :new, :create, :request_resource,:preview, :test_asset_url, :update_tags_ajax]
  before_filter :find_display_sop, :only=>[:show,:download]
  
  
  def new_version
    if (handle_data nil)      
      comments=params[:revision_comment]
      
      @sop.content_blob = ContentBlob.new(:tmp_io_object => @tmp_io_object, :url=>@data_url)
      @sop.content_type = params[:sop][:content_type]
      @sop.original_filename = params[:sop][:original_filename]
      
      conditions = @sop.experimental_conditions
      respond_to do |format|
        if @sop.save_as_new_version(comments)
          #Duplicate experimental conditions
          conditions.each do |con|
            new_con = con.clone
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
      @sop.last_used_at = Time.now
      @sop.save_without_timestamping
    end  
    
    respond_to do |format|
      format.html
      format.xml
      format.svg { render :text=>to_svg(@sop,params[:deep]=='true',@sop)}
      format.dot { render :text=>to_dot(@sop,params[:deep]=='true',@sop)}
      format.png { render :text=>to_png(@sop,params[:deep]=='true',@sop)}
    end
  end
  
  # GET /sops/1/download
  def download
    # update timestamp in the current SOP record 
    # (this will also trigger timestamp update in the corresponding Asset)
    @sop.last_used_at = Time.now
    @sop.save_without_timestamping
    
    handle_download @display_sop
  end
  
  # GET /sops/new
  def new
    @sop=Sop.new
    respond_to do |format|
      if Authorization.is_member?(current_user.person_id, nil, nil)
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

    if handle_data            
      @sop = Sop.new(params[:sop])
      @sop.contributor=current_user
      @sop.content_blob = ContentBlob.new(:tmp_io_object => @tmp_io_object,:url=>@data_url)

      update_tags @sop
      assay_ids = params[:assay_ids] || []
      respond_to do |format|
        if @sop.save
          # the SOP was saved successfully, now need to apply policy / permissions settings to it
          policy_err_msg = Policy.create_or_update_policy(@sop, current_user, params)
          
          # update attributions
          Relationship.create_or_update_attributions(@sop, params[:attributions])
          
          #Add creators
          AssetsCreator.add_or_update_creator_list(@sop, params[:creators])
          
          if policy_err_msg.blank?
            flash[:notice] = 'SOP was successfully uploaded and saved.'
            format.html { redirect_to sop_path(@sop) }
          else
            flash[:notice] = "SOP was successfully created. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
            format.html { redirect_to :controller => 'sops', :id => @sop, :action => "edit" }
          end
          assay_ids.each do |id|
              @assay = Assay.find(id)
              @assay.relate(@sop)
          end
        else
          format.html { 
            render :action => "new" 
          }
        end
      end
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

    update_tags @sop
    assay_ids = params[:assay_ids] || []
    respond_to do |format|
      if @sop.update_attributes(params[:sop])
        # the SOP was updated successfully, now need to apply updated policy / permissions settings to it
        policy_err_msg = Policy.create_or_update_policy(@sop, current_user, params)
        
        # update attributions
        Relationship.create_or_update_attributions(@sop, params[:attributions])
        
        #update authors
        AssetsCreator.add_or_update_creator_list(@sop, params[:creators])
        
        if policy_err_msg.blank?
          flash[:notice] = 'SOP metadata was successfully updated.'
          format.html { redirect_to sop_path(@sop) }
        else
          flash[:notice] = "SOP metadata was successfully updated. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
          format.html { redirect_to :controller => 'sops', :id => @sop, :action => "edit" }
        end
        # Update new assay_asset
        assay_ids.each do |id|
          @assay = Assay.find(id)
          @assay.relate(@sop)
        end
        #Destroy AssayAssets that aren't needed
        assay_assets = AssayAsset.find_all_by_asset_id(@sop.id)
        assay_assets.each do |assay_asset|
          flag = false
          assay_ids.each do |id|
            if assay_asset.assay_id.to_s == id
              flag = true
            end
          end
          if flag == false
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
    
    Mailer.deliver_request_resource(current_user,resource,details,base_host)
    
    render :update do |page|
      page[:requesting_resource_status].replace_html "An email has been sent on your behalf to <b>#{resource.managers.collect{|m| m.name}.join(", ")}</b> requesting the file <b>#{h(resource.title)}</b>."
    end
  end

  protected
  
  def find_display_sop
    if @sop
      @display_sop = params[:version] ? @sop.find_version(params[:version]) : @sop.latest_version
    end
  end
  
end
