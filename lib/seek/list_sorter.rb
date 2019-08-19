module Seek
  # for defining how lists should be storted, according to type, in a centralized fashion
  class ListSorter
    # potential to store definition in a config file, or database
    RULES = {
      'Person' => { 'index' => 'last_name, first_name', 'related' => 'last_name, first_name' },
      'Institution' => { 'index' => 'title', 'related' => 'title' },
      'Event' => { 'index' => 'start_date DESC', 'related' => 'start_date DESC' },
      'Publication' => { 'index' => 'published_date DESC', 'related' => 'published_date DESC' },
      'Other' => { 'index' => 'title', 'related' => 'updated_at DESC' }
    }.freeze

    ORDER_OPTIONS = {
      latest: { title: 'Latest', order: 'updated_at DESC' },
      oldest: { title: 'Oldest', order: 'created_at ASC' } # Example... remove me
    }.with_indifferent_access.freeze

    # sort items in the related items hash according the rule for its type
    def self.related_items(resource_hash)
      return if resource_hash.empty?

      resource_hash.each do |key, res|
        sort_items(key, res[:items], 'related')
      end
    end

    # sort items for an index by the given sort parameter, or the default for its type
    def self.index_items(items, order = nil)
      return if items.empty?
      if order && ORDER_OPTIONS[order]
        sort_by_field(items, ORDER_OPTIONS[order][:order])
      else
        sort_items(items.first.class.name, items, 'index')
      end
    end

    def self.sort_items(type_name, items, view)
      sort_by_field(items, sort_field(type_name, view))
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
      (RULES[type_name] || RULES['Other'])[view] || RULES['Other'][view]
    end
  end
end
