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
    #uniq_fs_or_ec_field_array =  fs_or_ec_array.collect{|fs_or_ec| [fs_or_ec.measured_item.title, fs_or_ec.start_value, fs_or_ec.end_value, fs_or_ec.unit.title, fs_or_ec.standard_deviation, fs_or_ec.substance_id, fs_or_ec.substance_type]}
    #uniq_fs_or_ec_field_array.uniq!
    uniq_fs_or_ec_field_array = []
    fs_or_ec_array.each do |fs_or_ec|
      compare_field = [fs_or_ec.measured_item.title, fs_or_ec.start_value, fs_or_ec.end_value, fs_or_ec.unit.title, fs_or_ec.standard_deviation, fs_or_ec.substance_id, fs_or_ec.substance_type]
      if !uniq_fs_or_ec_field_array.include?compare_field
        uniq_fs_or_ec_field_array.push compare_field
        result.push fs_or_ec
      end
    end
    result
  end

  def fses_or_ecs_of_project asset, fs_or_ec, project_id
    asset_class = asset.constantize
    fs_or_ec_array= []
    #FIXME: add :include in the query
    asset_items = asset_class.find(:all, :conditions => ["project_id = ?", project_id])
    asset_items.each do |item|
      fs_or_ec_array |= item.send fs_or_ec if item.can_view?
    end
    fs_or_ec_array
  end

end
