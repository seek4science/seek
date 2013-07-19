#require "flash_tool"
class PresentationsController < ApplicationController


  include IndexPager
  include DotGenerator

  include Seek::AssetsCommon
  include AssetsCommonExtension

  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_auth, :except => [ :index, :new, :create, :preview,:update_annotations_ajax]
  before_filter :find_display_asset, :only=>[:show, :download]

  include Seek::Publishing::GatekeeperPublish
  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  def new_version
    if (handle_data nil)
      comments=params[:revision_comment]

      #@presentation.content_blob = ContentBlob.new(:tmp_io_object => @tmp_io_object, :url=>@data_url)
      #@presentation.content_type = params[:presentation][:content_type]
      #@presentation.original_filename = params[:presentation][:original_filename]


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
    respond_to do |format|
      if current_user.person.member?
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
    if handle_data
      @presentation = Presentation.new(params[:presentation])

      @presentation.policy.set_attributes_with_sharing params[:sharing], @presentation.projects

      update_annotations @presentation
      assay_ids = params[:assay_ids] || []
      respond_to do |format|
        if @presentation.save

          create_content_blobs

          # update attributions
          Relationship.create_or_update_attributions(@presentation, params[:attributions])

          # update related publications
          Relationship.create_or_update_attributions(@presentation, params[:related_publication_ids].collect {|i| ["Publication", i.split(",").first]}, Relationship::RELATED_TO_PUBLICATION) unless params[:related_publication_ids].nil?

          #Add creators
          AssetsCreator.add_or_update_creator_list(@presentation, params[:creators])

          flash[:notice] = "#{t('presentation')} was successfully uploaded and saved."
          format.html { redirect_to presentation_path(@presentation) }
          Assay.find(assay_ids).each do |assay|
            if assay.can_edit?
              assay.relate(@presentation)
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




  # GET /presentations/1
  # GET /presentations/1.xml
  def show
    # store timestamp of the previous last usage
    @last_used_before_now = @presentation.last_used_at

    @presentation.just_used

    respond_to do |format|
      format.html # show.html.erb
      format.xml
      format.svg { render :text=>to_svg(@presentation,params[:deep]=='true',@presentation)}
      format.dot { render :text=>to_dot(@presentation,params[:deep]=='true',@presentation)}
      format.png { render :text=>to_png(@presentation,params[:deep]=='true',@presentation)}
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

    publication_params    = params[:related_publication_ids].nil?? [] : params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first]}

    update_annotations @presentation

    @presentation.attributes = params[:presentation]

    if params[:sharing]
      @presentation.policy_or_default
      @presentation.policy.set_attributes_with_sharing params[:sharing], @presentation.projects
    end

    assay_ids = params[:assay_ids] || []
    respond_to do |format|
      if @presentation.save

        # update attributions
        Relationship.create_or_update_attributions(@presentation, params[:attributions])

        # update related publications
        Relationship.create_or_update_attributions(@presentation,publication_params, Relationship::RELATED_TO_PUBLICATION)

        #update creators
        AssetsCreator.add_or_update_creator_list(@presentation, params[:creators])

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

  # DELETE /presentations/1
  # DELETE /presentations/1.xml
  def destroy
    @presentation.destroy

    respond_to do |format|
      format.html { redirect_to(presentations_path) }
      format.xml  { head :ok }
    end
  end

  def preview

    element = params[:element]
    presentation = Presentation.find_by_id(params[:id])

    render :update do |page|
      if presentation.try :can_view?
        page.replace_html element,:partial=>"assets/resource_preview",:locals=>{:resource=>presentation}
      else
        page.replace_html element,:text=>"Nothing is selected to preview."
      end
    end
  end

end
