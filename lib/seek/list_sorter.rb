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
        sort_by_field(items, 'updated_at DESC')
      else
        sort_items(type_name, items, 'index')
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
      fields = fields.split(",").map(&:strip)
      fields_and_mods = fields.map do |f|
        field, order = f.split(' ')
        [field, order&.match?(/desc/i) ? -1 : 1]
      end

      items.sort! do |a, b|
        val = 0
        fields_and_mods.each do |field, mod|
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
                  (x <=> y) * mod
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
