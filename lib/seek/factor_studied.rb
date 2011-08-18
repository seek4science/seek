module Seek

  module FactorStudied
    def find_or_new_substances(new_substances, known_substance_ids_and_types)
    result = []
    known_substances = known_substances known_substance_ids_and_types
    new_substances, known_substances = check_if_new_substances_are_known new_substances, known_substances
    result |= known_substances

    new_substances.each do |new_substance|
       #call the webservice to retrieve the substance annotation from sabiork
       #the annotation is stored in a hash, which keys: recommended_name, synonyms, sabiork_id, chebi_id, kegg_ids
       #compound_annotation = Seek::SabiorkWebservices.new().get_compound_annotation(new_substance)
       compound_annotation = {'recommended_name' => "#{new_substance}", 'synonyms' => ["#{new_substance}_1","#{new_substance}_2"], 'sabiork_id' => 50, 'chebi_id' => "CHEBI:15377", 'kegg_ids' => ["C00001", "C00002"]}
       unless compound_annotation.blank?
         #retrieve or create compound with the recommended_name
         recommended_name = compound_annotation["recommended_name"]
         c = Compound.find_by_name(recommended_name) ? Compound.find_by_name(recommended_name) : Compound.new(:name => recommended_name)

         #create new or update mappings and mapping_links
         c = new_or_update_mapping_links c, compound_annotation

         #create new or update synonyms
         c = new_or_update_synonyms c, compound_annotation

         #if new_substance is a new synonym of an existing compound,need to save that compound and return that synonym to the result
         if !c.new_record? and c.save
            result.push Synonym.find(:all, :conditions => ['name = ? AND substance_type = ? AND substance_id = ?', new_substance,c.class.name, c.id]).first
         else
           result.push c
         end
       else
         #if the webservice doesn't return any value: create compound with the name new_substance
         c = Compound.new(:name => new_substance)
         result.push c
       end
    end
    result
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

    protected
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
    return fixed_new_substances, known_substances
  end

  def known_substances known_substance_ids_and_types
    known_substances = []
    known_substance_ids_and_types.each do |text|
      id, type = text.split(',')
      id = id.strip
      type = type.strip.capitalize.constantize
      known_substances.push(type.find(id)) if type.find(id)
    end
    known_substances
  end

  def new_or_update_mapping_links compound, compound_annotation
    #create the mappings and mapping_links
     sabiork_id = compound_annotation["sabiork_id"]
     chebi_id = compound_annotation["chebi_id"]
     kegg_ids = compound_annotation["kegg_ids"]
     #destroy the mapping_links if the recommended_compound exists
     if !compound.new_record?
       compound.mapping_links.each do |ml|
         ml.destroy
       end
     end
     mapping_links = []
     kegg_ids.each do |kegg_id|
       #only create new mapping when it doesn't exist
       mappings = Mapping.find(:all, :conditions => ['sabiork_id = ? AND chebi_id = ? AND kegg_id = ?', sabiork_id, chebi_id, kegg_id])
       mapping = mappings.blank? ? Mapping.new(:sabiork_id => sabiork_id, :chebi_id => chebi_id, :kegg_id => kegg_id) :  mappings.first
       mapping_links.push MappingLink.new(:substance => compound, :mapping => mapping)
     end
     compound.mapping_links = mapping_links
     compound
  end

  def new_or_update_synonyms compound, compound_annotation
   #create synonyms and the relations with compound
     synonyms = compound_annotation["synonyms"]
     #if the compound exists, create only the new synonyms which the compound hasn't had
     existing_synonyms = []
     if !compound.new_record?
       compound.synonyms.each do |s|
         existing_synonyms.push s.name
       end
     end
       synonyms = synonyms - existing_synonyms
       synonyms.each do |s|
          compound.synonyms << Synonym.new(:name => s, :substance => compound)
       end
     compound
  end
  end

end