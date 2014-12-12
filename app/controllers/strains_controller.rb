class StrainsController < ApplicationController
  include IndexPager
  include Seek::AnnotationCommon
  include Seek::DestroyHandling

  before_filter :organisms_enabled?
  before_filter :find_assets, :only => [:index]
  before_filter :find_and_authorize_requested_item, :only => [:show, :edit, :update, :destroy]

  before_filter :get_strains_for_organism,:only=>[:existing_strains_for_assay_organism]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  def new
    parent_strain = Strain.find_by_id(params[:parent_id])
    if !parent_strain.nil? && parent_strain.can_view?
      @strain = parent_strain.clone_with_associations
      @strain.parent_id = parent_strain.id
    else
      @strain = Strain.new()
    end

    @strain.from_biosamples = params[:from_biosamples]
  end

  def edit
    @strain.from_biosamples = params[:from_biosamples]
    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end
  end

  def create
    @strain = new_strain(params[:strain])
    @strain.policy.set_attributes_with_sharing params[:sharing], @strain.projects
    update_annotations @strain

    if @strain.save
      if @strain.from_biosamples=='true'
        #reload to get updated nested attributes,e.g. genotypes/phenotypes
        @strain.reload
        render :partial => "biosamples/back_to_biosamples", :locals => {:action => 'create', :object => @strain}
      else
        respond_to do |format|
          flash[:notice] = 'Strain was successfully created.'
          format.html { redirect_to(@strain) }
          format.xml { render :xml => @strain, :status => :created, :location => @strain }
        end
      end
    else
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml { render :xml => @strain.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    respond_to do |format|
      format.rdf { render :template=>'rdf/show'}
      format.xml
      format.html
    end
  end

  def update
    update_annotations @strain
    if params[:sharing]
      @strain.policy.set_attributes_with_sharing params[:sharing], @strain.projects
    end
    @strain.attributes = params[:strain]
    if @strain.save
      if @strain.from_biosamples=='true'
        #reload to get updated nested attributes,e.g. genotypes/phenotypes
        @strain.reload
        render :partial => "biosamples/back_to_biosamples", :locals => {:action => 'update', :object => @strain}
      else
        respond_to do |format|
          flash[:notice] = 'Strain was successfully updated.'
          format.html { redirect_to(@strain) }
          format.xml { render :xml => @strain, :status => :created, :location => @strain }
        end
      end
    else
      respond_to do |format|
        format.html { render :action => "edit" }
        format.xml { render :xml => @strain.errors, :status => :unprocessable_entity }
      end
    end
  end

  def existing_strains_for_assay_organism
    if User.current_user && !Seek::Config.is_virtualliver
      #restrict strains to those of that persons project
      projects = User.current_user.person.projects
      @strains = @strains.select{|s| !(s.projects & projects).empty?}
    end
    render :update do |page|
      if @strains && @organism
        page.replace_html 'existing_strains_for_assay_organism', :partial=>"strains/existing_strains_for_assay_organism",:object=>@strains,:locals=>{:organism=>@organism}
      else
        page.insert_html :bottom, 'existing_strains_for_assay_organism',:text=>""
      end
    end
  end

  def get_strains_for_organism
    if params[:organism_id]
      @organism=Organism.find_by_id(params[:organism_id])
      strains=@organism.try(:strains)
      @strains = strains ? strains.reject{|s| s.is_dummy? || s.id == params[:strain_id].to_i}.select(&:can_view?) : strains
    end
  end

  def new_strain strain_params
    strain = Strain.new
    # to delete id hash which is saved in the hidden id field (automatically generated in form with fields_for)
    # try_block {
    #delete id hashes of genotypes/phenotypes
    strain_params[:genotypes_attributes].try(:delete, "id")
    strain_params[:phenotypes_attributes].try(:delete, "id")
    #delete id hashes of gene_attributes/modification_attributes
    strain_params[:genotypes_attributes].try(:each) do |genotype_key, genotype_value|

      genotype_value.delete_if { |k, v| k=="id" }
      #delete if,e.g. "0"=>{"_destroy"=>0} for genotypes
      strain_params[:genotypes_attributes].delete(genotype_key) if genotype_value.keys == ["_destroy"]

      genotype_value[:gene_attributes].try(:delete_if) { |k, v| k=="id" }
      genotype_value[:modification_attributes].try(:delete_if) { |k, v| k=="id" }

      #delete if,e.g. "0"=>{"_destroy"=>0}  for gene_attributes/modification_attributes (which means new genes/modifications with empty title), this must be done after the id hashes are deleted!!!
      genotype_value.delete("gene_attributes") if genotype_value[:gene_attributes].try(:keys) == ["_destroy"]
      genotype_value.delete("modification_attributes") if genotype_value[:modification_attributes].try(:keys) == ["_destroy"]
    end
    strain_params[:phenotypes_attributes].try(:each) do |key, value|
      value.delete_if { |k, v| k=="id" }
      #delete if ,e.g. "0"=>{"_destroy"=>0} for phenotypes
      strain_params[:phenotypes_attributes].delete(key) if value.keys== ["_destroy"]
    end
    # }

    strain.attributes = strain_params
    strain
  end

end
