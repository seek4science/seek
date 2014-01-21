require 't2flow/model'
require 't2flow/parser'
require 't2flow/dot'

class WorkflowsController < ApplicationController

  include IndexPager
  include Seek::AssetsCommon
  include AssetsCommonExtension

  before_filter :find_and_filter_workflows, :only => [ :index ]
  before_filter :find_and_auth, :except => [ :index, :new, :create, :preview ]
  before_filter :find_display_asset, :only=>[:show, :download, :run]
  before_filter :check_runs_before_destroy, :only => :destroy

  include Seek::Publishing::PublishingCommon
  include Seek::BreadCrumbs

  def show

  end

  def temp_link
    workflow = Workflow.find(params[:id])
    respond_to do |format|
      format.html { render :partial => "sharing/temp_link", :locals => { :workflow => workflow } }
    end
  end

  def run
  end


  def new
    @workflow = Workflow.new(:category_id => params[:category_id])
    #@data_file.parent_name = params[:parent_name]
    #@data_file.is_with_sample= params[:is_with_sample]
    @page_title = params[:page_title]
    respond_to do |format|
      if current_user.person.member?
        format.html # new.html.erb
      else
        flash[:error] = "You are not authorized to upload new workflows. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html { redirect_to workflows_path }
      end
    end
  end

  def edit

  end

  def create
    if handle_data

      @workflow = Workflow.new params[:workflow]
      @workflow.policy.set_attributes_with_sharing params[:sharing], @workflow.projects
      if @workflow.save
        update_annotations @workflow

        create_content_blobs

        # Check if the uploaded file contains a Taverna workflow
        if !taverna_workflow?(@workflow.content_blob.data_io_object)
          @workflow.destroy
          respond_to do |format|
            flash[:error] = 'The uploaded file does not appear to be a Taverna workflow.'
            format.html {redirect_to new_workflow_path}
          end
          return
        end

        # Pull title and from t2flow
        extract_workflow_metadata

        # update attributions
        Relationship.create_or_update_attributions(@workflow, params[:attributions])

        # update related publications
        Relationship.create_or_update_attributions(@workflow, params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first] }, Relationship::RELATED_TO_PUBLICATION) unless params[:related_publication_ids].nil?

        #Add creators
        AssetsCreator.add_or_update_creator_list(@workflow, params[:creators])
        respond_to do |format|
          flash[:notice] = "#{t('workflow')} was successfully uploaded and saved." if flash.now[:notice].nil?
          format.html { redirect_to describe_ports_workflow_path(@workflow) }
        end
      else
        respond_to do |format|
          format.html {
            render :action => "new"
          }
        end
      end
    end
  end

  def update
    if params[:workflow]
      [:contributor_id, :contributor_type, :original_filename, :content_type, :content_blob_id, :created_at, :updated_at, :last_used_at].each do |column_name|
        params[:workflow].delete(column_name)
      end

      params[:workflow][:last_used_at] = Time.now
    end

    publication_params    = params[:related_publication_ids].nil?? [] : params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first]}

    @workflow.attributes = params[:workflow]

     if params[:sharing]
       @workflow.policy_or_default
       @workflow.policy.set_attributes_with_sharing params[:sharing], @workflow.projects
     end

    if @workflow.save && !params[:sharing_form]
      update_annotations @workflow

      extract_workflow_metadata

      # update attributions
      Relationship.create_or_update_attributions(@workflow, params[:attributions])

      # update related publications
      Relationship.create_or_update_attributions(@workflow, publication_params, Relationship::RELATED_TO_PUBLICATION)

      #Add creators
      AssetsCreator.add_or_update_creator_list(@workflow, params[:creators])

      respond_to do |format|
        flash[:notice] = "#{t('workflow')} was successfully updated." if flash.now[:notice].nil?
        format.html { redirect_to workflow_path(@workflow) }
      end
    else
      if @workflow.save && params[:sharing_form]
        flash[:notice] = "Sharing link has been #{!@workflow.special_auth_codes.empty? ? "enabled" : "disabled"}" if flash.now[:notice].nil?
      end
      respond_to do |format|
        format.html {
          render :action => "edit"
        }
      end
    end
  end

  def destroy
    if @workflow.runs.empty?
      @workflow.destroy
      respond_to do |format|
        format.html { redirect_to(workflows_path) }
        format.xml  { head :ok }
      end
    else
      flash[:error] = "This workflow has #{@workflow.runs.size} runs associated with it and so cannot be deleted. Please make it private instead."
      respond_to do |format|
        format.html { redirect_to(workflows_path) }
        format.xml  { head :forbidden }
      end
    end
  end

  def preview
    element=params[:element]
    workflow=Workflow.find_by_id(params[:id])

    render :update do |page|
      if workflow.try :can_view?
        page.replace_html element,:partial=>"assets/resource_preview",:locals=>{:resource=>workflow}
      else
        page.replace_html element,:text=>"Nothing is selected to preview."
      end
    end
  end

  def new_version
    if (handle_data nil)
      comments=params[:revision_comment]

      respond_to do |format|
        if @workflow.save_as_new_version(comments)
          create_content_blobs

          # Check if the uploaded file contains a Taverna workflow
          if !taverna_workflow?(@workflow.content_blob.data_io_object)
            @workflow.destroy
            flash[:error] = 'The uploaded file does not appear to be a Taverna workflow.'
            format.html {redirect_to :back}
            return
          end

          extract_workflow_metadata

          flash[:notice] = "New version uploaded - now on version #{@workflow.version}"
          format.html { redirect_to describe_ports_workflow_path(@workflow) }
        else
          flash[:error] = "Unable to save new version"
          format.html {redirect_to @workflow }
        end
      end
    else
      flash[:error]=flash.now[:error]
      redirect_to @workflow
    end
  end

  def describe_ports
    if @workflow.input_ports.empty? && @workflow.output_ports.empty?
      @workflow.t2flow.sources.each do |source|
        @workflow.input_ports.build(:name => source.name,
                                    :description => (source.descriptions || []).last,
                                    :example_value => (source.example_values || []).last,
                                    :port_type_id => WorkflowInputPortType.first.id)
      end
      @workflow.t2flow.sinks.each do |sink|
        @workflow.output_ports.build(:name => sink.name,
                                    :description => (sink.descriptions || []).last,
                                    :example_value => (sink.example_values || []).last,
                                    :port_type_id => WorkflowOutputPortType.first.id)
      end
    end
  end

  private

  # Checks if the uploaded file looks like a Taverna workflow
  def taverna_workflow?(file)
    first_couple_of_bytes = IO.read(file, 100) # returns string
    if first_couple_of_bytes.include?('http://taverna.sf.net/2008/xml/t2flow') # This looks like a Taverna workflow
      return true
    else
      return false
    end
  end

  def extract_workflow_metadata
    @t2flow = T2Flow::Parser.new.parse(@workflow.content_blob.data_io_object.read)

    @workflow.title = @t2flow.annotations.titles.last
    @workflow.description = @t2flow.annotations.descriptions.last
    # Needs to create ports here
    @workflow.save

    # Manually set workflow content type
    @workflow.content_blob.content_type = 'application/vnd.taverna.t2flow+xml'
    @workflow.content_blob.save
  end

  def find_and_filter_workflows
    find_assets

    # Has the user cleared the search box? - return all items.
    uploader = params[:uploader_id] || []
    category = params[:category_id] || []
    search_query = params[:query] || []
    search_included = (params[:commit] == 'Clear') ? false : true

    return @workfows if search_included == false && category.empty? && uploader.empty?

    # Filter by uploader and category
    filter_results = Workflow.where(true)
    filter_results = filter_results.by_category(params[:category_id].to_i) unless params[:category_id].blank?
    filter_results = filter_results.by_uploader(params[:uploader_id].to_i) unless params[:uploader_id].blank?
    @workflows = @workflows & filter_results

    # Filter by search results
    unless params[:query].blank? || search_included == false
      search_results = Workflow.search do |query|
        query.keywords(search_query.downcase)
      end.results
      @workflows = @workflows & search_results
    end

    @workflows
  end

  def check_runs_before_destroy
    unless @workflow.runs.empty?
      flash[:error] = "There are #{@workflow.runs.count} runs associated with this workflow and so it may not be deleted."
      redirect_to @workflow
    end
  end

end