class BiosamplesController < ApplicationController
  def existing_strains
      strains_of_organisms = []
      organisms = []
      if params[:organism_ids]
        organism_ids = params[:organism_ids].split(',')
        organism_ids.each do |organism_id|
          organism=Organism.find_by_id(organism_id)
          if organism
            organisms << organism
            strains=organism.try(:strains)
            strains_of_organisms |= strains ? strains.reject { |s| s.is_dummy? } : strains
          end
        end
      end
      render :update do |page|
          page.replace_html 'existing_strains', :partial=>"biosamples/existing_strains", :object=>strains_of_organisms, :locals=>{:organisms=>organisms}
      end
  end

  def create_strain_popup
    strain = Strain.find_by_id(params[:strain_id])
    respond_to do  |format|
      if current_user.try(:person).try(:member?)
        format.html{render :partial => 'biosamples/create_strain_popup', :locals => {:strain => strain}}
      else
        flash[:error] = "You are not authorized to create new strain. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html {redirect_to :back}
      end
    end
  end

  def new_strain_form
    strain = Strain.find_by_id(params[:id]) || Strain.new
    render :update do |page|
      page.replace_html 'strain_form', :partial=>"biosamples/strain_form",:locals=>{:strain => strain}
    end
  end

  def existing_specimens
    specimens_of_strains = []
    strains = []
    if params[:strain_ids]
      strain_ids = params[:strain_ids].split(',')
      strain_ids.each do |strain_id|
        strain=Strain.find_by_id(strain_id)
        if strain
          strains << strain
          specimens=strain.specimens
          specimens_of_strains |= specimens.select(&:can_view?)
        end
      end
    end

    render :update do |page|
        page.replace_html 'existing_specimens', :partial=>"biosamples/existing_specimens",:object=>specimens_of_strains, :locals=>{:strains=>strains}
    end
  end

  def existing_samples
    samples_of_specimens = []
    specimens = []
    if params[:specimen_ids]
      specimen_ids = params[:specimen_ids].split(',')
      specimen_ids.each do |specimen_id|
        specimen=Specimen.find_by_id(specimen_id)
        if specimen and specimen.can_view?
        specimens << specimen
        samples=specimen.try(:samples)
        samples_of_specimens |= samples.select(&:can_view?)
          end
      end
    end
    render :update do |page|
        page.replace_html 'existing_samples', :partial=>"biosamples/existing_samples",:object=>samples_of_specimens,:locals=>{:specimens=>specimens}
    end
  end

  def create_sample_popup
    sample = Sample.find_by_id(params[:sample_id])
    unless sample
      specimen = Specimen.find_by_id(params[:specimen_id])
    else
      specimen = sample.specimen
    end
    respond_to do  |format|
      if current_user.try(:person).try(:member?)
        format.html{render :partial => 'biosamples/create_sample_popup', :locals => {:sample => sample, :specimen => specimen}}
      else
        flash[:error] = "You are not authorized to create new sample. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html {redirect_to :back}
      end
    end
  end

  def create_specimen_sample
    params[:sharing][:permissions] = nil

    sample = Sample.new(params[:sample])

    sop_ids = []

    specimen = Specimen.find_by_id(params[:specimen][:id])
    if specimen.nil?
      specimen = Specimen.new(params[:specimen])
      sop_ids = (params[:specimen_sop_ids].nil? ? [] : params[:specimen_sop_ids].reject(&:blank?))||[]
      specimen.policy.set_attributes_with_sharing params[:sharing], sample.projects
      #if no strain is selected, create/select the default strain
      if params[:specimen][:strain_id] == '0'
        strain = Strain.default_strain_for_organism params[:organism_id]
        specimen.strain = strain
      end
      #Add creators
      AssetsCreator.add_or_update_creator_list(specimen, params[:creators])
    end
    sample.policy.set_attributes_with_sharing params[:sharing], sample.projects
    sample.specimen = specimen
    respond_to do |format|
      if specimen.save && sample.save
        sop_ids.each do |sop_id|
          sop= Sop.find sop_id
          SopSpecimen.create!(:sop_id => sop_id, :sop_version=> sop.version, :specimen_id=>specimen.id)
        end
      else
        specimen_error_messages = ''
        specimen.errors.full_messages.each do |e_m|
          specimen_error_messages << "cell culture #{e_m.downcase}. "
        end
        sample_error_messages = ''
        sample.errors.full_messages.each do |e_m|
          sample_error_messages << "sample #{e_m.downcase}. "
        end
        flash[:error] = "Fail to create new sample: #{specimen_error_messages}#{sample_error_messages}"
      end
      format.html { redirect_to :back }
    end
  end

  def create_strain
      #No need to process if current_user is not a project member, because they cant go here from UI
      if current_user.try(:person).try(:member?)
        strain = select_or_new_strain
        render :update do |page|
          if strain.save
            page.reload
            #page.call "check_show_existing_strains('strain_organism_ids', 'existing_strains', '')"
          else
            page.alert("Fail to create new strain. #{strain.errors.full_messages}")
          end
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
        unless params[:genotypes].blank?
          params[:genotypes].each_value do |value|
            genotype_array << [value['gene']['title'], value['modification']['title']]
          end
        end
        flag =  flag && (compare_genotypes strain.genotypes.collect{|genotype| [genotype.gene.try(:title), genotype.modification.try(:title)]}, genotype_array)
        phenotype_description = []
        unless params[:phenotypes].blank?
          params[:phenotypes].each_value do |value|
            phenotype_description << value['description'] unless value["description"].blank?
          end
        end
        flag =  flag && (compare_attribute strain.phenotype.try(:description), phenotype_description.join('$$$'))
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

      #phenotypes
      phenotypes_params = params["phenotypes"]
      phenotype_description = []
      unless phenotypes_params.blank?
        phenotypes_params.each_value do |value|
          phenotype_description << value["description"] unless value["description"].blank?
        end
      end
      unless phenotype_description.blank?
        strain.phenotype = Phenotype.new(:description => phenotype_description.join('$$$'))
      end

      #genotype
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
end
