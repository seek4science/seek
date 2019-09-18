module HasFilters
  extend ActiveSupport::Concern

  class_methods do
    def has_filter(*filters)
      available_filters.push(*filters.map do |f|
        case f
        when Symbol
          f
        when Hash
          custom_filters.merge!(f.symbolize_keys)
          f.keys.first.to_sym
        else
          f.to_sym
        end
      end)
    end

    def available_filters
      @available_filters ||= superclass.respond_to?(:available_filters) ? superclass.available_filters.dup : []
    end

    def custom_filters
      @custom_filters ||= superclass.respond_to?(:custom_filters) ? superclass.custom_filters.dup : {}
    end
  end
end
