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
                    :downloads_desc] },
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
      downloads_desc: { title: 'Downloads (Descending)', order: '--downloads_desc DESC',
                       relation_proc: -> (items) { # Sorts by number of downloads, descending
                         # ______ DOES NOT WORK! ______
                         # The things below are attempts at getting this working, but it doe not work yet.
                         # It has currently hardcoded DataFile as the sorting objective, for simplicity.

                         #### Using Active Record
                         # This section **modifies** "items" relation so that it *includes a new column "downloads"
                         items._select!('*', 'd.downloads')
                         alog=ActivityLog.all.where(action: 'download',activity_loggable_type: 'DataFile')
                         downloads=alog.select('activity_loggable_id AS data_files_id, COUNT(activity_loggable_id) AS downloads').group(:activity_loggable_id)
                         items.joins!("LEFT OUTER JOIN (#{downloads.to_sql}) d ON data_files.id = d.data_files_id")
                         # The call to items.arel_table is problematic, as it basically un-does all the modifications
                         # above, and gets the original items db, where downloads does not exist.
                         arel_field = items.arel_table[:downloads].desc
                         arel_field

                         # Play in the console with:
                         # items=DataFile.all
                         # items.object_id
                         # items._select!(:id,:title,'d.downloads')
                         # alog=ActivityLog.all.where(action: 'download',activity_loggable_type: 'DataFile')
                         # downloads=alog.select('activity_loggable_id AS data_files_id, COUNT(activity_loggable_id) AS downloads').group(:activity_loggable_id)
                         # items.joins!("LEFT OUTER JOIN (#{downloads.to_sql}) d ON data_files.id = d.data_files_id")
                         # items.object_id
                         # itclone=items.clone
                         # puts ActiveRecord::Base.connection.exec_query itclone.to_sql
                         #
                         # Note: if you call "puts ActiveRecord::Base.connection.exec_query items.to_sql" to be able to
                         # look at "items", it makes the relation inmutable, so clone it first instead, i.e. call
                         # "itclone=items.clone" and then "puts ActiveRecord::Base.connection.exec_query itclone.to_sql"

                         #### Using Arel
                         # This section joins a new column "downloads" to the arel_table, but does not modify items
                         # itemsarel=items.arel_table
                         # alog=ActivityLog.arel_table
                         # downloads=alog.project(alog[:activity_loggable_id].as("log_id"), alog[:activity_loggable_id].count.as("downloads")).where(alog[:action].eq('download').and(alog[:activity_loggable_type].eq('DataFile'))).group(:activity_loggable_id).as('downloads')
                         # joined=itemsarel.project(itemsarel[Arel.star], downloads[:downloads]).outer_join(downloads).on(itemsarel[:id].eq(downloads[:log_id])).as('joined')
                         # items=joined
                         # arel_field = joined[:downloads].desc
                         # arel_field

                         ## Reproduce the arel_table section in ruby console with:
                         # items=DataFile.all
                         # itemsarel=items.arel_table
                         # alog=ActivityLog.arel_table
                         # files=itemsarel.project(itemsarel[:id], itemsarel[:title])
                         # puts ActiveRecord::Base.connection.exec_query files.to_sql
                         # downloads=alog.project(alog[:activity_loggable_id].as("log_id"), alog[:activity_loggable_id].count.as("downloads")).where(alog[:action].eq('download').and(alog[:activity_loggable_type].eq('DataFile'))).group(:activity_loggable_id)
                         # puts ActiveRecord::Base.connection.exec_query downloads.to_sql
                         # d=downloads.as('d')
                         # joined=itemsarel.project(itemsarel[:id], itemsarel[:title], d[:downloads]).outer_join(d).on(itemsarel[:id].eq(d[:log_id]))
                         # puts ActiveRecord::Base.connection.exec_query joined.to_sql
                         # j=joined.as('j')
                         # arel_field = j[:downloads].desc
                         # arel_field

                         ## This works but goes around a bit
                         # downloads=alog.project(alog[:activity_loggable_id].as("log_id"), alog[:activity_loggable_id].count.as("downloads")).where(alog[:action].eq('download').and(alog[:activity_loggable_type].eq('DataFile'))).group(:activity_loggable_id).as('d')
                         # files=itemsarel.project(itemsarel[:id], itemsarel[:title]).as('f')
                         # joined=itemsarel.project(:id,:title,:downloads).from(files).join(downloads).on(files[:id].eq(downloads[:log_id]))
                         # puts ActiveRecord::Base.connection.exec_query joined.to_sql

                         ## A very ugly single liner that dones work
                         # joined=itemsarel.project(itemsarel[:id], itemsarel[:title], alog[:activity_loggable_id].count.as("downloads")).join(alog).on(itemsarel[:id].eq(alog[:activity_loggable_id])).where(alog[:action].eq('download').and(alog[:activity_loggable_type].eq('DataFile'))).group(:activity_loggable_id)
                         # puts ActiveRecord::Base.connection.exec_query joined.to_sql

                         ## Reproduce what sorting by :title does in the ruby console with:
                         # items=DataFile.all
                         # arel_field = items.arel_table[:title].desc
                         # arel_field
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
        pp 'items before call oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo'
        pp items.object_id
        itemsprod=items.clone
        pp itemsprod.object_id
        pp items.object_id
        puts ActiveRecord::Base.connection.exec_query itemsprod.to_sql
        pp 'oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo'
        orderings = strategy_for_relation(order, items)
        pp 'items after call o0ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo'
        pp items.object_id
        itemsprod=items.clone
        pp itemsprod.object_id
        pp items.object_id
        puts ActiveRecord::Base.connection.exec_query itemsprod.to_sql
        pp 'oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo'
        # Postgres requires any columns being ORDERed to be explicitly SELECTed (only when using DISTINCT?).
        columns = [items.arel_table[Arel.star]]
        pp 'look here below! xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
        pp 'Columns:'
        pp columns
        pp 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
        orderings.each do |ordering|
          pp 'ordering~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
          pp ordering
          pp '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
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
        pp 'look here below! xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
        pp 'Columns:'
        pp columns
        pp 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
        pp 'Orderings:'
        pp orderings
        pp items.select(columns).order(orderings)
        pp 'look here above! xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
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
          # pp 'look here below! yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'
          # pp ORDER_OPTIONS[field.sub('--', '').to_sym][:relation_proc].call(relation)
          # pp 'look here above! yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'
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
