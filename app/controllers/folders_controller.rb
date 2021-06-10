

class FoldersController < ApplicationController
  before_action :login_required
  before_action :check_project
  before_action :browser_enabled
  before_action :get_folder, :only=>[:create_folder, :destroy, :display_contents,:remove_asset]
  before_action :get_folders,:only=>[:index,:move_asset_to,:create_folder]
  before_action :get_asset, :only=>[:move_asset_to,:remove_asset]

  def show
    puts "show"
    @project = Project.find(params[:id])
    @folders = project_folders
    # For creating new investigation and study in Project view page
    @investigation = Investigation.new({})
    @study = Study.new({})
    @assay = Assay.new({})
    @sourceTypes = load_source_types

    respond_to do |format|
      format.html
    end
  end

  def index
    puts "index"
    respond_to do |format|
      format.html
    end
  end

  def render_sharing_form
    begin
      if params[:type] == "investigation"
        @investigation = Investigation.find(params[:id]) 
      elsif params[:type] == "study"
        @study = Study.find(params[:id]) 
      elsif params[:type] == "assay"
        @assay = Assay.find(params[:id]) 
        @sop = @assay.sops.first
      end
    rescue Exception => e
      error = e.message
    end
    respond_to do |format|
      if error
        format.js { render plain: error, status: :unprocessable_entity }
      else
        format.js
      end
    end
  end


  # GET
  def flowchart
    puts "flowchart"
    begin
      flowchart = Flowchart.where(study_id: params[:study_id]).first
      study = Study.where(id: params[:study_id]).first
      assay_ids = study.assays.select { |a| a.sops.length > 0 } .collect{|a| a.id.to_s}
      # assay_ids = assays.collect{|u|u.id.to_s}
      if flowchart.nil?
        # items = assays.map.with_index {|n,i| {id: n.id.to_s, left: i*180+40, top: i%2==0 ? 50 : 100}}
        return render json: {error:"no flowchart" }, status: :unprocessable_entity
      else
        #Filters items that don't exist anymore
        items = JSON.parse(flowchart.items).map{|n| n if assay_ids.include?(n["id"]) || n["id"].blank?}.compact
      end
      operators = items.map {|item| create_operator(item,study)}
      links = items.drop(1).map.with_index {|item, i| create_link(i)}
      flowchart_data = {operators: operators, links: links, operatorTypes:{}}
      # render json: {status: :ok, data: flowchart_data }
    rescue Exception => e
      error = e.message
    end
    if error
      render json: {status: :unprocessable_entity, error: error  }
    else
      render json: {status: :ok, data: flowchart_data }
    end
  end

  # POST >> TO-DO: PUT flowchart
  def update_flowchart
    puts "update_flowchart"
    is_new = false
    f = Flowchart.find_or_create_by(study_id: params[:flowchart][:study_id]) do |u|
      is_new = true
    end
    if f.update_attributes(flowchart_params)
      render json: { data: f, is_new: is_new }, status: :ok
    else
      render json: { error: json_api_errors(f) }, status: :unprocessable_entity
    end
  end

  #GET study_id
  def sample_source 
    puts "sample_source"
    flowchart = Flowchart.where(study_id: params[:study_id]).first
    if (flowchart)
      source_sample_type = SampleType.find(flowchart.source_sample_type_id).sample_attributes.select(:required, :title,
           :sample_type_id, :id, :sample_controlled_vocab_id)
      render json: { status: :ok, data: source_sample_type }
    else
      render json: { status: :unprocessable_entity, error: "There is no data yet!" }
    end
  end

  #GET 
  def sample_table
    puts "sample_table"
    assay = Assay.find(params[:assay_id])
    flowchart = Flowchart.where(study_id: assay.study.id).first
    if (flowchart)
      source_sample_type = SampleType.find(flowchart.source_sample_type_id)
      samples = load_samples(assay, source_sample_type)
      header = load_headers(assay, source_sample_type)
      render json: { status: :ok, data: { header: header, samples: samples } }
    else
      render json: { status: :unprocessable_entity, error: "The flowchart does not exist." }
    end
  end


  #GET
  def ontology
    puts "ontology"
    begin
      labels = (SampleControlledVocab.find(params[:sample_controlled_vocab_id])
      &.sample_controlled_vocab_terms || [])
      .where("LOWER(label) like :query", query: "%#{params[:query].downcase}%")
      .select("label").limit(params[:limit] || 100)
      render json: { status: :ok, data: labels }
    rescue Exception => e
      render json: {status: :unprocessable_entity, error: e.message } 
    end
  end

  def destroy
    puts "destroy"
    respond_to do |format|
      flash[:error]="Unable to delete this folder" if !@folder.destroy
      format.html { redirect_to(:project_folders) }
    end
  end

  def nuke
    puts "nuke"
      ProjectFolder.nuke @project
      redirect_to project_folders_path(@project)
  end

  def create_folder
    puts "create_folder"
    title=params[:title]
    if title.length>2
      @folder.add_child(title)
      @folder.save!
      respond_to do |format|
        format.js { render plain: '' }
      end
    else
      error_text="The name is too short, it must be 2 or more characters"
      respond_to do |format|
        format.js { render plain: error_text, status: 500 }
      end
    end

  end

  #moves the asset identified by :asset_id and :asset_type from this folder to the folder identified by :dest_folder_id
  def move_asset_to
    puts "move_asset_to"
    @origin_folder=resolve_folder params[:id]
    @dest_folder=resolve_folder params[:dest_folder_id]
    @dest_folder.move_assets @asset,@origin_folder
    respond_to do |format|
      format.js
    end
  end

  def remove_asset
    puts "remove_asset"
    @folder.remove_assets @asset
    respond_to do |format|
      format.js
    end
  end

  def store_folder_cookie
    puts "store_folder_cookie"
    cooky=cookies[:folder_browsed_json]
    Rails.logger.error "Old cookie value: #{cooky}"
    cooky||={}.to_json
    folder_browsed=ActiveSupport::JSON.decode(cooky)
    folder_browsed[@project.id.to_s]=params[:id]
    Rails.logger.error "New cookie value: #{folder_browsed.to_json}"

    cookies[:folder_browsed_json]=folder_browsed.to_json
  end

  def display_contents
    puts "display_contents"
    begin
      store_folder_cookie
    rescue Exception=>e
      Rails.logger.error("Error reading cookie for last folder browser - #{e.message}")
    end
    respond_to do |format|
      format.js
    end
  end

  def set_project_folder_title
    puts "set_project_folder_title"
    @item = ProjectFolder.find(params[:id])
    @item.update_attribute(:title, params[:value])
    render plain: @item.title
  end

  def set_project_folder_description
    puts "set_project_folder_description"
    @item = ProjectFolder.find(params[:id])
    @item.update_attribute(:description, params[:value])
    render plain: @item.description
  end

  private

  def check_project
    puts "check_project"
    @project = Project.find(params[:project_id])
    if @project.nil? || !current_person.projects.include?(@project)
      error("You must be a member of the #{t('project').downcase}", "is invalid (not in #{t('project').downcase})")
    end
  end

  def browser_enabled
    puts "browser_enabled"
    unless Seek::Config.project_browser_enabled
      flash[:error]="Not available"
      redirect_to @project
    end
  end

  def get_folder
    puts "get_folder"
    id = params[:id]
    resolve_folder id
  end

  def resolve_folder id
    puts "resolve_folder"
    if id.start_with?("Assay")
      id=id.split("_")[1]
      assay = Assay.find(id)
      if assay.can_view?
        @folder = Seek::AssayFolder.new assay,@project
      else
        error("You cannot view the contents of that assay", "is invalid or not authorized")
      end
    else
      @folder = ProjectFolder.find(id)
    end
  end

  def get_folders
    puts "get_folders"
    @folders = project_folders
  end

  def project_folders
    puts "project_folders"
    project_folders = ProjectFolder.root_folders(@project)
    if project_folders.empty?
      project_folders = ProjectFolder.initialize_default_folders(@project)
      ProjectFolderAsset.assign_existing_assets @project
    end
    project_folders
  end

  def get_asset
    puts "get_asset"
    @asset = params[:asset_type].constantize.find(params[:asset_id])
    unless @asset.can_view?
      error("You cannot view the asset", "is invalid or not authorized")
    end
  end

  def load_source_types
    puts "load_source_types"
    source_list = []
    RepositoryStandard.all().each do |item|
      source_list.push({title: item.title, type: item.repo_type, 
        repoId: item.id, attributes: 
        item.sample_controlled_vocabs.map do |term|
          { id: term.id,
          title: term.title,
          shortName: term.short_name,
          des: term.description,
          required: term.required}
        end
      })
    end
    source_list
  end

  def load_headers (assay, source)
    puts "load_headers"
    # No assay is associated with the source
    header = source.sample_attributes.select(:required, :title, :sample_type_id, :id, :sample_controlled_vocab_id)
    Study.find(assay.study.id).assays.where("position <= #{assay.position}").order(:position).each do |a|
      header += a.sample_type.sample_attributes.select(:required, :title, :sample_type_id, :id, :sample_controlled_vocab_id)
    end
    header
  end


  def load_samples (assay, source)
    puts "load_samples"
    return nil if assay.position.nil? 
    samples_collection = {}
    # No assay is associated with the source
    samples_collection[0] = source.samples.select(:id, :json_metadata, :sample_type_id, :link_id)
    Study.find(assay.study.id).assays.where("position <= #{assay.position}").order(:position).each_with_index do |a, i|
      samples_collection[i + 1] = a.sample_type.samples.select(:id, :json_metadata, :sample_type_id, :link_id)
    end
    samples_collection
  end

  
  def flowchart_params
    puts "flowchart_params"
    params.require(:flowchart).permit(:study_id, :source_sample_type_id, :assay_sample_type, :items)
        .select { |k, v| !v.nil? }
  end

  def create_operator (item, study)
    puts "create_operator"
    id = item["id"]
    { properties: {title: id.blank? ? "Source Sample" : study.assays.find(id).sops.first.title,
      inputs: id.blank? ? {} : {input_0: {label: "in"}}, outputs: {output_0: {label: "out"}}, 
      shape: id.blank? ? "parallelogram" : "rectangle", 
      shape_id: id || "init"}, left: item["left"], top: item["top"]}
  end

  def create_link index
    puts "create_link"
    {fromOperator:index, fromConnector:"output_0",
      fromSubConnector: "0",toOperator: index + 1, toConnector:"input_0",toSubConnector: "0"}
  end

end
