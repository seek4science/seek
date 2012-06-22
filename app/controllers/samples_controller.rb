class SamplesController < ApplicationController

  include IndexPager
  before_filter :find_assets, :only => [:index]
  before_filter :find_and_auth, :only => [:show, :edit, :update, :destroy]
  before_filter :virtualliver_only, :only => [:new_object_based_on_existing_one]

  include Seek::Publishing

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
    @sample.from_new_link = params[:from_new_link]
    @sample.from_biosamples = params[:from_biosamples]
    @sample.specimen = Specimen.find_by_id(params[:specimen_id]) || Specimen.new(:creators=>[User.current_user.person])

    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end
  end

  def edit
    @sample.from_biosamples = params[:from_biosamples]
    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end
  end

  def create
    @sample = Sample.new(params[:sample])
    spe = Specimen.find_by_id(params[:specimen_id])
    if spe && (@sample.from_biosamples=='true')
      @sample.specimen = spe
    else
      @sample.specimen.contributor = @sample.contributor if @sample.specimen.contributor.nil?
      @sample.specimen.projects = @sample.projects if @sample.specimen.projects.blank?
      if @sample.specimen.strain.nil? && !params[:organism].blank?
        @sample.specimen.strain = Strain.default_strain_for_organism(params[:organism])
      end

      #add policy to specimen

      @sample.specimen.policy.set_attributes_with_sharing params[:sharing], @sample.projects

      #get SOPs
      sops = (params[:specimen_sop_ids].nil?? [] : params[:specimen_sop_ids].reject(&:blank?)) || []

      #add creators
      AssetsCreator.add_or_update_creator_list(@sample.specimen, params[:creators])
      @sample.specimen.other_creators=params[:specimen][:other_creators] if params[:specimen]
    end

    @sample.policy.set_attributes_with_sharing params[:sharing], @sample.projects

    if @sample.save
      deliver_request_publish_approval params[:sharing], @sample
        align_sops(@sample.specimen,sops) unless spe

        if @sample.from_new_link=="true"
           render :partial=>"assets/back_to_fancy_parent",:locals=>{:child=>@sample,:parent=>"assay"}
        elsif @sample.from_biosamples=="true"
          render :partial=>"biosamples/back_to_biosamples",:locals=>{:action => 'create', :object=>@sample, :new_specimen => spe ? false : true}
        else
          respond_to do |format|
            flash[:notice] = 'Sample was successfully created.'
            format.html { redirect_to(@sample) }
            format.xml  { head :ok }
          end
        end
    else
        respond_to do |format|
          format.html { render :action => "new" }
        end
    end

  end


  def update
    sops = (params[:sample_sop_ids].nil?? [] : params[:sample_sop_ids].reject(&:blank?)) || []
    @sample.attributes = params[:sample]
    #update policy to sample
    @sample.policy.set_attributes_with_sharing params[:sharing],@sample.projects

    sops  = (params[:specimen_sop_ids].nil?? [] : params[:specimen_sop_ids].reject(&:blank?)) || []

      if @sample.save
        deliver_request_publish_approval params[:sharing], @sample
        align_sops(@sample, sops)

        if @sample.from_biosamples=="true"
          render :partial => "biosamples/back_to_biosamples", :locals => {:action => 'update', :object => @sample}
        else
          respond_to do |format|
            flash[:notice] = 'Sample was successfully updated.'
            format.html { redirect_to(@sample) }
            format.xml { head :ok }
          end
        end
      else
        respond_to do |format|
          format.html { render :action => "edit" }
        end
      end
  end

  def align_sops resource,new_sop_ids
    existing_ids = resource.sop_masters.collect{|sm| sm.sop.id}
    to_remove = existing_ids - new_sop_ids
    join_class_string = ['Sop', resource.class.name].sort.join
    join_class = join_class_string.constantize
    to_remove.each do |id|
      joins = join_class.find(:all, :conditions=>{"#{resource.class.name.downcase}_id".to_sym=>resource.id,:sop_id=>id})
      joins.each{|j| j.destroy}
    end
    (new_sop_ids - existing_ids).each do |id|
      sop=Sop.find(id)
      join_class.create!(:sop_id=>sop.id,:sop_version=>sop.version,"#{resource.class.name.downcase}_id".to_sym=>resource.id)
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
