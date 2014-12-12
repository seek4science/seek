#require "flash_tool"
class PresentationsController < ApplicationController


  include IndexPager
  include DotGenerator

  include Seek::AssetsCommon

  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_authorize_requested_item, :except => [ :index, :new, :create, :preview,:update_annotations_ajax]
  before_filter :find_display_asset, :only=>[:show, :download]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  def new_version
    if handle_upload_data
      comments=params[:revision_comment]

      respond_to do |format|
        if @presentation.save_as_new_version(comments)
          create_content_blobs
          flash[:notice]="New version uploaded - now on version #{@presentation.version}"
        else
          flash[:error]="Unable to save new version"
        end
        format.html {redirect_to @presentation }
      end
    else
      flash[:error]=flash.now[:error]
      redirect_to @presentation
    end

  end

  # GET /presentations/new
  # GET /presentations/new.xml
  def new
    @presentation=Presentation.new
    @presentation.parent_name = params[:parent_name]
    respond_to do |format|
      if User.logged_in_and_member?
        format.html # new.html.erb
      else
        flash[:error] = "You are not authorized to upload new Presentations. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html { redirect_to presentations_path }
      end
    end
  end

  # POST /presentations
  # POST /presentations.xml
  def create
    if handle_upload_data
      @presentation = Presentation.new(params[:presentation])

      @presentation.policy.set_attributes_with_sharing params[:sharing], @presentation.projects

      update_annotations @presentation
      update_scales @presentation

      assay_ids = params[:assay_ids] || []
        if @presentation.save

          create_content_blobs

          update_relationships(@presentation,params)

          if !@presentation.parent_name.blank?
            render :partial=>"assets/back_to_fancy_parent", :locals=>{:child=>@presentation, :parent_name=>@presentation.parent_name}
          else
            flash[:notice] =  "#{t('presentation')} was successfully uploaded and saved."
            respond_to do |format|
              format.html { redirect_to presentation_path(@presentation) }
            end
          end
          Assay.find(assay_ids).each do |assay|
            if assay.can_edit?
              assay.relate(@presentation)
            end
          end
        else
          respond_to do |format|
            format.html {
              render :action => "new"
            }
          end
        end
    else
      handle_upload_data_failure
    end

  end




  # GET /presentations/1
  # GET /presentations/1.xml
  def show
    # store timestamp of the previous last usage
    @last_used_before_now = @presentation.last_used_at

    @presentation.just_used

    respond_to do |format|
      format.html # show.html.erb
      format.xml
    end
  end

  def edit

  end

 # PUT /presentations/1
  # PUT /presentations/1.xml
  def update
    # remove protected columns (including a "link" to content blob - actual data cannot be updated!)
    if params[:presentation]
      [:contributor_id, :contributor_type, :original_filename, :content_type, :content_blob_id, :created_at, :updated_at, :last_used_at].each do |column_name|
        params[:presentation].delete(column_name)
      end

      # update 'last_used_at' timestamp on the Presentation
      params[:presentation][:last_used_at] = Time.now
    end

    update_annotations @presentation
    update_scales @presentation

    @presentation.attributes = params[:presentation]

    if params[:sharing]
      @presentation.policy_or_default
      @presentation.policy.set_attributes_with_sharing params[:sharing], @presentation.projects
    end

    assay_ids = params[:assay_ids] || []
    respond_to do |format|
      if @presentation.save

        update_relationships(@presentation,params)

        flash[:notice] = "#{t('presentation')} metadata was successfully updated."
        format.html { redirect_to presentation_path(@presentation) }
        # Update new assay_asset
        Assay.find(assay_ids).each do |assay|
          if assay.can_edit?
            assay.relate(@presentation)
          end
        end
        #Destroy AssayAssets that aren't needed
        assay_assets = @presentation.assay_assets
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


end
