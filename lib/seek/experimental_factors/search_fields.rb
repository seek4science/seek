module Seek
  module ExperimentalFactors
    # search fields for the factors studied and experimental conditions
    module SearchFields
      def fs_search_fields
        exp_or_fs_search_fields studied_factors
      end

      def exp_conditions_search_fields
        exp_or_fs_search_fields experimental_conditions
      end

      def exp_or_fs_search_fields(things)
        things.collect do |ec|
          [ec.measured_item.title,
           ec.substances.collect do |sub|
             # FIXME: this makes the assumption that the synonym.substance appears like a Compound
             sub = sub.substance if sub.is_a?(Synonym)
             [sub.title] |
               (sub.respond_to?(:synonyms) ? sub.synonyms.collect(&:title) : []) |
               (sub.respond_to?(:mappings) ? sub.mappings.collect { |mapping| ["CHEBI:#{mapping.chebi_id}", mapping.chebi_id, mapping.sabiork_id.to_s, mapping.kegg_id] } : [])
           end
          ]
        end.uniq.flatten
      end
    end
  end
end
