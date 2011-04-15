class ExperimentsController < ApplicationController


  before_filter :find_experiments, :only => [:index]
  before_filter :find_experiment, :only => [:show, :update, :edit,:destroy]

  before_filter :login_required
  include IndexPager

  def find_experiment
    @experiment = Experiment.find params[:id]

  end

   def find_experiments
    @experiments = apply_filters( Experiment.find(:all)  )
   end


  def new
    @experiment = Experiment.new
      respond_to do |format|
      format.html # new.html.erb
      format.xml
    end

  end

  def create
     @experiment = Experiment.new(params[:experiment])

    respond_to do |format|
      if @experiment.save

      format.html { redirect_to(@experiment)}

      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    respond_to do |format|
      if @experiment.update_attributes params[:experiment]
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




end
