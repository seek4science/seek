module StudiedFactorsHelper
   def all_substances
      #Find all substances from Compounds table, Synonyms table, Protein table and Mixtures table
      # concat substance name with the type of the substance
      # concat substance id with the type of the substance
      all_substances = []

      #From Compounds table
      compounds =  Compound.find(:all)
      compounds.each do |compound|
        s = Substance.new
        s.id = compound.id.to_s + ',Compound'
        s.name = compound.name
        all_substances.push s
      end

      #From Synonyms table
      synonyms = Synonym.find(:all)
      synonyms.each do |synonym|
        s = Substance.new
        s.id = synonym.id.to_s + ',Synonym'
        s.name = synonym.name + " (#{synonym.substance.name})"
        all_substances.push s
      end
      all_substances
   end

   def tagged_substances resource
      tagged_substances = []
      if !resource.nil? && !resource.substance.nil?
        substance = resource.substance
        s = Substance.new
        s.id = substance.id.to_s + ",#{substance.class.name}"
        s.name = substance.name
        tagged_substances.push s
      end
      tagged_substances
   end

  class Substance
     def id
       @id
     end
     def id=id
       @id = id
     end

     def name
       @name
     end
     def name=name
       @name = name
     end
  end

  def uniq_fs_or_ec fs_or_ec_array=[]
    result = []
    uniq_fs_or_ec_field_array = []
    fs_or_ec_array.each do |fs_or_ec|
      compare_field = [fs_or_ec.measured_item_id, fs_or_ec.start_value, fs_or_ec.end_value, fs_or_ec.unit_id, try_block{fs_or_ec.standard_deviation}, fs_or_ec.substance_id, fs_or_ec.substance_type]
      if !uniq_fs_or_ec_field_array.include?compare_field
        uniq_fs_or_ec_field_array.push compare_field
        result.push fs_or_ec
      end
    end
    result
  end

  #get the fses_or_ecs of the project the asset belongs to, but dont include the fses_or_ecs of that asset
  def fses_or_ecs_of_project asset, fs_or_ec
    neighboring_assets = asset.class.find(:all).select do |a|
      projects_in_common = (a.projects & asset.projects)
      a != asset and !projects_in_common.empty?
    end
    neighboring_assets.select(&:can_view?).collect {|a| a.send(fs_or_ec)}.flatten
  end

end
