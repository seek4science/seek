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

end
