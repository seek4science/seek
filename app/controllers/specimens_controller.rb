class SpecimensController < ApplicationController
  # To change this template use File | Settings | File Templates.

  before_filter :find_specimens, :only => [:index]
  before_filter :find_specimen, :only => [:show, :update, :edit,:destroy]

  before_filter :login_required
  include IndexPager

  def find_specimen
    @specimen = Specimen.find params[:id]

  end

   def find_specimens
    @specimens = apply_filters( Specimen.find(:all)  )
   end


  def new
    @specimen = Specimen.new
      respond_to do |format|
      format.html # new.html.erb
      format.xml
  end

  end

  def create
     @specimen = Specimen.new(params[:specimen])
     @specimen.contributor = current_user
    respond_to do |format|
      if @specimen.save
      #Add creators
          AssetsCreator.add_or_update_creator_list(@specimen, params[:creators])
      format.html { redirect_to(@specimen)}

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
        flash[:notice] = 'Specimen was successfully updated.'
        format.html { redirect_to(@specimen) }
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



end

