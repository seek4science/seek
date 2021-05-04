module Seek
  class Filterer
    # Hard-coded list of available filters for types. Overrides the automatically discovered filters (via `has_filter`).
    AVAILABLE_FILTERS = {
        Publication: [:query, :programme, :project, :published_year, :publication_type, :author, :organism, :human_disease, :tag],
        Event: [:query, :created_at, :country],
        Person: [:query, :programme, :project, :institution, :location, :project_position, :expertise, :tool]
    }.freeze

    # Misc mappings/transformations that might be used in multiple filters.
    MAPPINGS = {
        # Map a list of person IDs to peoples' names.
        person_name: ->(ids) do
          people = Person.select(:id, :first_name, :last_name).where(id: ids).to_a
          ids.map { |v| (people.detect { |p| p.id == v.to_i })&.name }
        end,
        assay_type_label:->(uris) {
          uris.map do |uri|
            Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_uri[uri]&.label ||
                Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_uri[uri]&.label
          end
        },
        technology_type_label: ->(uris) {
          uris.map { |uri| Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_uri[uri]&.label }
        },
        country_name: ->(codes) { codes.map { |code| CountryCodes.country(code) } }
    }.freeze

    # Pre-defined filters that may or may not be re-used for multiple types.
    FILTERS = {
        project: Seek::Filtering::Filter.new(
            value_field: 'projects.id',
            label_field: 'projects.title',
            joins: [:projects]
        ),
        programme: Seek::Filtering::Filter.new(
            value_field: 'programmes.id',
            label_field: 'programmes.title',
            joins: [:programmes]
        ),
        institution: Seek::Filtering::Filter.new(
            value_field: 'institutions.id',
            label_field: 'institutions.title',
            joins: [:institutions]
        ),
        contributor: Seek::Filtering::Filter.new(
            value_field: 'people.id',
            label_mapping: MAPPINGS[:person_name],
            includes: [:contributor]
        ),
        creator: Seek::Filtering::Filter.new(
            value_field: 'assets_creators.creator_id',
            label_mapping: MAPPINGS[:person_name],
            joins: [:creators]
        ),
        assay_class: Seek::Filtering::Filter.new(
            value_field: 'assay_classes.id',
            label_field: 'assay_classes.title',
            joins: [:assay_class]
        ),
        assay_type: Seek::Filtering::Filter.new(
            value_field: 'assay_type_uri',
            label_mapping: MAPPINGS[:assay_type_label]
        ),
        technology_type: Seek::Filtering::Filter.new(
            value_field: 'technology_type_uri',
            label_mapping: MAPPINGS[:technology_type_label]
        ),
        tag: Seek::Filtering::Filter.new(
            value_field: 'text_values.text',
            joins: [:tags_as_text]
        ),
        country: Seek::Filtering::Filter.new(
            value_field: 'country',
            label_mapping: MAPPINGS[:country_name]
        ),
        organism: Seek::Filtering::Filter.new(
            value_field: 'organisms.id',
            label_field: 'organisms.title',
            joins: [:organisms]
        ),
        human_disease: Seek::Filtering::Filter.new(
            value_field: 'human_diseases.id',
            label_field: 'human_diseases.title',
            joins: [:human_diseases]
        ),
        model_type: Seek::Filtering::Filter.new(
            value_field: 'model_types.id',
            label_field: 'model_types.title',
            joins: [:model_type]
        ),
        model_format: Seek::Filtering::Filter.new(
            value_field: 'model_formats.id',
            label_field: 'model_formats.title',
            joins: [:model_format]
        ),
        recommended_environment: Seek::Filtering::Filter.new(
            value_field: 'recommended_model_environments.id',
            label_field: 'recommended_model_environments.title',
            joins: [:recommended_environment]
        ),
        author: Seek::Filtering::Filter.new(
            value_field: 'people.id',
            label_mapping: MAPPINGS[:person_name],
            joins: [:people]
        ),
        published_year: Seek::Filtering::YearFilter.new(field: 'published_date'),
        publication_type: Seek::Filtering::Filter.new(
            value_field: 'publication_types.key',
            label_field: 'publication_types.title',
            joins: [:publication_type]
        ),
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
      @klass.custom_filters[key.to_sym] || FILTERS[key.to_sym]
    end
  end
end
