module SubstancesHelper
  def all_substances
    # Find all substances from Compounds table, Synonyms table, Protein table and Mixtures table
    # concat substance name with the type of the substance
    # concat substance id with the type of the substance
    all_substances = []

    # From Compounds table
    Compound.find_each do |compound|
      all_substances << substance_for_compound(compound)
    end

    # From Synonyms table
    Synonym.find_each do |synonym|
      all_substances << substance_for_synonym(synonym)
    end
    all_substances
  end

  def substance_for_compound(compound)
    substance = Seek::ExperimentalFactors::Substance.new
    substance.id = compound.id.to_s + ',Compound'
    substance.name = compound.name
    substance
  end

  def substance_for_synonym(synonym)
    substance = Seek::ExperimentalFactors::Substance.new
    substance.id = synonym.id.to_s + ',Synonym'
    substance.name = synonym.name + " (#{synonym.try(:substance).try(:name)})"
    substance
  end

  def tagged_substances(resource)
    tagged_substances = []
    link_table_name = (resource.class.name == 'StudiedFactor') ? 'studied_factor_links' : 'experimental_condition_links'
    if resource
      (resource.send link_table_name).each do |experimental_factor|
        if experimental_factor.substance
          tagged_substances << substance_for_experimental_factor(experimental_factor.substance)
        end
      end
    end
    tagged_substances.map(&:name)
  end

  def substance_for_experimental_factor(substance)
    s = Seek::ExperimentalFactors::Substance.new
    s.id = substance.id.to_s + ",#{substance.class.name}"
    s.name = substance.name
    s
  end

  def uniq_fs_or_ec(fs_or_ec_array = [])
    result = []
    uniq_fs_or_ec_field_array = []
    link_table_name = (!fs_or_ec_array.empty? && fs_or_ec_array.first.class.name == 'StudiedFactor') ? 'studied_factor_links' : 'experimental_condition_links'
    fs_or_ec_array.each do |fs_or_ec|
      substances = fs_or_ec.send(link_table_name).collect(&:substance)
      substances = substances.sort { |a, b| a.id <=> b.id }
      end_value = fs_or_ec.respond_to?(:end_value) ? fs_or_ec.end_value : nil
      sd = fs_or_ec.respond_to?(:standard_deviation) ? fs_or_ec.standard_deviation : nil
      compare_field = [fs_or_ec.measured_item_id, fs_or_ec.start_value, end_value, fs_or_ec.unit_id, sd, substances]
      unless uniq_fs_or_ec_field_array.include? compare_field
        uniq_fs_or_ec_field_array.push compare_field
        result.push fs_or_ec
      end
    end
    result
  end

  # get the fses_or_ecs of the project the asset belongs to, but dont include the fses_or_ecs of that asset
  def fses_or_ecs_of_project(asset, fs_or_ec)
    visible = asset.class.all.select(&:can_view?) - [asset]
    neighboring_assets = visible.select do |other_asset|
      (other_asset.projects & asset.projects).any?
    end
    neighboring_assets.collect { |asset| asset.send(fs_or_ec) }.uniq.flatten
  end
end
