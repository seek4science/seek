module Seek
  # for defining how lists should be storted, according to type, in a centralized fashion
  class ListSorter
    # potential to store definition in a config file, or database
    RULES = {
      'Person' => { 'index' => 'last_name', 'related' => 'last_name' },
      'Institution' => { 'index' => 'title', 'related' => 'title' },
      'Event' => { 'index' => 'start_date', 'related' => 'start_date' },
      'Publication' => { 'index' => 'published_date', 'related' => 'published_date' },
      'Other' => { 'index' => 'title', 'related' => 'updated_at' }
    }.freeze

    # sort items in the related items hash according the rule for its type
    def self.related_items(resource_hash)
      return if resource_hash.empty?

      resource_hash.each do |key, res|
        sort_items(key, res[:items], 'related')
      end
    end

    # sort items for an index, according to the page according the rule for its type
    #  if the page is 'latest', then they are always sorted by updated_at
    def self.index_items(items, page)
      return if items.empty?
      type_name = items.first.class.name
      if page == 'latest'
        sort_by_field(items, 'updated_at')
      else
        sort_items(type_name, items, 'index')
      end
    end

    def self.sort_items(type_name, items, view)
      type_name = 'Other' unless RULES[type_name]
      field = RULES[type_name][view] || RULES['Other'][view]
      sort_by_field(items, field)
    end

    def self.sort_by_field(items, field)
      # needs to handle nil values, which sort_by!(&field) raises and error. items with a nil value go at the end
      items.sort_by! { |item| [item.send(field) ? 0 : 1, item.send(field)] }
      items.reverse! if %w[updated_at start_date published_date].include?(field)
    end
  end
end
