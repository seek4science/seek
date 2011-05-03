class SpecimensController < ApplicationController
  # To change this template use File | Settings | File Templates.


  before_filter :find_assets, :only => [:index]
  before_filter :find_and_auth, :only => [:show, :update, :edit, :destroy]

  include IndexPager

  def new
    @specimen = Specimen.new
    respond_to do |format|

      format.html # new.html.erb
    end
  end

  def create
    @specimen = Specimen.new(params[:specimen])
    @specimen.contributor = current_user
    @specimen.project= Project.find params[:project_id]


    respond_to do |format|
      if @specimen.save


        #Add creators
        AssetsCreator.add_or_update_creator_list(@specimen, params[:creators])
        format.html { redirect_to @specimen }

      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    respond_to do |format|
      if @specimen.update_attributes params[:specimen]
        #update creators
        AssetsCreator.add_or_update_creator_list(@specimen, params[:creators])
        format.html { redirect_to @specimen }
      else
        format.html { render :action => "edit" }
      end

    end
  end

  def destroy
    respond_to do |format|
      if @specimen.destroy
        format.html { redirect_to(specimens_path) }
        format.xml { head :ok }
      else
        flash.now[:error]="Unable to delete the specimen" if !@specimen.institution.nil?
        format.html { render :action=>"show" }
        format.xml { render :xml => @specimen.errors, :status => :unprocessable_entity }
      end
    end
  end


  def project_selected_ajax

    if params[:project_id] && params[:project_id]!="0"
      ins=Project.find(params[:project_id]).institutions

    end
    ins||=[]

    render :update do |page|

      page.replace_html "institution_collection", :partial=>"specimens/institutions_list", :locals=>{:ins=>ins, :project_id=>params[:project_id]}
    end

  end


end

