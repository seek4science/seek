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
            strains_of_organisms |= strains ? strains.without_default : strains
          end
        end
      end
      render :update do |page|
          page.replace_html 'existing_strains', :partial=>"biosamples/existing_strains", :object=>strains_of_organisms, :locals=>{:organisms=>organisms}
      end
  end

  def strains_of_selected_organism
    strains = []
    if params[:organism_id]
      organism = Organism.find_by_id params[:organism_id].to_i
      strains |= organism.strains if organism
    end
    respond_to do |format|
          format.json{
            render :json => {:status => 200, :strains => strains.sort_by(&:title).without_default.collect{|strain| [strain.id, strain.info]}}
          }
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
    sample = Sample.new
    specimen = Specimen.find_by_id(params[:specimen_id]) || Specimen.new
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
    params[:sharing][:permissions] = nil if params[:sharing]

    sample = Sample.new(params[:sample])

    sop_ids = []
    is_new_specimen = false
    specimen = Specimen.find_by_id(params[:specimen][:id])
    if specimen.nil?
      is_new_specimen =true
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
    render :update do |page|
      if sample.save
        sop_ids.each do |sop_id|
          sop= Sop.find sop_id
          SopSpecimen.create!(:sop_id => sop_id, :sop_version=> sop.version, :specimen_id=>specimen.id)
        end
        page.call 'RedBox.close'
        if is_new_specimen
           #also show specimen of the default strain, after this specimen is created(need to ask for this)
           specimen_array = ['Strain ' + specimen.strain.info + "(ID=#{specimen.strain.id})",
                            (check_box_tag "selected_specimen_#{specimen.id}", specimen.id, false, {:onchange => remote_function(:url => {:controller => 'biosamples', :action => 'existing_samples'}, :with => "'specimen_ids=' + getSelectedSpecimens()") + ";show_existing_samples();" }),
                            specimen.title, specimen.born_info, specimen.culture_growth_type.try(:title), specimen.contributor.try(:person).try(:name), specimen.id, asset_version_links(specimen.sops).join(", ")]

            page.call :loadNewSpecimenAfterCreation, specimen_array, specimen.strain.id
        else
          sample_array = [sample.specimen_info,
                          (link_to sample.title, sample_path(sample.id), {:target => '_blank'}),
                          sample.lab_internal_number, sample.sampling_date_info, sample.age_at_sampling, sample.provider_name_info, sample.id, sample.comments]

          page.call :loadNewSampleAfterCreation, sample_array
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
        page.alert("Fail to create: #{specimen_error_messages}#{sample_error_messages}")
        page['create_specimen_sample'].disabled = false
        page['create_specimen_sample'].value = 'Create'
      end
    end
  end

  def create_strain
      #No need to process if current_user is not a project member, because they cant go here from UI
      if current_user.try(:person).try(:member?)
        strain = select_or_new_strain
        strain.policy.set_attributes_with_sharing params[:sharing], strain.projects
        render :update do |page|
          if strain.save
            page.call 'RedBox.close'
            strain_array = [(link_to strain.organism.title, organism_path(strain.organism.id), {:target => '_blank'}),
                            (check_box_tag "selected_strain_#{strain.id}", strain.id, false, :onchange => remote_function(:url => {:controller => 'biosamples', :action => 'existing_specimens'}, :with => "'strain_ids=' + getSelectedStrains()") +";show_existing_specimens();hide_existing_samples();"),
                            strain.title, strain.genotype_info, strain.phenotype_info, strain.id, strain.synonym, strain.comment, strain.parent_strain]

            page.call :loadNewStrainAfterCreation, strain_array, strain.organism.title
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
        flag =  flag && (compare_attribute strain.phenotypes.collect(&:description).sort, phenotype_description.sort)
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
      phenotype_description.each do |description|
        strain.phenotypes << Phenotype.new(:description => description)
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
