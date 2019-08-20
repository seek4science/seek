module Seek
  # for defining how lists should be storted, according to type, in a centralized fashion
  class ListSorter
    # potential to store definition in a config file, or database
    RULES = {
      'Person' => {
          defaults: { index: :name_asc, related: :name_asc },
          options: [:name_desc, :name_asc, :created_at_asc, :created_at_desc] },
      'Institution' => {
          defaults: { index: :title_asc, related: :title_asc },
          options: [:title_asc, :title_desc] },
      'Event' => {
          defaults: { index: :start_date_desc, related: :start_date_desc },
          options: [:start_date_asc, :start_date_desc, :title_asc, :title_desc] },
      'Publication' => {
          defaults: { index: :published_at_desc, related: :published_at_desc },
          options: [:published_at_asc, :published_at_desc, :created_at_asc, :created_at_desc, :title_asc, :title_desc] },
      'Other' => {
          defaults: { index: :title_asc, related: :updated_at_desc },
          options: [:updated_at_asc, :updated_at_desc, :created_at_asc, :created_at_desc, :title_asc, :title_desc] },
    }.with_indifferent_access.freeze

    ORDER_OPTIONS = {
      title_asc: { title: 'Title (A-Z)', order: 'title' },
      title_desc: { title: 'Title (Z-A)', order: 'title DESC' },
      name_asc: { title: 'Name (A-Z)', order: 'last_name, first_name' },
      name_desc: { title: 'Name (Z-A)', order: 'last_name DESC, first_name DESC' },
      start_date_asc: { title: 'Date (Ascending)', order: 'start_date' },
      start_date_desc: { title: 'Date (Descending)', order: 'start_date DESC' },
      published_at_asc: { title: 'Publication date (Ascending)', order: 'published_date' },
      published_at_desc: { title: 'Publication date (Descending)', order: 'published_date DESC' },
      updated_at_asc: { title: 'Last updated (Descending)', order: 'updated_at' },
      updated_at_desc: { title: 'Last updated (Ascending)', order: 'updated_at DESC' },
      created_at_asc: { title: 'Last created (Descending)', order: 'created_at' },
      created_at_desc: { title: 'Last created (Ascending)', order: 'created_at DESC' },
    }.with_indifferent_access.freeze

    # sort items in the related items hash according the rule for its type
    def self.related_items(resource_hash)
      return if resource_hash.empty?

      resource_hash.each do |key, res|
        sort_by_field(res[:items], sort_field(key, :related))
      end
    end

    # sort items for an index by the given sort parameter, or the default for its type
    def self.index_items(items, order = nil)
      return if items.empty?
      if order && ORDER_OPTIONS[order]
        sort_by_field(items, ORDER_OPTIONS[order][:order])
      else
        sort_by_field(items, sort_field(items.first.class.name, :index))
      end
    end

    def self.json_api_sort(items, sort)
      fields = sort.split(',').map do |field|
        if field.start_with?('-')
          field = field[1..-1]
          "#{field[1..-1]} desc"
        else
          field
        end
      end.join(', ')

      sort_by_field(items, fields)
    end

    # Sort an array with SQL-style order by clauses, e.g.:
    # * `last_name`
    # * `updated_at DESC`
    # * `first_letter ASC, updated_at DESC`
    def self.sort_by_field(items, fields)
      # Create an array of pairs: [<field>, <sort direction>]
      # Direction 1 is ascending (default), -1 is descending
      fields_and_directions = fields.split(',').map do |f|
        field, order = f.strip.split(' ')
        [field, order&.match?(/desc/i) ? -1 : 1]
      end

      items.sort! do |a, b|
        val = 0
        # For each pair, sort by the first field/direction.
        # If that sorting produces 0 (i.e. both are equal), try the next field until a non-zero value is returned,
        #  or we run out of fields.
        #
        # nil values are always sorted to the end, regardless of direction.
        fields_and_directions.each do |field, direction|
          x = a.send(field)
          y = b.send(field)
          val = if x.nil?
                  if y.nil?
                    0
                  else
                    1
                  end
                elsif y.nil?
                  -1
                else
                  (x <=> y) * direction  # A direction of -1 inverts the sorting.
                end
          break if val != 0
        end
        val
      end
    end

    def self.sort_field(type_name, view)
      key = (RULES[type_name] || RULES['Other'])[:defaults][view] || RULES['Other'][:defaults][view]
      ORDER_OPTIONS[key][:order]
    end
  end
end
