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

   def find_or_create_substance(new_substances, known_substance_ids_and_types)
    known_substances = []
    known_substance_ids_and_types.each do |text|
      id, type = text.split(',')
      id = id.strip
      type = type.strip.capitalize.constantize
      known_substances.push(type.find(id)) if type.find(id)
    end
    new_substances, known_substances = check_if_new_substances_are_known new_substances, known_substances
    #no substance
    if (new_substances.size + known_substances.size) == 0
      nil
    #one substance
    elsif (new_substances.size + known_substances.size) == 1
      if !known_substances.empty?
        known_substances.first
      else
        c = Compound.new(:name => new_substances.first)
          if  c.save
            c
          else
            nil
          end
      end
    #FIXME: update code when mixture table is created
    else
      nil
    end
  end

  #double checks and resolves if any new compounds are actually known. This can occur when the compound has been typed completely rather than
  #relying on autocomplete. If not fixed, this could have an impact on preserving compound ownership.
  def check_if_new_substances_are_known new_substances, known_substances
    fixed_new_substances = []
    new_substances.each do |new_substance|
      substance=Compound.find_by_name(new_substance.strip) || Synonym.find_by_name(new_substance.strip)
      if substance.nil?
        fixed_new_substances << new_substance
      else
        known_substances << substance unless known_substances.include?(substance)
      end
    end
    return new_substances, known_substances
  end
end
