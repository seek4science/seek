class SamplesController < ApplicationController

  include IndexPager
  before_filter :find_assets, :only => [:index]
  before_filter :find_and_auth, :only => [:show, :edit, :update, :destroy]


  def new_object_based_on_existing_one
    @existing_sample =  Sample.find(params[:id])
    @sample = @existing_sample.clone_with_associations

    unless @sample.specimen.can_view?
      @sample.specimen = nil
      flash.now[:notice] = "The specimen of the existing sample cannot be viewed, please specify your own specimen! <br/> "
    end

    @existing_sample.sop_masters.each do |s|
       if !s.sop.can_view?
       flash.now[:notice] << "Some or all sops of the existing sample cannot be viewed, you may specify your own! <br/>"
        break
      end
    end
    render :action=>"new"

  end

  def new
    @sample = Sample.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end
  end


  def create
    @sample = Sample.new(params[:sample])

    #add policy to sample
    @sample.policy.set_attributes_with_sharing params[:sharing], @sample.project
    tissue_and_cell_types = params[:tissue_and_cell_type_ids]||[]
    sops       = params[:sample_sop_ids] || []
    respond_to do |format|
      if @sample.save
        tissue_and_cell_types.each do |t|
          t_id, t_title = t.split(",")
          @sample.associate_tissue_and_cell_type(t_id, t_title)
        end
        sops.each do |s_id|
          s = Sop.find(s_id)
          @sample.associate_sop(s) if s.can_view?
        end
        flash[:notice] = 'Sample was successfully created.'
        format.html { redirect_to(@sample) }
        format.xml { head :ok }
      else

        format.html { render :action => "new" }
      end
    end
  end


  def update


      tissue_and_cell_types = params[:tissue_and_cell_type_ids]||[]
      sops       = params[:sample_sop_ids] || []

      @sample.attributes = params[:sample]

      #update policy to sample
      @sample.policy.set_attributes_with_sharing params[:sharing], @sample.project
      respond_to do |format|

      if @sample.save
        if tissue_and_cell_types.blank?
          @sample.tissue_and_cell_types= tissue_and_cell_types
          @sample.save
        else
          tissue_and_cell_types.each do |t|
          t_id, t_title = t.split(",")
          @sample.associate_tissue_and_cell_type(t_id, t_title)
          end
        end

        if sops.blank?
          @sample.sample_sops= []
          @sample.save
        else
          sops.each do |s_id|
          s = Sop.find(s_id)
          @sample.associate_sop(s) if s.can_view?
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
