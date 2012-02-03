class SamplesController < ApplicationController

  include IndexPager
  before_filter :find_assets, :only => [:index]
  before_filter :find_and_auth, :only => [:show, :edit, :update, :destroy]
  before_filter :virtualliver_only


  def new_object_based_on_existing_one
    @existing_sample =  Sample.find(params[:id])
    @sample = @existing_sample.clone_with_associations

    unless @sample.specimen.can_view?
      @sample.specimen = nil
      flash.now[:notice] = "The specimen of the existing sample cannot be viewed, please specify your own specimen! <br/> "
    else
      flash.now[:notice] = ""
    end

    @existing_sample.data_file_masters.each do |df|
       if !df.can_view?
       flash.now[:notice] << "Some or all data files of the existing sample cannot be viewed, you may specify your own! <br/>"
        break
      end
    end
    @existing_sample.model_masters.each do |m|
       if !m.can_view?
       flash.now[:notice] << "Some or all models of the existing sample cannot be viewed, you may specify your own! <br/>"
        break
      end
    end
    @existing_sample.sop_masters.each do |s|
       if !s.can_view?
       flash.now[:notice] << "Some or all sops of the existing sample cannot be viewed, you may specify your own! <br/>"
        break
      end
    end

    render :action=>"new"

  end

  def new
    @sample = Sample.new
    @sample.from_new_link = params[:from_new_link]

    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end
  end


  def create
    @sample = Sample.new(params[:sample])

    #add policy to sample
    @sample.policy.set_attributes_with_sharing params[:sharing], @sample.projects
    data_file_ids = (params[:sample_data_file_ids].nil?? [] : params[:sample_data_file_ids].reject(&:blank?)) || []
    model_ids = (params[:sample_model_ids].nil?? [] : params[:sample_model_ids].reject(&:blank?)) || []
    sop_ids = (params[:sample_sop_ids].nil?? [] : params[:sample_sop_ids].reject(&:blank?)) || []

    if @sample.save

      @sample.create_or_update_assets data_file_ids, "DataFile"
      @sample.create_or_update_assets model_ids, "Model"
      @sample.create_or_update_assets sop_ids, "Sop"

      if @sample.from_new_link=="true"
        render :partial=>"assets/back_to_fancy_parent", :locals=>{:child=>@sample, :parent=>"assay"}
      else
        respond_to do |format|
          flash[:notice] = 'Sample was successfully created.'
          format.html { redirect_to(@sample) }
          format.xml { head :ok }
        end
      end
    else
        respond_to do |format|
          format.html { render :action => "new" }
          end
    end

  end


  def update
      data_file_ids = (params[:sample_data_file_ids].nil? ? [] : params[:sample_data_file_ids].reject(&:blank?)) || []
      model_ids = (params[:sample_model_ids].nil? ? [] : params[:sample_model_ids].reject(&:blank?)) || []
      sop_ids = (params[:sample_sop_ids].nil? ? [] : params[:sample_sop_ids].reject(&:blank?)) || []

      @sample.attributes = params[:sample]

      #update policy to sample
      @sample.policy.set_attributes_with_sharing params[:sharing],@sample.projects
      respond_to do |format|

      if @sample.save

        @sample.create_or_update_assets data_file_ids,"DataFile"
        @sample.create_or_update_assets model_ids,"Model"
        @sample.create_or_update_assets sop_ids,"Sop"

        flash[:notice] = 'Sample was successfully updated.'
        format.html { redirect_to(@sample) }
        format.xml { head :ok }

      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy

    respond_to do |format|
      if @sample.destroy
        format.html { redirect_to samples_url }
      else
        flash.now[:error] = "Unable to delete sample" if !@sample.specimen.nil?
        format.html { render :action => "show" }
      end
    end
  end


end
