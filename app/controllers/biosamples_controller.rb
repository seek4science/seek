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

  
end
