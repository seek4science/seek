class StrainsController < ApplicationController
  include Seek::IndexPager
  include Seek::AssetsCommon

  before_action :organisms_enabled?
  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item, only: [:show, :edit, :update, :destroy, :manage, :manage_update]

  before_action :get_strains_for_organism, only: [:existing_strains_for_assay_organism]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  def new
    parent_strain = Strain.find_by_id(params[:parent_id])
    if !parent_strain.nil? && parent_strain.can_view?
      @strain = parent_strain.clone_with_associations
      @strain.parent_id = parent_strain.id
    else
      @strain = Strain.new
    end
  end

  def edit
    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end
  end

  def create
    @strain = new_strain(strain_params)
    @strain.policy.set_attributes_with_sharing(params[:policy_attributes])
    update_annotations(params[:tag_list], @strain)

    if @strain.save

      respond_to do |format|
        flash[:notice] = 'Strain was successfully created.'
        format.html { redirect_to(@strain) }
        format.xml { render xml: @strain, status: :created, location: @strain }
        format.json {render json: @strain, status: :created, location: @strain}

      end

    else
      respond_to do |format|
        format.html { render action: 'new' }
        format.xml { render xml: @strain.errors, status: :unprocessable_entity }
        format.json  { render json: @strain.errors, status: :unprocessable_entity }

      end
    end
  end

  def index
    respond_to do |format|
      format.rdf {super}
      format.xml {super}
      format.html {super}
      format.json {render json: :not_implemented, status: :not_implemented }
    end
  end

  def show
    respond_to do |format|
      format.rdf { render template: 'rdf/show' }
      format.xml
      format.html
      # format.json {render json: @strain}
      format.json {render json: :not_implemented, status: :not_implemented }

    end
  end

  def update
    @strain.attributes = strain_params
    update_annotations(params[:tag_list], @strain)
    if params[:policy_attributes]
      @strain.policy.set_attributes_with_sharing(params[:policy_attributes])
    end
    if @strain.save
      respond_to do |format|
        flash[:notice] = 'Strain was successfully updated.'
        format.html { redirect_to(@strain) }
        format.xml { render xml: @strain, status: :created, location: @strain }
        format.json {render json: @strain}
      end

    else
      respond_to do |format|
        format.html { render action: 'edit' }
        format.xml { render xml: @strain.errors, status: :unprocessable_entity }
        format.json  { render json: @strain.errors, status: :unprocessable_entity }
      end
    end
  end

  def existing_strains_for_assay_organism
    if current_user && !Seek::Config.is_virtualliver
      # restrict strains to those of that persons project
      projects = current_person.projects
      @strains = @strains.select { |s| !(s.projects & projects).empty? }
    end
    if @strains && @organism
      render partial: 'strains/existing_strains_for_assay_organism', object: @strains, locals: { organism: @organism }
    else
      render plain: ''
    end
  end

  def get_strains_for_organism
    if params[:organism_id]
      @organism = Organism.find_by_id(params[:organism_id])
      strains = @organism.try(:strains)
      @strains = strains ? strains.reject { |s| s.is_dummy? || s.id == params[:strain_id].to_i }.select(&:can_view?) : strains
    end
  end

  def new_strain(strain_params)
    strain = Strain.new
    # to delete id hash which is saved in the hidden id field (automatically generated in form with fields_for)
    # try_block {
    # delete id hashes of genotypes/phenotypes
    strain_params[:genotypes_attributes].try(:delete, 'id')
    strain_params[:phenotypes_attributes].try(:delete, 'id')
    # delete id hashes of gene_attributes/modification_attributes
    strain_params[:genotypes_attributes].try(:each) do |genotype_key, genotype_value|
      genotype_value.delete_if { |k, _v| k == 'id' }
      # delete if,e.g. "0"=>{"_destroy"=>0} for genotypes
      strain_params[:genotypes_attributes].delete(genotype_key) if genotype_value.keys == ['_destroy']

      genotype_value[:gene_attributes].try(:delete_if) { |k, _v| k == 'id' }
      genotype_value[:modification_attributes].try(:delete_if) { |k, _v| k == 'id' }

      # delete if,e.g. "0"=>{"_destroy"=>0}  for gene_attributes/modification_attributes (which means new genes/modifications with empty title), this must be done after the id hashes are deleted!!!
      genotype_value.delete('gene_attributes') if genotype_value[:gene_attributes].try(:keys) == ['_destroy']
      genotype_value.delete('modification_attributes') if genotype_value[:modification_attributes].try(:keys) == ['_destroy']
    end
    strain_params[:phenotypes_attributes].try(:each) do |key, value|
      value.delete_if { |k, _v| k == 'id' }
      # delete if ,e.g. "0"=>{"_destroy"=>0} for phenotypes
      strain_params[:phenotypes_attributes].delete(key) if value.keys == ['_destroy']
    end
    # }

    strain.attributes = strain_params
    strain
  end

  def strains_of_selected_organism
    strains = []
    if params[:organism_id]
      organism = Organism.find_by_id params[:organism_id].to_i
      strains |= organism.strains if organism
    end
    respond_to do |format|
      format.json do
        render json: { status: 200, strains: strains.sort_by(&:title).reject(&:is_dummy).select(&:can_view?).collect { |strain| [strain.id, strain.info] } }
      end
    end
  end

  private

  def strain_params
    params.require(:strain).permit(:title, :provider_id, :provider_name, :synonym, :comment, :organism_id, :parent_id,
                                   { project_ids: [] },
                                   { genotypes_attributes: [:id, :_destroy,
                                                            { gene_attributes: [:title] },
                                                            { modification_attributes: [:title]}]},
                                   { phenotypes_attributes: [:id, :_destroy, :description]})
  end

end
