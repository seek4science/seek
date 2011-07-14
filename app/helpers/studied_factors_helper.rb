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



  def no_comma_for_decimal
    check_string = ''
    if self.controller_name.downcase == 'studied_factors'
      check_string.concat(params[:studied_factor][:start_value].to_s + params[:studied_factor][:end_value].to_s + params[:studied_factor][:standard_deviation].to_s)
    elsif self.controller_name.downcase == 'experimental_conditions'
      check_string.concat(params[:experimental_condition][:start_value].to_s + params[:experimental_condition][:end_value].to_s)
    end

    if check_string.match(',')
         render :update do |page|
           page.alert('Please use point instead of comma for decimal number')
         end
      return false
    else
      return true
    end
  end
end
