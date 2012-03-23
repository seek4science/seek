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
        s.name = synonym.name + " (#{try_block{synonym.substance.name}.to_s})"
        all_substances.push s
      end
      all_substances
   end

   def tagged_substances resource
      tagged_substances = []
      link_table_name = (resource.class.name == 'StudiedFactor') ? 'studied_factor_links' : 'experimental_condition_links'
      if !resource.nil?
        (resource.send link_table_name).each do |ltn|
          substance = ltn.substance
          unless substance.blank?
            s = Substance.new
            s.id = substance.id.to_s + ",#{substance.class.name}"
            s.name = substance.name
            tagged_substances.push s
          end
        end
      end
      tagged_substances
   end

  class Substance

     #required to appear like a text tag
     alias_attribute :text,:name

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
    link_table_name = try_block{fs_or_ec_array.first.class.name == 'StudiedFactor'} ? 'studied_factor_links' : 'experimental_condition_links'
    fs_or_ec_array.each do |fs_or_ec|
      substances = fs_or_ec.send(link_table_name).collect{|ltn| ltn.substance}
      substances = substances.sort{|a,b| a.id <=> b.id}
      compare_field = [fs_or_ec.measured_item_id, fs_or_ec.start_value, try_block{fs_or_ec.end_value}, fs_or_ec.unit_id, try_block{fs_or_ec.standard_deviation}, substances]
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




