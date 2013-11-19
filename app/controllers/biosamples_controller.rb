class BiosamplesController < ApplicationController
  include Seek::BreadCrumbs

  before_filter :biosamples_enabled?

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
        render :json => {:status => 200, :strains => strains.sort_by(&:title).reject{|s| s.is_dummy}.select(&:can_view?).collect{|strain| [strain.id, strain.info]}}
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
    if object && object.is_a?(Sample)
       specimen = object.specimen
       id_column = Seek::Config.is_virtualliver ? 8 : 6
    end
    render :update do |page|
      if object.can_delete? && object.destroy
        page.call :removeRowAfterDestroy, "#{params[:class]}_table", object.id, params[:id_column_position]
        page.call :updateSpecimenRow, specimen_row_data(specimen),id_column if specimen
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
    specimens_with_default_strain =[]
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
    if Seek::Config.is_virtualliver && params[:organism_ids]
      organism_ids = params[:organism_ids].split(",")
      organism_ids.each do |organism_id|
       default_strains = Strain.find_all_by_title_and_organism_id "default", organism_id
       default_strains.each do |default_strain|
         strains << default_strain
         specimens_with_default_strain = default_strain.specimens.select(&:can_view?)
         specimens_of_strains |= specimens_with_default_strain
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
        strain = new_strain(params[:strain])
        strain.policy.set_attributes_with_sharing params[:sharing], strain.projects
        render :update do |page|
          if strain.save
            page.call 'RedBox.close'
            page.call :loadNewStrainAfterCreation, strain_row_data(strain), strain.organism.title
          else
            page.alert("Fail to create new strain. #{strain.errors.full_messages}")
          end
        end
      else
        render :update do |page|
          page.alert("You are not allowed to create a new strain, you may login first")
        end
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
