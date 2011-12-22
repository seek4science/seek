class StrainsController < ApplicationController
  before_filter :login_required
  before_filter :get_strains,:only=>[:existing_strains_for_assay_organism, :existing_strains, :existing_strains_for_create]
  before_filter :get_strain, :only =>:show_existing_strain

  def existing_strains
    render :update do |page|
      if @strains && @organism
        page.replace_html 'existing_strains', :partial=>"strains/existing_strains",:object=>@strains,:locals=>{:organism=>@organism}
      else
        page.insert_html :bottom, 'existing_strains',:text=>""
      end
    end
  end

  def existing_strains_for_create
    partial = "existing_strains_for_create"
    render :update do |page|
      if @strains && @organism
        page.replace_html partial, :partial=>"strains/#{partial}",:object=>@strains,:locals=>{:organism=>@organism}
      else
        page.insert_html :bottom, partial,:text=>""
      end
    end
  end

  def show_existing_strain
    render :update do |page|
      page.remove 'strain_form'
      page.insert_html :bottom, "create_based_on_existing_strain",:partial=>"strains/form",:locals=>{:strain => @strain, :action => params[:status], :organism_id => params[:organism_id], :display => true}
    end
  end

  def new_strain_form
    @strain = Strain.find_by_id(params[:id]) || Strain.new
    render :update do |page|
      page.remove 'strain_form'
      if params['checkbox_checked'] == '1'
        page.insert_html :bottom, "create_new_strain",:partial=>"strains/form",:locals=>{:strain => @strain, :organism_id => params[:organism_id], :display => true}
      else
        page.insert_html :bottom, "create_new_strain",:partial=>"strains/form",:locals=>{:strain => @strain, :organism_id => params[:organism_id], :display => false}
      end
    end
  end

  def create_strain_popup
    respond_to do  |format|
      format.html{render :partial => 'strains/create_strain_popup'}
    end
  end

  def create
    strain = select_or_new_strain
    respond_to do |format|
      if strain.save
        format.html {redirect_to :back}
      else
        flash[:error] = "Fail to create new strain. #{strain.errors.full_messages}"
        format.html {redirect_to :back}
      end
    end
  end

  def existing_strains_for_assay_organism
    render :update do |page|
      if @strains && @organism
        page.replace_html 'existing_strains_for_assay_organism', :partial=>"strains/existing_strains_for_assay_organism",:object=>@strains,:locals=>{:organism=>@organism}
      else
        page.insert_html :bottom, 'existing_strains_for_assay_organism',:text=>""
      end
    end
  end

  def get_strains
    if params[:organism_id]
      @organism=Organism.find_by_id(params[:organism_id])
      strains=@organism.try(:strains)
      @strains = strains ? strains.reject{|s| s.title == 'default' || s.id == params[:strain_id].to_i} : strains
    end
  end

  def get_strain
    if params[:id]
      @strain=Strain.find_by_id(params[:id])
    end
  end

  def show
    @strain=Strain.find(params[:id])
    respond_to do |format|
      format.xml
    end
  end
  
  def index
    @strains=Strain.all
    respond_to do |format|
      format.xml
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
        flag =  flag && (compare_attribute strain.phenotype.try(:description), params['phenotype']['description'])
        genotype_array = []
        unless params[:genotypes].blank?
          params[:genotypes].each_value do |value|
            genotype_array << [value['gene']['title'], value['modification']['title']]
          end
        end
        flag =  flag && (compare_genotypes strain.genotypes.collect{|genotype| [genotype.gene.try(:title), genotype.modification.try(:title)]}, genotype_array)
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
      strain = Strain.new()
      strain.attributes = params[:strain]
      phenotype = Phenotype.new()
      phenotype.attributes = params["phenotype"]
      if phenotype['description'].blank?
        strain.phenotype = nil
      else
        strain.phenotype = phenotype
      end

      genotypes_params = params["genotypes"]
      unless genotypes_params.blank?
        genotypes_params.each_value do |value|
          genotype = Genotype.new()
          gene = Gene.find_by_title(value['gene']['title']) || (Gene.new(:title => value['gene']['title']) unless value['gene']['title'].blank?)
          modification = Modification.find_by_title(value['modification']['title']) || (Modification.new(:title => value['modification']['title']) unless value['modification']['title'].blank?)
          genotype.gene = gene
          genotype.modification = modification
          strain.genotypes << genotype unless gene.blank?
        end
      end
      strain
  end

  def default_strain_for organism_id
    strain = Strain.find(:all, :conditions => ['organism_id=? and title=?', organism_id, 'default']).first
    unless strain
      strain = Strain.new(:title => 'default', :organism_id => organism_id)
      gene = Gene.find_by_title('wild-type') || Gene.create(:title => 'wild-type')
      genotype = Genotype.new(:gene => gene)
      phenotype = Phenotype.new(:description => 'wild-type')
      strain.genotypes = [genotype]
      strain.phenotype = phenotype
      strain.save
    end
    strain
  end

end
