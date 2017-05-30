module Seek
  module FactorStudied
    def find_or_new_substances(substances)
      substances ||= ''
      substances = substances.split(',')

      result = []
      new_substances = []

      substances.each do |substance|
        substance.strip!
        if (compound = (Compound.find_by_name(substance) || Synonym.find_by_name(substance))).nil?
          new_substances << substance
        else
          result << compound
        end
      end

      new_substances.each do |new_substance|
        # call the webservice to retrieve the substance annotation from sabiork
        # the annotation is stored in a hash, which keys: recommended_name, synonyms, sabiork_id, chebi_ids, kegg_ids
        compound_annotation = Seek::SabiorkWebservices.new.get_compound_annotation(new_substance)
        # compound_annotation = {'recommended_name' => "#{new_substance}", 'synonyms' => ["#{new_substance}_1","#{new_substance}_2"], 'sabiork_id' => 50, 'chebi_ids' => [CHEBI:15377], 'kegg_ids' => ["C00001", "C00002"]}
        unless compound_annotation.blank?
          # retrieve or create compound with the recommended_name
          recommended_name = compound_annotation['recommended_name']
          c = Compound.find_by_name(recommended_name) ? Compound.find_by_name(recommended_name) : Compound.new(name: recommended_name)

          # create new or update mappings and mapping_links
          c = new_or_update_mapping_links c, compound_annotation

          # create new or update synonyms
          c = new_or_update_synonyms c, compound_annotation

          # if new_substance is a new synonym of an existing compound,need to save that compound and return that synonym to the result
          if !c.new_record? && c.save
            s = c.synonyms.select { |s| s.title == new_substance }
            result.push s.first unless s.first.blank?
          else
            result.push c
          end
        else
          # if the webservice doesn't return any value: create compound with the name new_substance
          c = Compound.new(name: new_substance)
          result.push c
        end
      end
      result
  end

    def update_substance(substance)
      unless substance.blank?
        # call the webservice to retrieve the substance annotation from sabiork
        # the annotation is stored in a hash, which keys: recommended_name, synonyms, sabiork_id, chebi_ids, kegg_ids
        compound_annotation = Seek::SabiorkWebservices.new.get_compound_annotation(substance)
        # compound_annotation = {'recommended_name' => "#{new_substance}", 'synonyms' => ["#{new_substance}_1","#{new_substance}_2"], 'sabiork_id' => 50, 'chebi_ids' => [CHEBI:15377], 'kegg_ids' => ["C00001", "C00002"]}
        unless compound_annotation.blank?
          # retrieve or create compound with the recommended_name
          recommended_name = compound_annotation['recommended_name']
          c = Compound.find_by_name(recommended_name) ? Compound.find_by_name(recommended_name) : Compound.new(name: recommended_name)

          # create new or update mappings and mapping_links
          c = new_or_update_mapping_links c, compound_annotation

          # create new or update synonyms
          c = new_or_update_synonyms c, compound_annotation

          return c
        else
          # if the webservice doesn't return any value: find the compound or create compound with the name substance
          c = Compound.find_by_name(substance) ? Compound.find_by_name(substance) : Compound.new(name: substance)
          return c
        end
      end
    end

    def no_comma_for_decimal
      check_string = ''
      if controller_name.downcase == 'studied_factors' && params[:studied_factor].is_a?(Hash)
        check_string.concat(params[:studied_factor][:start_value].to_s + params[:studied_factor][:end_value].to_s + params[:studied_factor][:standard_deviation].to_s)
      elsif controller_name.downcase == 'experimental_conditions' && params[:experimental_condition].is_a?(Hash)
        check_string.concat(params[:experimental_condition][:start_value].to_s)
      end

      if check_string =~ /,/
        render :update do |page|
          page.alert('Please use point instead of comma for decimal number')
        end
        return false
      else
        return true
      end
    end

    def known_substances(known_substance_ids_and_types)
      known_substances = []
      known_substance_ids_and_types.each do |text|
        id, type = text.split(',')
        id = id.strip
        type = type.strip.capitalize.constantize
        known_substances.push(type.find(id)) if type.find(id)
      end
      known_substances
    end

    def new_or_update_mapping_links(compound, compound_annotation)
      # create the mappings and mapping_links
      sabiork_id = compound_annotation['sabiork_id']
      chebi_ids = compound_annotation['chebi_ids']
      kegg_ids = compound_annotation['kegg_ids']
      # destroy the mapping_links if the recommended_compound exists
      compound.mapping_links.each(&:destroy) unless compound.new_record?
      mapping_links = []
      # not always every ids are provided, proceed 8 possibilities of the 3 ids combination
      if sabiork_id.blank?
        if kegg_ids.blank?
          unless chebi_ids.blank?
            chebi_ids.each do |chebi_id|
              mapping = new_or_update_mapping sabiork_id, chebi_id
              mapping_links.push MappingLink.new(substance: compound, mapping: mapping)
            end
          end
        else
          if chebi_ids.blank?
            kegg_ids.each do |kegg_id|
              mapping = new_or_update_mapping sabiork_id, nil, kegg_id
              mapping_links.push MappingLink.new(substance: compound, mapping: mapping)
            end
          else
            kegg_ids.each do |kegg_id|
              # only create new mapping when it doesn't exist
              chebi_ids.each do |chebi_id|
                mapping = new_or_update_mapping sabiork_id, chebi_id, kegg_id
                mapping_links.push MappingLink.new(substance: compound, mapping: mapping)
              end
            end
          end
        end
      else
        if kegg_ids.blank?
          if chebi_ids.blank?
            mapping = new_or_update_mapping sabiork_id
            mapping_links.push MappingLink.new(substance: compound, mapping: mapping)
          else
            chebi_ids.each do |chebi_id|
              mapping = new_or_update_mapping sabiork_id, chebi_id
              mapping_links.push MappingLink.new(substance: compound, mapping: mapping)
            end
          end
        else
          if chebi_ids.blank?
            kegg_ids.each do |kegg_id|
              mapping = new_or_update_mapping sabiork_id, nil, kegg_id
              mapping_links.push MappingLink.new(substance: compound, mapping: mapping)
            end
          else
            kegg_ids.each do |kegg_id|
              # only create new mapping when it doesn't exist
              chebi_ids.each do |chebi_id|
                mapping = new_or_update_mapping sabiork_id, chebi_id, kegg_id
                mapping_links.push MappingLink.new(substance: compound, mapping: mapping)
              end
            end
          end
       end
      end

      compound.mapping_links = mapping_links
      compound
    end

    def new_or_update_synonyms(compound, compound_annotation)
      # create synonyms and the relations with compound
      synonyms = compound_annotation['synonyms']
      # if the compound exists, create only the new synonyms which the compound hasn't had
      existing_synonyms = []
      unless compound.new_record?
        compound.synonyms.each do |s|
          existing_synonyms.push s.name
        end
      end
      synonyms -= existing_synonyms
      synonyms.each do |s|
        compound.synonyms << Synonym.new(name: s, substance: compound)
      end
      compound
    end

    def new_or_update_mapping(sabiork_id, chebi_id = nil, kegg_id = nil)
      mappings = Mapping.where(['sabiork_id = ? AND chebi_id = ? AND kegg_id = ?', sabiork_id, chebi_id, kegg_id])
      mapping = mappings.blank? ? Mapping.new(sabiork_id: sabiork_id, chebi_id: chebi_id, kegg_id: kegg_id) : mappings.first
      mapping
    end

    #   def create_annotation entity, owner=User.current_user
    #     unless owner.blank?
    #       annotation = Annotation.new(:attribute_name => params[:annotation][:attribute_name],
    #                         :value => params[:annotation][:value],
    #                         :source => owner,
    #                         :annotatable => entity)
    #       annotation.save!
    #     end
    #   end
    #
    #   def create_or_update_annotation entity, owner=User.current_user
    #     unless owner.blank?
    #       current = entity.annotations_with_attribute(params[:annotation][:attribute_name])
    #       unless annotation.blank?
    #         annotation.update_attributes!({:attribute_name => params[:annotation][:attribute_name], :value => params[:annotation][:value]})
    #       else
    #         create_annotation owner
    #       end
    #     end
    #   end
  end
end
