module AssaysHelper

  #assays that haven't already been associated with a study
  def assays_available_for_study_association
    Assay.where(['study_id IS NULL'])
  end

  #only data files authorised for show, and belonging to projects matching current_user
  def data_files_for_assay_association
    data_files=DataFile.find(:all, :include => :asset)
    data_files=data_files.select { |df| current_user.person.member_of?(df.projects) }
    Authorization.authorize_collection("view", data_files, current_user)
  end

  def assay_organism_list_item assay_organism
    result = link_to assay_organism.organism.title, assay_organism.organism
    if assay_organism.strain
      result += " : "
      result += link_to h(assay_organism.strain.info), assay_organism.strain, {:class => "assay_strain_info"}
    end

    if assay_organism.tissue_and_cell_type
      result += " : "
      result += link_to h(assay_organism.tissue_and_cell_type.title), assay_organism.tissue_and_cell_type, {:class => "assay_tissue_and_cell_type_info"}
    end

    if assay_organism.culture_growth_type
      result += " (#{assay_organism.culture_growth_type.title})"
    end
    return result.html_safe
  end


  def authorised_assays projects=nil,action="edit"
    authorised_assets(Assay, projects, action)
  end


  def list_assay_organisms attribute, assay_organisms, html_options={}, none_text="Not Specified"

    result= "<p class='#{html_options[:class]}' id='#{html_options[:id]}'> <b>#{attribute}</b>: "

    result += append_list_assay_organisms(assay_organisms)
    result += "</p>"

    return result.html_safe
  end

  def describe_organism_and_strain_for_list(organism, strain)
    result = ""
    if organism
      result += link_to organism.title, organism, {:class => "assay_organism_info"}
    end

    if strain && !strain.is_dummy? && strain.can_view?
      result += " :<span class='strain_info'> "
      result += link_to strain.info, strain, {:class => "strain_info"}
      result += "</span>"
    end
    result
  end


  def append_list_assay_organisms assay_organisms
    result=""

    organism=nil
    strain = nil
    culture_growth_type=nil

    organisms =[]
    strains =[]
    culture_growth_types =[]
    tissue_and_cell_types = []

    group_count = 0

    assay_organisms.each do |ao|

      if organism == ao.organism and strain == ao.strain and culture_growth_type == ao.culture_growth_type
        tissue_and_cell_types[group_count].push ao.tissue_and_cell_type
      else
        organism = ao.organism
        strain = ao.strain
        tissue_and_cell_type = ao.tissue_and_cell_type
        culture_growth_type = ao.culture_growth_type

        organisms[group_count] = organism
        strains[group_count] = strain
        culture_growth_types[group_count] = culture_growth_type

        group_count += 1
        tissue_and_cell_types[group_count] =[]
        tissue_and_cell_types[group_count].push(tissue_and_cell_type)
      end
    end

    for group_index in 1..group_count do

      organism = organisms[group_index-1]
      strain = strains[group_index-1]
      culture_growth_type = culture_growth_types[group_index-1]

      one_group_tissue_and_cell_types = tissue_and_cell_types[group_index]

      result += describe_organism_and_strain_for_list(organism, strain)

      if one_group_tissue_and_cell_types.compact.length > 0
        result += " : "
        one_group_tissue_and_cell_types = one_group_tissue_and_cell_types.compact
        one_group_tissue_and_cell_types.each do |tt|
          if tt
            result += " [" if tt== one_group_tissue_and_cell_types.first
            result += link_to h(tt.title), tt
            result += "|" unless tt == one_group_tissue_and_cell_types.last
            result += "]" if tt == one_group_tissue_and_cell_types.last
          end
        end
      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
      result += ", " unless group_index==group_count
    end

    return result.html_safe
  end

  def direction_options
    dirs = [AssayAsset::Direction::NODIRECTION,
     AssayAsset::Direction::INCOMING,
     AssayAsset::Direction::OUTGOING]

    options_for_select(dirs.map { |dir| [direction_name(dir), dir] })
  end

  def direction_name(direction)
    case direction
      when AssayAsset::Direction::INCOMING
        'Incoming'
      when AssayAsset::Direction::OUTGOING
        'Outgoing'
      else
        'No direction'
    end
  end

end
