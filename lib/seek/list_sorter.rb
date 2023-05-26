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
          options: [:updated_at_asc, :updated_at_desc, :created_at_asc, :created_at_desc, :title_asc, :title_desc,
                    :downloads_desc, :views_desc] },
      'Assay' => {
          defaults: { related: :position_asc }
      }
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
      position_asc: { title: 'Position (Ascending)', order: 'position' },
      position_desc: { title: 'Position (Descending)', order: 'position DESC' },
      downloads_desc: { title: 'Downloads (Descending)', order: '--downloads_desc',
                        relation_proc: -> (items) { # Sorts by number of downloads, descending
                          #### Using Active Record
                          # This section **modifies** "items" relation so that it includes a new column "downloads"
                          alog=ActivityLog.all.where(action: 'download',activity_loggable_type: items.first.class.name)
                          downloads=alog.select("activity_loggable_id AS #{items.table.name}_id, COUNT(activity_loggable_id) AS downloads").group(:activity_loggable_id)
                          items._select!("#{items.table.name}.*", 'd.downloads').joins!("LEFT OUTER JOIN (#{downloads.to_sql}) d ON #{items.table.name}.id = d.#{items.table.name}_id")

                          #### Using Arel
                          # This section builds the equivalent arel_table to provide the corresponding arel_field
                          items_a=items.arel_table
                          alog_a=ActivityLog.arel_table
                          downloads=alog_a.project(alog_a[:activity_loggable_id].as("log_id"), alog_a[:activity_loggable_id].count.as("downloads"))
                                        .where(alog_a[:action].eq('download').and(alog_a[:activity_loggable_type].eq(items.first.class.name)))
                                        .group(:activity_loggable_id).as('downloads')
                          joined=items_a.project(items_a[Arel.star], downloads[:downloads]).outer_join(downloads).on(items_a[:id].eq(downloads[:log_id])).as('d')

                          case ActiveRecord::Base.connection.instance_values["config"][:adapter]
                          when 'postgresql'
                            joined[:downloads].desc.nulls_last
                          else
                            joined[:downloads].desc
                          end
                        },
                        enum_proc: -> (items) {
                          return nil if items.empty? || !items.first.is_downloadable?
                          alog=ActivityLog.all.where(action: 'download',activity_loggable_type: items.first.class.name)
                          downloads = alog.select("activity_loggable_id AS #{items.first.class.table_name}_id, COUNT(activity_loggable_id) AS downloads").group(:activity_loggable_id)
                          joined = items.first.class.all.select('*', 'd.downloads').joins("LEFT OUTER JOIN (#{downloads.to_sql}) d ON #{items.first.class.table_name}.id = d.#{items.first.class.table_name}_id")
                          ids = joined.pluck("#{items.first.class.table_name}.id")
                          dls = joined.pluck('downloads')
                          -> (a, b) {
                            x = dls[ids.index(a.id)] || 0
                            y = dls[ids.index(b.id)] || 0
                            y <=> x
                          }
                        }
      },
      views_desc: { title: 'Views (Descending)', order: '--views_desc',
                    relation_proc: -> (items) { # Sorts by number of views, descending
                      #### Using Active Record
                      # This section **modifies** "items" relation so that it includes a new column "views"
                      alog=ActivityLog.all.where(action: 'show',activity_loggable_type: items.first.class.name)
                      views=alog.select("activity_loggable_id AS #{items.table.name}_id, COUNT(activity_loggable_id) AS views").group(:activity_loggable_id)
                      items._select!("#{items.table.name}.*", 'v.views').joins!("LEFT OUTER JOIN (#{views.to_sql}) v ON #{items.table.name}.id = v.#{items.table.name}_id")

                      #### Using Arel
                      # This section builds the equivalent arel_table to provide the corresponding arel_field
                      items_a=items.arel_table
                      alog_a=ActivityLog.arel_table
                      views=alog_a.project(alog_a[:activity_loggable_id].as("log_id"), alog_a[:activity_loggable_id].count.as("views"))
                                  .where(alog_a[:action].eq('show').and(alog_a[:activity_loggable_type].eq(items.first.class.name)))
                                  .group(:activity_loggable_id).as('views')
                      joined=items_a.project(items_a[Arel.star], views[:views]).outer_join(views).on(items_a[:id].eq(views[:log_id])).as('v')

                      case ActiveRecord::Base.connection.instance_values["config"][:adapter]
                      when 'postgresql'
                        joined[:views].desc.nulls_last
                      else
                        joined[:views].desc
                      end
                    },
                    enum_proc: -> (items) {
                      return nil if items.empty? || [Person, Project, Institution, Programme, Organism, HumanDisease].include?(items.first.class)
                      alog=ActivityLog.all.where(action: 'show',activity_loggable_type: items.first.class.name)
                      views = alog.select("activity_loggable_id AS #{items.first.class.table_name}_id, COUNT(activity_loggable_id) AS views").group(:activity_loggable_id)
                      joined = items.first.class.all.select('*', 'v.views').joins("LEFT OUTER JOIN (#{views.to_sql}) v ON #{items.first.class.table_name}.id = v.#{items.first.class.table_name}_id")
                      ids = joined.pluck("#{items.first.class.table_name}.id")
                      dls = joined.pluck('views')
                      -> (a, b) {
                        x = dls[ids.index(a.id)] || 0
                        y = dls[ids.index(b.id)] || 0
                        y <=> x
                      }
                    }
      },
      relevance: { title: 'Relevance', order: '--relevance',
                   relation_proc: -> (items) {
                     ids = items.solr_cache(items.last_solr_query)
                     return [] if ids.empty?
                     case ActiveRecord::Base.connection.instance_values["config"][:adapter]
                     when 'mysql2'
                       Arel.sql("FIELD(#{items.arel_table.name}.id,#{ids.join(',')})")
                     when 'postgresql'
                       Arel.sql("position(#{items.arel_table.name}.id::text in '#{ids.join(',')}')")
                     else
                       ids.map { |id| Arel::Nodes::Descending.new(items.arel_table[:id].eq(id)) }
                     end
                   },
                   enum_proc: -> (items) { # Curry a sorting function that sorts two items: a and b based on search relevance
                     return nil if items.empty?
                     type = items.first.class
                     ids = type.solr_cache(type.last_solr_query)
                     -> (a, b) {
                       x = ids.index(a&.id&.to_s)
                       y = ids.index(b&.id&.to_s)
                       if x.nil?
                         if y.nil?
                           0
                         else
                           1
                         end
                       elsif y.nil?
                         -1
                       else
                         x <=> y
                       end
                     }
                   }
      }
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
        orderings = strategy_for_relation(order, items)
        # Postgres requires any columns being ORDERed to be explicitly SELECTed (only when using DISTINCT?).
        if ["--views_desc","--downloads_desc"].include? order
          columns = []
        else
          columns = [items.arel.as(items.table.name)[Arel.star]]
          orderings.each do |ordering|
            if ordering.is_a?(Arel::Nodes::Ordering)
              expr = ordering.expr
              # Don't need to SELECT columns that are already covered by "*" and MySQL will error if you try!
              unless expr.respond_to?(:relation) && expr.relation == items.arel_table
                columns << expr
              end
            else
              columns << ordering
            end
          end
        end
        items.select(columns).order(orderings)
      else
        items.sort(&strategy_for_enum(order, items))
      end
    end

    def self.options(type_name)
      RULES.dig(type_name, :options) || RULES.dig('Other', :options)
    end

    def self.options_for_select(type_name)
      options(type_name).map do |key|
        [ORDER_OPTIONS[key][:title], key]
      end
    end

    def self.key_for_view(type_name, view)
      RULES.dig(type_name, :defaults, view) || RULES.dig('Other', :defaults, view)
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

    # Returns an Array of Arel "orderings", which can be passed into `SomeModel#order` to sort a relation.
    def self.strategy_for_relation(order, relation)
      fields_and_directions = order.split(',').flat_map do |f|
        field, order = f.strip.split(' ', 2)
        if field.start_with?('--')
          ORDER_OPTIONS[field.sub('--', '').to_sym][:relation_proc].call(relation)
        else
          m = field.match(/LOWER\((.+)\)/)
          field = m[1] if m
          arel_field = relation.arel_table[field.to_sym]
          arel_field = arel_field.eq(nil) if order == 'IS NULL'
          arel_field = arel_field.lower if m
          unless arel_field.is_a?(Arel::Nodes::Equality)
            arel_field = order&.match?(/desc/i) ? arel_field.desc : arel_field.asc
          end
          arel_field
        end
      end

      # Note: The following fixes an inconsistency between sorting relations and enumerables.
      # If, for example, you are sorting a relation by title, and multiple records have the same title, SQL will
      # order the duplicates  most recent -> oldest.
      # If you were sorting an enumerable however, it's likely it was already ordered oldest -> most recent, and
      # thus will sort duplicates the same way.
      fields_and_directions << relation.arel_table[:id].asc
      fields_and_directions
    end

    # Creates a proc from the given order string, which can be used to sort an Array e.g.
    #   `array.sort(&strategy_for_enum(order, array))`
    def self.strategy_for_enum(order, array)
      # Create an array of pairs: [<field>, <sort direction>]
      # Direction 1 is ascending (default), -1 is descending
      fields_and_directions = order.split(',').map do |f|
        field, order = f.strip.split(' ', 2)
        if field.start_with?('--')
          sorter = ORDER_OPTIONS[field.sub('--', '').to_sym][:enum_proc].call(array)
          next unless sorter
          [sorter, 1]
        else
          m = field.match(/LOWER\((.+)\)/)
          field = m[1] if m
          next if order == 'IS NULL'
          [field, order&.match?(/desc/i) ? -1 : 1]
        end
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
          if field.respond_to?(:call)
            val = field.call(a, b)
          else
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
          end
          break if val != 0
        end
        val
      end
    end
  end
end
