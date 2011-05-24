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

    #add policy to sample
    @sample.policy_or_default
    @sample.policy.set_attributes_with_sharing params[:sharing]
    tissue_and_cell_types = params[:tissue_and_cell_type_ids]||[]

    respond_to do |format|
      if @sample.save

        tissue_and_cell_types.each do |t|
          t_id, t_title = t.split(",")
          @sample.associate_tissue_and_cell_type(t_id, t_title)
        end
          flash[:notice] = 'Sample was successfully created.'
          format.html { redirect_to(@sample) }
          format.xml  { head :ok }
      else
        format.html { render :action => "new" }
      end
    end
  end


  def update


      tissue_and_cell_types = params[:tissue_and_cell_type_ids]||[]

      #update policy to sample
      @sample.policy.set_attributes_with_sharing params[:sharing]
      respond_to do |format|

      if @sample.update_attributes params[:sample]
        if tissue_and_cell_types.blank?
          @sample.tissue_and_cell_types= tissue_and_cell_types
        else
           tissue_and_cell_types.each do |t|
          t_id, t_title = t.split(",")
          @sample.associate_tissue_and_cell_type(t_id, t_title)
        end
        end


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
