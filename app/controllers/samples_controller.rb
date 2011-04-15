class SamplesController < ApplicationController

  include IndexPager

  before_filter :find_samples, :only => [:index]
  before_filter :find_sample, :only => [:show,:edit,:update,:destroy]

  def find_sample
    @sample = Sample.find params[:id]
  end
  def find_samples
    controller = self.controller_name.downcase
    model_name=controller.classify
    model_class=eval(model_name)
    found = model_class.find(:all)
    found = apply_filters(found)

    eval("@" + controller + " = found")
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

        respond_to do |format|
      if @sample.save

      format.html { redirect_to(@sample)}

      else
        format.html { render :action => "new" }
      end
    end
  end


  def update
    respond_to do |format|

      if @sample.update_attributes params[:sample]
        flash[:notice] = 'Sample was successfully updated'
        format.html {redirect_to @sample}
      else
        format.html {render :action => "edit"}
      end
    end
  end

  def destroy

    respond_to do |format|
      if @sample.destroy
        format.html{redirect_to samples_url}
      else
        flash.now[:error] = "Unable to delete sample" if !@sample.specimen.nil?
        format.html { render :action => "show"}
      end
    end
  end

end
