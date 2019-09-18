module HasFilters
  extend ActiveSupport::Concern

  class_methods do
    def has_filter(*filters)
      self.applicable_filters.push(*filters.map do |f|
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

    def applicable_filters
      @applicable_filters ||= []
    end

    def custom_filters
      @custom_filters ||= {}
    end
  end
end
