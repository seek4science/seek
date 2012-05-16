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
    sop_ids = (params[:specimen_sop_ids].nil?? [] : params[:specimen_sop_ids].reject(&:blank?))||[]
    @specimen.policy.set_attributes_with_sharing params[:sharing], @specimen.projects

    #strain
    if params[:create_strain] == '1' || params[:create_strain] == '2'
      strain = select_or_new_strain
    else
      strain = Strain.default_strain_for_organism(organism_id)
    end
    @specimen.strain = strain

    #Add creators
    AssetsCreator.add_or_update_creator_list(@specimen, params[:creators])
    respond_to do |format|
      if @specimen.save
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

    #if no strain is selected, create/select the default strain
    if params[:specimen][:strain_id] == '0' || params[:specimen][:strain_id] == ''
      strain = Strain.default_strain_for_organism params[:organism]
      @specimen.strain = strain
    end

    #update creators
    AssetsCreator.add_or_update_creator_list(@specimen, params[:creators])

    if @specimen.save
      sop_ids.each do |sop_id|
        sop= Sop.find sop_id
        existing = @specimen.sop_masters.select { |ss| ss.sop == sop }
        if existing.blank?
          SopSpecimen.create!(:sop_id => sop_id, :sop_version => sop.version, :specimen_id => @specimen.id)
        end
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

  #if the strain doesnt get changed from UI, just select that strain
  #otherwise create the new one
  def select_or_new_strain
    if params['strain']['id'].blank?
      new_strain
    else
      strain = Strain.find_by_id(params['strain']['id'])
      if strain
        attributes = strain.attributes
        strain_params = params[:strain]
        flag = true
        flag =  flag && (compare_attribute attributes['title'], strain_params['title'])
        flag =  flag && (compare_attribute attributes['organism_id'].to_s, strain_params['organism_id'])
        flag =  flag && (compare_attribute attributes['synonym'], strain_params['synonym'])
        flag =  flag && (compare_attribute attributes['comment'], strain_params['comment'])
        flag =  flag && (compare_attribute attributes['provider_id'].to_s, strain_params['provider_id'])
        flag =  flag && (compare_attribute attributes['provider_name'], strain_params['provider_name'])
        genotype_array = []
        unless params[:strain][:genotypes_attributes].blank?
          params[:strain][:genotypes_attributes].each_value do |value|
            genotype_array << [value['gene_attributes']['title'], value['modification_attributes']['title']]
          end
        end
        flag = flag && (compare_genotypes strain.genotypes.collect { |genotype| [genotype.gene.try(:title), genotype.modification.try(:title)] }, genotype_array)
        phenotype_description = []
        unless params[:strain][:phenotypes_attributes].blank?
          params[:strain][:phenotypes_attributes].each_value do |value|
            phenotype_description << value['description']
          end
        end
        flag = flag && (compare_attribute strain.phenotypes.collect(&:description).sort, phenotype_description.sort)
        if flag
          strain
        else
          new_strain
        end
      end
    end
  end

  def compare_attribute attr1, attr2
    if attr1.blank? and attr2.blank?
      true
    elsif attr1 == attr2
      true
    else
      false
    end
  end

  def compare_genotypes array1, array2
    array1.sort!
    array2.sort!
    if array1.blank? and array2.blank?
      true
    elsif array1 == array2
      true
    else
      false
    end
  end

  def new_strain
    strain = Strain.new
    # to delete id hash which is saved in the hidden id field (automatically generated in form with fields_for)
    try_block {
      params[:strain][:genotypes_attributes].each_value do |genotype_value|
        genotype_value.delete_if { |k, v| k=="id" }
        genotype_value[:gene_attributes].delete_if { |k, v| k=="id" }
        genotype_value[:modification_attributes].delete_if { |k, v| k=="id" }
      end
      params[:strain][:phenotypes_attributes].each_value do |value|
        value.delete_if { |k, v| k=="id" }
      end
    }

    strain.attributes = params[:strain]


    strain
  end

end
