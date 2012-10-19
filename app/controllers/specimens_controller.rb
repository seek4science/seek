class SpecimensController < ApplicationController
  # To change this template use File | Settings | File Templates.

  before_filter :find_assets, :only => [:index]
  before_filter :find_and_auth, :only => [:show, :update, :edit, :destroy]

  include IndexPager
  include Seek::Publishing

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
    sop_ids = (params[:specimen_sop_ids].nil?? [] : params[:specimen_sop_ids].reject(&:blank?))||[]
    @specimen.policy.set_attributes_with_sharing params[:sharing], @specimen.projects

    if @specimen.strain.nil? && !params[:organism].blank?
      @specimen.strain = Strain.default_strain_for_organism(params[:organism])
    end

    #Add creators
    AssetsCreator.add_or_update_creator_list(@specimen, params[:creators])
    respond_to do |format|
      if @specimen.save
        deliver_request_publish_approval params[:sharing], @specimen
        sop_ids.each do |sop_id|
          sop= Sop.find sop_id
          SopSpecimen.create!(:sop_id => sop_id,:sop_version=> sop.version,:specimen_id=>@specimen.id)
        end

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
    sop_ids = (params[:specimen_sop_ids].nil?? [] : params[:specimen_sop_ids].reject(&:blank?)) ||[]

    @specimen.attributes = params[:specimen]
    @specimen.policy.set_attributes_with_sharing params[:sharing], @specimen.projects

    if @specimen.strain.nil? && !params[:organism].blank?
        @specimen.strain = Strain.default_strain_for_organism(params[:organism])
    end

    #update creators
    AssetsCreator.add_or_update_creator_list(@specimen, params[:creators])

    if @specimen.save
      deliver_request_publish_approval params[:sharing], @specimen
      #associate sops
      sop_ids.each do |sop_id|
        sop= Sop.find sop_id
        existing = @specimen.sop_masters.select { |ss| ss.sop == sop }
        if existing.blank?
          SopSpecimen.create!(:sop_id => sop_id, :sop_version => sop.version, :specimen_id => @specimen.id)
        end
      end
      #unassociate sops
      (@specimen.sop_masters.collect{|sm| sm.sop.id} - sop_ids.map(&:to_i)).each do |id|
        sop_master = @specimen.sop_masters.detect{ |ss| ss.sop.id == id }
        sop_master.destroy if sop_master && sop_master.sop.can_view?
      end

      if @specimen.from_biosamples=='true'
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
