module Seek
  # for defining how lists should be storted, according to type, in a centralized fashion
  class ListSorter
    # potential to store definition in a config file, or database
    RULES = {
      'Person' => {
          defaults: { index: :name_asc, related: :name_asc },
          options: [:name_asc, :name_desc, :created_at_asc, :created_at_desc] },
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
          defaults: { index: :updated_at_desc, related: :updated_at_desc },
          options: [:updated_at_asc, :updated_at_desc, :created_at_asc, :created_at_desc, :title_asc, :title_desc] },
    }.with_indifferent_access.freeze

    ORDER_OPTIONS = {
      title_asc: { title: 'Title (A-Z)', order: 'LOWER(title)' },
      title_desc: { title: 'Title (Z-A)', order: 'LOWER(title) DESC' },
      name_asc: { title: 'Name (A-Z)', order: 'last_name IS NULL, LOWER(last_name), LOWER(first_name)' },
      name_desc: { title: 'Name (Z-A)', order: 'last_name IS NULL, LOWER(last_name) DESC, LOWER(first_name) DESC' },
      start_date_asc: { title: 'Date (Ascending)', order: 'start_date' },
      start_date_desc: { title: 'Date (Descending)', order: 'start_date DESC' },
      published_at_asc: { title: 'Publication date (Ascending)', order: 'published_date' },
      published_at_desc: { title: 'Publication date (Descending)', order: 'published_date DESC' },
      updated_at_asc: { title: 'Last update date (Ascending)', order: 'updated_at' },
      updated_at_desc: { title: 'Last update date (Descending)', order: 'updated_at DESC' },
      created_at_asc: { title: 'Creation date (Ascending)', order: 'created_at' },
      created_at_desc: { title: 'Creation date (Descending)', order: 'created_at DESC' },
    }.with_indifferent_access.freeze

    # sort items in the related items hash according the rule for its type
    def self.related_items(resource_hash)
      return if resource_hash.empty?

      resource_hash.each do |key, res|
        resource_hash[key][:items] = sort_by_order(res[:items], order_for_view(key, :related))
      end
    end

    def self.sort_by_order(items, order = nil)
      order ||= order_for_view(items.first.class.name, :index)
      if items.is_a?(ActiveRecord::Relation)
        items.order(strategy_for_relation(order, items))
      else
        items.sort(&strategy_for_enum(order))
      end
    end

    def self.options(type_name)
      (RULES[type_name] || RULES['Other'])[:options]
    end

    def self.options_for_select(type_name)
      options(type_name).map do |key|
        [ORDER_OPTIONS[key][:title], key]
      end
    end

    def self.key_for_view(type_name, view)
      (RULES[type_name] || RULES['Other'])[:defaults][view] || RULES['Other'][:defaults][view]
    end

    def self.valid_key?(type, key)
      options(type).include?(key.to_sym) && ORDER_OPTIONS.key?(key.to_sym)
    end

    def self.order_from_keys(*keys)
      keys.map do |key|
        ORDER_OPTIONS[key][:order]
      end.compact.join(", ")
    end

    def self.keys_from_json_api_sort(type, sort)
      sort.split(',').map do |field|
        if field.start_with?('-')
          key = "#{field[1..-1]}_desc"
        else
          key = "#{field}_asc"
        end

        key.to_sym if valid_key?(type, key)
      end.compact
    end

    def self.keys_from_params(type, params)
      params = Array(params) unless params.is_a?(Array)
      params.reject(&:blank?).map(&:to_sym).select { |key| valid_key?(type, key) }
    end

    def self.order_for_view(type_name, view)
      self.order_from_keys(self.key_for_view(type_name, view))
    end

    def self.strategy_for_relation(order, relation)
      fields_and_directions = order.split(',').map do |f|
        field, order = f.strip.split(' ', 2)
        m = field.match(/LOWER\((.+)\)/)
        field = m[1] if m
        arel_field = relation.arel_table[field.to_sym]
        arel_field = arel_field.eq(nil) if order == 'IS NULL'
        arel_field = arel_field.lower if m
        arel_field = arel_field.desc if order&.match?(/desc/i)
        arel_field
      end

      # Note: The following fixes an inconsistency between sorting relations and enumerables.
      # If, for example, you are sorting a relation by title, and multiple records have the same title, SQL will
      # order the duplicates  most recent -> oldest.
      # If you were sorting an enumerable however, it's likely it was already ordered oldest -> most recent, and
      # thus will sort duplicates the same way.
      fields_and_directions << relation.arel_table[:id].asc
      fields_and_directions
    end

    def self.strategy_for_enum(order)
      # Create an array of pairs: [<field>, <sort direction>]
      # Direction 1 is ascending (default), -1 is descending
      fields_and_directions = order.split(',').map do |f|
        field, order = f.strip.split(' ', 2)
        m = field.match(/LOWER\((.+)\)/)
        field = m[1] if m
        next if order == 'IS NULL'
        [field, order&.match?(/desc/i) ? -1 : 1]
      end.compact

      fields_and_directions << [:id, 1] # See above note

      proc do |a, b|
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
                  (x.is_a?(String) && y.is_a?(String) ? x.casecmp(y) : x <=> y) * direction  # A direction of -1 inverts the sorting.
                end
          break if val != 0
        end
        val
      end
    end
  end
end
