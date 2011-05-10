class ExperimentsController < ApplicationController


  before_filter :find_assets, :only => [:index]
  before_filter :find_and_auth, :only => [:show, :update, :edit, :destroy]

  #before_filter :login_required
  include IndexPager


  def new
    @experiment = Experiment.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end

  end

  def edit
    @experiment = Experiment.find params[:id]
    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end

  end

  def create
    @experiment = Experiment.new(params[:experiment])
    @experiment.contributor = current_user
    @experiment.project_id= params[:project_id]

    data_file_ids = params[:data_file_ids] || []
    data_file_ids.each do |text|
      a_id, r_type = text.split(",")
      @experiment.data_files << DataFile.find(a_id)
    end
    params.delete :data_file_ids

    AssetsCreator.add_or_update_creator_list(@experiment, params[:creators])
    respond_to do |format|
      if @experiment.save

        # update related publications
        Relationship.create_or_update_attributions(@experiment, params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first] }.to_json, Relationship::RELATED_TO_PUBLICATION) unless params[:related_publication_ids].nil?

        format.html { redirect_to(@experiment) }

      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @experiment.project_id= params[:project_id]

    data_file_ids = params[:data_file_ids] || []
    @experiment.data_files = []
    data_file_ids.each do |text|
      a_id, r_type = text.split(",")
      @experiment.data_files << DataFile.find(a_id)
    end
    params.delete :data_file_ids

    AssetsCreator.add_or_update_creator_list(@experiment, params[:creators])
    respond_to do |format|
      if @experiment.update_attributes params[:experiment]

        # update related publications in relationship
        Relationship.create_or_update_attributions(@experiment, params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first] }.to_json, Relationship::RELATED_TO_PUBLICATION) unless params[:related_publication_ids].nil?

        flash[:notice] = 'Experiment was successfully updated.'
        format.html { redirect_to(@experiment) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @experiment.destroy
        format.html { redirect_to(experiments_path) }
        format.xml { head :ok }
      else
        flash.now[:error]="Unable to delete the experiment" if !@experiment.sample.nil?
        format.html { render :action=>"show" }
        format.xml { render :xml => @experiment.errors, :status => :unprocessable_entity }
      end
    end
  end

  def project_selected_ajax

    if params[:project_id] && params[:project_id]!="0"
      ins=Project.find(params[:project_id]).institutions

    end
    ins||=[]

    render :update do |page|

      page.replace_html "institution_collection", :partial=>"experiments/institutions_list", :locals=>{:ins=>ins, :project_id=>params[:project_id]}
    end

  end

end
