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

    sample_strain_ids = params[:sample_strain_ids] || []


    respond_to do |format|
      if @sample.save
        @sample.strains = Strain.find sample_strain_ids.collect { |s| s.split(',') }
        format.html { redirect_to(@sample) }

      else
        format.html { render :action => "new" }
      end
    end
  end


  def update

    sample_strain_ids = params[:sample_strain_ids] || []


    respond_to do |format|

      if @sample.update_attributes params[:sample]
        @sample.strains = Strain.find sample_strain_ids.collect { |s| s.split(',') }

        flash[:notice] = 'Sample was successfully updated'
        format.html { redirect_to @sample }
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
