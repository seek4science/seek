class SamplesController < ApplicationController

  include IndexPager
  include Seek::PreviewHandling
  include Seek::DestroyHandling

  before_filter :biosamples_enabled?
  before_filter :find_assets, :only => [:index]
  before_filter :find_and_authorize_requested_item, :only => [:show, :edit, :update, :destroy,:preview,:new_object_based_on_existing_one]

  #project_membership_required_appended is an alias to project_membership_required, but is necesary to include the actions
  #defined in the application controller
  before_filter :project_membership_required_appended, :only=>[:new_object_based_on_existing_one]

  before_filter :virtualliver_only, :only => [:new_object_based_on_existing_one]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  def new_object_based_on_existing_one
    @existing_sample =  Sample.find(params[:id])
    @sample = @existing_sample.clone_with_associations

    unless @sample.specimen.can_view?
      @sample.specimen = nil
      flash.now[:notice] = "The #{t('biosamples.sample_parent_term')} of the existing Sample cannot be viewed, please specify your own #{t('biosamples.sample_parent_term')}! <br/> "
    else
      flash.now[:notice] = ""
    end

    @existing_sample.data_file_masters.each do |df|
       if !df.can_view?
       flash.now[:notice] << "Some or all #{t('data_file').pluralize} of the existing Sample cannot be viewed, you may specify your own! <br/>"
        break
      end
    end
    @existing_sample.model_masters.each do |m|
       if !m.can_view?
       flash.now[:notice] << "Some or all #{t('model').pluralize} of the existing Sample cannot be viewed, you may specify your own! <br/>"
        break
      end
    end
    @existing_sample.sop_masters.each do |s|
       if !s.can_view?
       flash.now[:notice] << "Some or all #{t('sop').pluralize} of the existing Sample cannot be viewed, you may specify your own! <br/>"
        break
      end
    end

    render :action=>"new"

  end

  def show
    respond_to do |format|
      format.html
      format.xml
      format.rdf { render :template=>'rdf/show'}
    end
  end

  def new
    @sample = Sample.new
    @sample.parent_name = params[:parent_name]
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
    # create new specimen only for combined form
    is_new_spec = params[:sample][:specimen_id].nil? ? true : false

    if is_new_spec
      @sample.specimen.contributor = @sample.contributor if @sample.specimen.contributor.nil?
      @sample.specimen.projects = @sample.projects if @sample.specimen.projects.blank?
      if @sample.specimen.strain.nil? && !params[:organism].blank? && Seek::Config.is_virtualliver
        @sample.specimen.strain = Strain.default_strain_for_organism(params[:organism])
      end
      #add policy to specimen
      @sample.specimen.policy.set_attributes_with_sharing params[:sharing], @sample.projects
      #get specimen SOPs
      specimen_sop_ids = (params[:specimen_sop_ids].nil?? [] : params[:specimen_sop_ids].reject(&:blank?)) || []
      #add creators
      AssetsCreator.add_or_update_creator_list(@sample.specimen, params[:creators])
      @sample.specimen.other_creators=params[:specimen][:other_creators] if params[:specimen]
    end

    tissue_and_cell_types = params[:tissue_and_cell_type_ids]||[]

    @sample.policy.set_attributes_with_sharing params[:sharing], @sample.projects

    data_file_ids = (params[:sample_data_file_ids].nil?? [] : params[:sample_data_file_ids].reject(&:blank?)) || []
    model_ids = (params[:sample_model_ids].nil?? [] : params[:sample_model_ids].reject(&:blank?)) || []
    sop_ids = (params[:sample_sop_ids].nil?? [] : params[:sample_sop_ids].reject(&:blank?)) || []

    if @sample.save
      #send publishing request for specimen
      if !@sample.specimen.can_publish? && params[:sharing] && (params[:sharing][:sharing_scope].to_i == Policy::EVERYONE)
        deliver_request_publish_approval [@sample.specimen]
      end

        tissue_and_cell_types.each do |t|
          t_id, t_title = t.split(",")
          @sample.associate_tissue_and_cell_type(t_id, t_title)
        end if @sample.respond_to?(:tissue_and_cell_types)
      @sample.create_or_update_assets data_file_ids, "DataFile"
      @sample.create_or_update_assets model_ids, "Model"
      @sample.create_or_update_assets sop_ids, "Sop"
      
      align_sops(@sample.specimen, specimen_sop_ids) if is_new_spec


      if @sample.parent_name=="assay"
        render :partial=>"assets/back_to_fancy_parent", :locals=>{:child=>@sample, :parent_name=>"assay"}
        elsif @sample.from_biosamples=="true"
          render :partial=>"biosamples/back_to_biosamples",:locals=>{:action => 'create', :object=>@sample, :new_specimen => is_new_spec}
      else
        respond_to do |format|
          flash[:notice] = 'Sample was successfully created.'
          format.html { redirect_to(@sample) }
          format.xml { head :ok }
        end
      end
    else
        respond_to do |format|
          format.html { render :action => "new" }
        end
    end

  end


  def update
    data_file_ids = (params[:sample_data_file_ids].nil? ? [] : params[:sample_data_file_ids].reject(&:blank?)) || []
    model_ids = (params[:sample_model_ids].nil? ? [] : params[:sample_model_ids].reject(&:blank?)) || []
    sop_ids = (params[:sample_sop_ids].nil? ? [] : params[:sample_sop_ids].reject(&:blank?)) || []
    @sample.attributes = params[:sample]
      tissue_and_cell_types = params[:tissue_and_cell_type_ids]||[]

    #update policy to sample
    @sample.policy.set_attributes_with_sharing params[:sharing],@sample.projects

      if @sample.save
        #TODO CONFIG improve configurability. Configuration currently is deduced from other parameters
        if tissue_and_cell_types.blank?
          @sample.tissue_and_cell_types= tissue_and_cell_types
          @sample.save
        else
          tissue_and_cell_types.each do |t|
          t_id, t_title = t.split(",")
          @sample.associate_tissue_and_cell_type(t_id, t_title)
          end
        end
          @sample.create_or_update_assets data_file_ids,"DataFile"
          @sample.create_or_update_assets model_ids,"Model"
          @sample.create_or_update_assets sop_ids,"Sop"

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
      joins = join_class.where({"#{resource.class.name.downcase}_id".to_sym=>resource.id,:sop_id=>id})
      joins.each{|j| j.destroy}
    end
    (new_sop_ids - existing_ids).each do |id|
      sop=Sop.find(id)
      join_class.create!(:sop_id=>sop.id,:sop_version=>sop.version,"#{resource.class.name.downcase}_id".to_sym=>resource.id)
    end
  end

end
