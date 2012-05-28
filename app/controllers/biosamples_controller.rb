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
            strains_of_organisms |= strains ? strains.reject{|s| s.is_dummy?}.select(&:can_view?) : strains
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
        render :json => {:status => 200, :strains => strains.sort_by(&:title).reject{|s| s.is_dummy?}.select(&:can_view?).collect{|strain| [strain.id, strain.info]}}
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

  def edit_strain_popup
    strain = Strain.find_by_id(params[:strain_id])
    respond_to do  |format|
      if current_user.can_edit?
        format.html{render :partial => 'biosamples/edit_strain_popup', :locals => {:strain => strain}}
      else
        flash[:error] = "You are not authorized to edit this strain."
        format.html {redirect_to :back}
      end
    end
  end

  def update_strain
    strain = Strain.find_by_id params[:strain][:id]
    strain.attributes = params[:strain]

    old_phenotypes = strain.phenotypes
    # Update new phenotypes
    updated_phenotypes = []
    phenotypes_params = params["phenotypes"]
    unless phenotypes_params.blank?
      phenotypes_params.each_value do |value|
        phenotype = Phenotype.find(:all, :conditions => ["description=? and strain_id=?", value["description"], strain.id]).first
        if phenotype
          updated_phenotypes << phenotype
        else
          updated_phenotypes << Phenotype.create(:description => value["description"], :strain_id => strain.id) unless value[:description].blank?
        end
      end
    end
    #Destroy uneeded phenotypes
    (old_phenotypes - updated_phenotypes.compact).each { |p| p.destroy }

    old_genotypes = strain.genotypes
    # Update new genotypes
    updated_genotypes = []
    genotypes_params = params["genotypes"]
    unless genotypes_params.blank?
      genotypes_params.each_value do |value|
        gene = Gene.find_by_title(value['gene']['title']) || (Gene.create(:title => value['gene']['title']) unless value['gene']['title'].blank?)
        modification = Modification.find_by_title(value['modification']['title']) || (Modification.create(:title => value['modification']['title']) unless value['modification']['title'].blank?)
        genotype = Genotype.find(:all, :conditions => ['gene_id=? and modification_id=? and strain_id=?', gene.id, modification.id, strain.id]).first
        if genotype
          updated_genotypes << genotype
        else
          updated_genotypes << Genotype.create(:gene_id => gene.id, :modification_id => modification.id, :strain_id => strain.id)
        end
      end
    end
    #Destroy uneeded genotypes
    (old_genotypes - updated_genotypes.compact).each { |g| g.destroy }

    if params[:sharing]
      strain.policy.set_attributes_with_sharing params[:sharing], strain.projects
    end
    render :update do |page|
      if strain.save
        strain.reload
        page.call 'RedBox.close'
        page.call :updateStrainRow, strain_row_data(strain), 5
      else
        page.alert("Fail to create new strain. #{strain.errors.full_messages}")
      end
    end

  end


  def destroy
    object=params[:class].capitalize.constantize.find(params[:id])
    render :update do |page|
      if object.can_delete? && object.destroy
        page.call :removeRowAfterDestroy, "#{params[:class]}_table", object.id, params[:id_column_position]
      else
        page.alert(object.errors.full_messages)
      end
    end
  end

  def strain_form
    strain = Strain.find_by_id(params[:id]) || Strain.new
    render :update do |page|
      page.replace_html 'strain_form', :partial=>"biosamples/strain_form",:locals=>{:strain => strain, :action => params[:strain_action]}
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
        page.call :scrollToElement, 'existing_specimens'
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
        page.call :scrollToElement, 'existing_samples'
    end
  end

  def create_strain
      #No need to process if current_user is not a project member, because they cant go here from UI
      if current_user.try(:person).try(:member?)
        strain = new_strain
        strain.policy.set_attributes_with_sharing params[:sharing], strain.projects
        render :update do |page|
          if strain.save
            page.call 'RedBox.close'
            page.call :loadNewStrainAfterCreation, strain_row_data(strain), strain.organism.title
          else
            page.alert("Fail to create new strain. #{strain.errors.full_messages}")
          end
        end
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

  def check_auth_strain
    if params[:specimen] and params[:specimen][:strain_id] and params[:specimen][:strain_id] != "0"
      strain = Strain.find_by_id(params[:specimen][:strain_id].to_i)
      if strain && !strain.can_view?
        error("You are not allowed to select this strain", "is invalid (no permissions)")
        return false
      end
    end
  end

end
