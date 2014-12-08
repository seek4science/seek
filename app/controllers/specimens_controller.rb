class SpecimensController < ApplicationController
  include IndexPager
  include Seek::Publishing::PublishingCommon
  include Seek::BreadCrumbs
  include Seek::DestroyHandling

  before_filter :biosamples_enabled?
  before_filter :find_assets, :only => [:index]
  before_filter :find_and_authorize_requested_item, :only => [:show, :update, :edit, :destroy,:new_object_based_on_existing_one]

  #project_membership_required_appended is an alias to project_membership_required, but is necesary to include the actions
  #defined in the application controller
  before_filter :project_membership_required_appended, :only=>[:new_object_based_on_existing_one]

  def new_object_based_on_existing_one
    @existing_specimen =  Specimen.find(params[:id])
    @specimen = @existing_specimen.clone_with_associations

     @existing_specimen.sop_masters.each do |s|
       if !s.sop.can_view?
       flash.now[:notice] = "Some or all #{t('sop').pluralize} of the existing #{t('biosamples.sample_parent_term')} cannot be viewed, you may specify your own!"
        break
      end
     end

    render :action=>"new"

  end

  def new
    @specimen = Specimen.new
    @specimen.from_biosamples = params[:from_biosamples]
    respond_to do |format|

      format.html # new.html.erb
    end
  end

  def show
    respond_to do |format|
      format.xml
      format.html
      format.rdf { render :template=>'rdf/show'}
    end
  end

  def create
    organism_id = params[:specimen].delete(:organism_id)
    @specimen = new_specimen
    sop_ids = (params[:specimen_sop_ids].nil? ? [] : params[:specimen_sop_ids].reject(&:blank?))||[]
    @specimen.build_sop_masters sop_ids
    @specimen.policy.set_attributes_with_sharing params[:sharing], @specimen.projects

    if @specimen.strain.nil? && !params[:organism].blank? && Seek::Config.is_virtualliver
      @specimen.strain = Strain.default_strain_for_organism(params[:organism])
    end

    #Add creators
    AssetsCreator.add_or_update_creator_list(@specimen, params[:creators])

    if @specimen.save
      if @specimen.from_biosamples=='true'
        #reload to get updated nested attributes,e.g. genotypes/phenotypes
        @specimen.reload
        render :partial => "biosamples/back_to_biosamples", :locals => {:action => 'create', :object => @specimen}
      else
        respond_to do |format|
          flash[:notice] = "#{t('biosamples.sample_parent_term')} was successfully created."
          format.html { redirect_to(@specimen) }
          format.xml  { head :ok }
        end
      end
    else
     # Policy.create_or_update_policy(@specimen, current_user, params)
      respond_to do |format|
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

    if @specimen.strain.nil? && !params[:organism].blank? && Seek::Config.is_virtualliver
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
          flash[:notice] = "#{t('biosamples.sample_parent_term')} was successfully updated."
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

  private
  def new_specimen
        specimen = Specimen.new
        # to delete id hash which is saved in the hidden id field (automatically generated in form with fields_for)
          #delete id hashes of genotypes/phenotypes
          params[:specimen][:genotypes_attributes].try(:delete, "id")
          params[:specimen][:phenotypes_attributes].try(:delete, "id")
          #delete id hashes of gene_attributes/modification_attributes
          params[:specimen][:genotypes_attributes].try(:each) do |genotype_key,genotype_value|

            genotype_value.delete_if { |k, v| k=="id" }
            #delete if,e.g. "0"=>{"_destroy"=>0} for genotypes
            params[:specimen][:genotypes_attributes].delete(genotype_key) if genotype_value.keys == ["_destroy"]

            genotype_value[:gene_attributes].try(:delete_if) { |k, v| k=="id"}
            genotype_value[:modification_attributes].try(:delete_if) { |k, v| k=="id"}

            #delete if,e.g. "0"=>{"_destroy"=>0}  for gene_attributes/modification_attributes (which means new genes/modifications with empty title), this must be done after the id hashes are deleted!!!
            genotype_value.delete("gene_attributes") if genotype_value[:gene_attributes].try(:keys) == ["_destroy"]
            genotype_value.delete("modification_attributes") if genotype_value[:modification_attributes].try(:keys) == ["_destroy"]
          end
          params[:specimen][:phenotypes_attributes].try(:each) do |key, value|
            value.delete_if { |k, v| k=="id" }
            #delete if ,e.g. "0"=>{"_destroy"=>0} for phenotypes
            params[:specimen][:phenotypes_attributes].delete(key) if value.keys== ["_destroy"]
          end
        specimen.attributes = params[:specimen]
        specimen
    end
end
