module Seek
  class Filter
    FILTERS = {
        project: {
            field: 'projects.id',
            title_field: 'projects.title',
            joins: [:projects],
        },
        programme: {
            field: 'programmes.id',
            title_field: 'programmes.title',
            joins: [:programmes],
        },
        contributor: {
            field: 'people.id',
            title_mapping: ->(values) { Person.where(id: values).map(&:name) },
            includes: [:contributor],
        },
        creator: {
            field: 'assets_creators.creator_id',
            title_mapping: ->(values) { Person.where(id: values).map(&:name) },
            joins: [:creators],
        },
        assay_class: {
            field: 'assay_classes.id',
            title_field: 'assay_classes.title',
            joins: [:assay_class],
        },
        assay_type: {
            field: 'assay_type_uri',
        },
        technology_type: {
            field: 'technology_type_uri',
        },
        tag: {
            field: 'text_values.id',
            title_field: 'text_values.text',
            joins: [:tags_as_text],
        }
    }.freeze

    def initialize(klass)
      @klass = klass
    end

    def active_filters(filter_params)
      active_filters = {}

      filter_params.each do |key, values|
        active_filters[key.to_sym] = [values].flatten if get_filter(key)
      end

      active_filters
    end

    def filter(collection, active_filters)
      filtered_collection = collection

      active_filters.each do |key, values|
        filtered_collection = apply_filter(filtered_collection, get_filter(key), values)
      end

      filtered_collection
    end

    def available_filters(unfiltered_collection, active_filters)
      return {} if unfiltered_collection.empty?

      available_filters = {}
      @klass.applicable_filters.each do |key|
        filter = get_filter(key)
        without_current_filter = filter(unfiltered_collection, active_filters.except(key))
        available_filters[key] = available_filter_values(without_current_filter, filter).map do |value, count, title|
          {
            title: title,
            value: value.to_s,
            count: count,
            active: active_filters[key]&.include?(value.to_s)
          }
        end
      end

      available_filters
    end

    private

    def apply_filter(collection, filter, value)
      collection = collection.joins(filter[:joins]) if filter[:joins]
      collection = collection.includes(filter[:includes]) if filter[:includes]
      collection.where(filter[:field] => value)
    end

    def available_filter_values(collection, filter)
      select = [filter[:field], "COUNT(#{filter[:field]})", filter[:title_field]].compact.map { |f| Arel.sql(f) }
      collection = collection.select(*select)
      collection = collection.joins(filter[:joins]) if filter[:joins]
      collection = collection.includes(filter[:includes]) if filter[:includes]
      groups = collection.group(filter[:field]).pluck(*select).reject { |g| g[1].zero? } # Remove 0 count results
      if filter[:title_mapping]
        filter[:title_mapping].call(groups.map(&:first)).each.with_index do |title, index|
          groups[index][2] = title
        end
      end
      groups
    end

    def get_filter(key)
      @klass.custom_filters[key.to_sym] || FILTERS[key.to_sym]
    end
  end
end