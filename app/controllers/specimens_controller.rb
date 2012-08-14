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
    @specimen = new_specimen
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
        deliver_request_publish_approval params[:sharing], @specimen
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
      deliver_request_publish_approval params[:sharing], @specimen
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
