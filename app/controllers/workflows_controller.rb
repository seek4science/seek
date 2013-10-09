require 't2flow/model'
require 't2flow/parser'
require 't2flow/dot'

class WorkflowsController < ApplicationController

  include IndexPager
  include Seek::AssetsCommon
  include AssetsCommonExtension

  before_filter :find_workflows, :only => [ :index ]
  before_filter :find_and_auth, :except => [ :index, :new, :create, :preview ]

  include Seek::Publishing::PublishingCommon
  include Seek::BreadCrumbs

  def show

  end

  def run
  end


  def new
    @workflow = Workflow.new
    #@data_file.parent_name = params[:parent_name]
    #@data_file.is_with_sample= params[:is_with_sample]
    @page_title = params[:page_title]
    respond_to do |format|
      if current_user.person.member?
        format.html # new.html.erb
      else
        flash[:error] = "You are not authorized to upload new Workflows. Only members of known projects, institutions or work groups are allowed to create new content."
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
          format.html { redirect_to workflow_path(@workflow) }
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

    if @workflow.save
      update_annotations @workflow

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
      respond_to do |format|
        format.html {
          render :action => "edit"
        }
      end
    end
  end

  def destroy
    @workflow.destroy

    respond_to do |format|
      format.html { redirect_to(workflows_path) }
      format.xml  { head :ok }
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

  private


  def extract_workflow_metadata
    @t2flow = T2Flow::Parser.new.parse(@workflow.content_blob.data_io_object.read)

    @workflow.title = @t2flow.annotations.titles.first
    @workflow.description = @t2flow.annotations.descriptions.first
    # Needs to create ports here
    @workflow.save

    # Manually set workflow content type
    @workflow.content_blob.content_type = 'application/vnd.taverna.t2flow+xml'
    @workflow.content_blob.save
  end

  def find_workflows
    find_assets
    unless params[:category_id].blank?
      @workflows.select { |w| w.category_id == params[:category_id] }
    end
  end

end