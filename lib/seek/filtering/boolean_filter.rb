module Seek
  module Filtering
    class BooleanFilter
      attr_reader :field, :includes, :joins, :isa_json_compliant
      attr_writer :isa_json_compliant

      def initialize(field: nil, includes: [], joins: [])
        @field = field
        @includes = includes
        @joins = joins
      end

      def apply(collection, bool)

        collection = apply_joins(collection) || []
        return collection if bool.nil?
        collection.where("#{field} = ?", bool)
      end

      def options(collection, active_values = [])
        collection = apply_joins(collection) || []
        isa_json_compliant_result = apply(collection, true)
        non_isa_json_compliant_result = collection - isa_json_compliant_result
        isa_json_compliance_is_active = active_values.include? 'true'
        non_isa_json_compliance_is_active = active_values.include? 'false'
        options = [
          Seek::Filtering::Option.new('Yes', 'true', isa_json_compliant_result.count, isa_json_compliance_is_active, {replace_filters: true}),
          Seek::Filtering::Option.new('No', 'false', non_isa_json_compliant_result.count, non_isa_json_compliance_is_active, {replace_filters: true})
        ]
        options.compact.sort
      end

      private

      def apply_joins(collection)
        collection = collection.includes(includes) if includes
        collection = collection.joins(joins) if joins

        collection
      end

    end
  end
end