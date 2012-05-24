class SpecimensController < ApplicationController
  # To change this template use File | Settings | File Templates.

  before_filter :find_assets, :only => [:index]
  before_filter :find_and_auth, :only => [:show, :update, :edit, :destroy]

  include IndexPager

  def new_object_based_on_existing_one
    @existing_specimen =  Specimen.find(params[:id])
    @specimen = @existing_specimen.clone_with_associations

     @existing_specimen.sop_masters.each do |s|
       if !s.sop.can_view?
       flash.now[:notice] = "Some or all sops of the existing specimen cannot be viewed, you may specify your own!"
        break
      end
     end

    render :action=>"new"

  end

  def new
    @specimen = Specimen.new
    respond_to do |format|

      format.html # new.html.erb
    end
  end

  def create
    organism_id = params[:specimen].delete(:organism_id)
    @specimen = Specimen.new(params[:specimen])
    sop_ids = (params[:specimen_sop_ids].nil? ? [] : params[:specimen_sop_ids].reject(&:blank?))||[]
    @specimen.build_sop_masters sop_ids
    @specimen.policy.set_attributes_with_sharing params[:sharing], @specimen.projects

    if @specimen.strain.nil? && !params[:organism].blank?
      @specimen.strain = Strain.default_strain_for_organism(params[:organism])
    end

    #Add creators
    AssetsCreator.add_or_update_creator_list(@specimen, params[:creators])
    respond_to do |format|
      if @specimen.save
        flash[:notice] = 'Specimen was successfully created.'
        format.html { redirect_to(@specimen) }
        format.xml  { head :ok }
      else
       # Policy.create_or_update_policy(@specimen, current_user, params)
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @specimen.from_biosamples = params[:from_biosamples]
    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end
  end

  def update
    sop_ids = (params[:specimen_sop_ids].nil?? [] : params[:specimen_sop_ids].reject(&:blank?))||[]
    @specimen.build_sop_masters sop_ids

    @specimen.attributes = params[:specimen]
    @specimen.policy.set_attributes_with_sharing params[:sharing], @specimen.projects

    if @specimen.strain.nil? && !params[:organism].blank?
        @specimen.strain = Strain.default_strain_for_organism(params[:organism])
    end

    #update creators
    AssetsCreator.add_or_update_creator_list(@specimen, params[:creators])

    if @specimen.save
      if @specimen.from_biosamples=='true'
        #reload to get updated nested attributes,e.g. genotypes/phenotypes
        @specimen.reload
        render :partial => "biosamples/back_to_biosamples", :locals => {:action => 'update', :object => @specimen}
      else
        respond_to do |format|
          flash[:notice] = 'Specimen was successfully updated.'
          format.html { redirect_to(@specimen) }
          format.xml { head :ok }
        end
      end
    else
      respond_to do |format|
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
