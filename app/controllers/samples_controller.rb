class SamplesController < ApplicationController

  include IndexPager
  before_filter :find_assets, :only => [:index]
  before_filter :find_and_auth, :only => [:show, :edit, :update, :destroy]


  def new
    @sample = Sample.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end
  end


  def create
    @sample = Sample.new(params[:sample])
    @sample.contributor = current_user
    @sample.strain_ids = params[:sample_strain_ids]
    #add policy to sample
    policy_err_msg = Policy.create_or_update_policy(@sample, current_user, params)
    respond_to do |format|
      if @sample.save

        if policy_err_msg.blank?
          flash[:notice] = 'Sample was successfully created.'
          format.html { redirect_to(@sample) }
          format.xml  { head :ok }
        else
          flash[:notice] = "Sample metadata was successfully updated. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
         format.html { redirect_to sample_edit_path(@sample)}
        end

      else
        format.html { render :action => "new" }
      end
    end
  end


  def update

      @sample.strain_ids = params[:sample_strain_ids]
      #update policy to sample
    policy_err_msg = Policy.create_or_update_policy(@sample, current_user, params)

      respond_to do |format|

      if @sample.update_attributes params[:sample]
         if policy_err_msg.blank?
          flash[:notice] = 'Sample was successfully created.'
          format.html { redirect_to(@sample) }
          format.xml  { head :ok }
        else
          flash[:notice] = "Sample metadata was successfully updated. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
         format.html { redirect_to sample_edit_path(@sample)}
        end
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

  def strains_selected_ajax
      if params[:sample_strain_ids] && params[:sample_strain_ids]!="0"
      @sample.strains = Strain.find(params[:sample_strain_ids])
     end
  end

end
