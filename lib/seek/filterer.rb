module Seek
  class Filterer
    AVAILABLE_FILTERS = {
        Publication: [],
        Event: [:query, :created_at],
        Person: [:query, :programme, :project, :institution, :project_position, :expertise, :tool]
    }.freeze

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
        institution: {
            field: 'institutions.id',
            title_field: 'institutions.title',
            joins: [:institutions],
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
            title_mapping: ->(values) {
              values.map do |value|
                value = RDF::URI(value)
                Seek::Ontologies::AssayTypeReader.instance.fetch_label_for(value) ||
                    Seek::Ontologies::ModellingAnalysisTypeReader.instance.fetch_label_for(value)
              end
            }
        },
        technology_type: {
            field: 'technology_type_uri',
            title_mapping: ->(values) {
              values.map { |value| Seek::Ontologies::TechnologyTypeReader.instance.fetch_label_for(RDF::URI(value)) }
            }
        },
        tag: {
            field: 'text_values.id',
            title_field: 'text_values.text',
            joins: [:tags_as_text],
        },
        country: {
            field: 'country'
        },
        organism: {
            field: 'organisms.id',
            title_field: 'organisms.title',
            joins: [:organisms],
        }
    }.freeze

    def initialize(klass)
      @klass = klass
    end

    def active_filter_values(filter_params)
      hash = {}

      filter_params.each do |key, values|
        hash[key.to_sym] = [values].flatten.reject(&:blank?) if get_filter(key)
      end

      hash
    end

    def filter(collection, active_filters)
      filtered_collection = collection

      active_filters.each do |key, values|
        filter = get_filter(key)
        filtered_collection = filter.apply(filtered_collection, values)
      end

      filtered_collection
    end

    def available_filters(unfiltered_collection, active_filters)
      return {} if unfiltered_collection.empty?

      available_filters = {}
      available_filter_keys.each do |key|
        filter = get_filter(key)
        without_current_filter = filter(unfiltered_collection, active_filters.except(key))
        available_filters[key] = filter.options(without_current_filter, active_filters[key] || [])
      end

      available_filters
    end

    def available_filter_keys
      AVAILABLE_FILTERS[@klass.name.to_sym] || @klass.available_filters
    end

    def get_filter(key)
      val = @klass.custom_filters[key.to_sym] || FILTERS[key.to_sym]
      val.is_a?(Hash) ? Seek::Filtering::Filter.new(val) : val
    end
  end
end