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


end
