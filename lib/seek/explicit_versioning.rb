module Seek
  # Based heavily on the acts_as_versioned plugin
  module ExplicitVersioning
    CALLBACKS = [:sync_latest_version].freeze
    VISIBILITY = {
        0 => :private,
        1 => :registered_users,
        2 => :public
    }.freeze
    VISIBILITY_INV = VISIBILITY.invert.freeze

    def self.included(mod) # :nodoc:
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def explicit_versioning(options = {}, &extension)
        # don't allow multiple calls
        return if included_modules.include?(Seek::ExplicitVersioning::ActMethods)

        send :include, Seek::ExplicitVersioning::ActMethods

        cattr_accessor :versioned_class_name, :versioned_foreign_key, :versioned_table_name, :versioned_inheritance_column,
                       :version_column, :version_sequence_name, :file_columns, :allowed_list_columns, :revision_comments_column,
                       :version_association_options, :timestamp_columns, :sync_ignore_columns

        self.versioned_class_name         = options[:class_name]  || 'Version'
        self.versioned_foreign_key        = options[:foreign_key] || to_s.foreign_key
        self.versioned_table_name         = options[:table_name]  || "#{table_name_prefix}#{base_class.name.demodulize.underscore}_versions#{table_name_suffix}"
        self.versioned_inheritance_column = options[:inheritance_column] || "versioned_#{inheritance_column}"
        self.version_column               = options[:version_column]     || 'version'
        self.file_columns                 = options[:file_columns] || []
        self.allowed_list_columns           = options[:allowed_list_columns] || []
        self.revision_comments_column     = options[:revision_comments_column] || 'revision_comments'
        self.version_association_options  = {
            class_name: "#{self}::#{versioned_class_name}",
            foreign_key: versioned_foreign_key.to_s,
            order: 'version',
            dependent: :destroy
        }.merge(options[:association_options] || {})
        self.timestamp_columns            = options[:timestamp_columns] || %w[created_at updated_at]
        self.sync_ignore_columns          = options[:sync_ignore_columns] || []

        class_eval do
          order_opts = version_association_options.delete(:order) || ''
          condition_ops = version_association_options.delete(:conditions) || ''
          has_many :standard_versions, -> { order(order_opts).where(condition_ops) }, **version_association_options

          before_create :set_new_version
          after_create :save_version_on_create
          after_update :sync_latest_version
        end

        parent_class = self
        # create the dynamic versioned model
        const_set(versioned_class_name, Class.new(ApplicationRecord)).class_eval do
          def name
            "Version #{version}"
          end

          def self.reloadable?
            false
          end

          def latest_version
            parent.latest_standard_version
          end

          def previous_version
            parent.previous_standard_version(self.version)
          end

          def versions
            parent.standard_versions
          end

          def latest_version?
            parent.latest_standard_version == self
          end

          def is_a_version?
            true
          end

          def is_git_versioned?
            false
          end

          def visibility= key
            super(Seek::ExplicitVersioning::VISIBILITY_INV[key.to_sym] || Seek::ExplicitVersioning::VISIBILITY_INV[self.class.default_visibility])
          end

          def visibility
            Seek::ExplicitVersioning::VISIBILITY[super]
          end

          def can_change_visibility?
            !latest_version? && (!respond_to?(:doi) || doi.blank?)
          end

          def visible?(user = User.current_user)
            case visibility
            when :public
              true
            when :private
              parent.can_manage?(user)
            when :registered_users
              user&.person&.member?
            end
          end

          def self.default_visibility
            :public
          end

          def set_default_visibility
            self.visibility ||= self.class.default_visibility
          end

          def cache_key_fragment
            "#{parent.class.name.underscore}-#{parent.id}-#{version}"
          end

          if parent_class.method_defined?(:to_schema_ld)
            def to_schema_ld
              Seek::BioSchema::Serializer.new(self).json_ld
            end
          end

          def schema_org_supported?
            Seek::BioSchema::Serializer.supported?(parent)
          end
        end

        versioned_class.table_name = versioned_table_name
        versioned_class.belongs_to to_s.demodulize.underscore.to_sym,
                                   class_name: "::#{self}",
                                   foreign_key: versioned_foreign_key

        # add a generic method, independent of the model, that gets the thing being versioned.
        versioned_class.belongs_to :parent,
                                   class_name: "::#{self}",
                                   foreign_key: versioned_foreign_key

        versioned_class.before_validation :set_default_visibility

        versioned_class.class_eval(&extension) if block_given?
      end
    end

    module ActMethods
      def self.included(base) # :nodoc:
        base.extend ClassMethods
        base.include Git::VersioningCompatibility
      end

      # Finds a specific version of this model.
      def find_standard_version(version)
        return version if version.is_a?(self.class.versioned_class)
        return nil if version.is_a?(ActiveRecord::Base)
        find_standard_versions(conditions: ['version = ?', version], limit: 1).first
      end

      # Returns the most recent version
      def latest_standard_version
        standard_versions.last
      end

      # Returns the previous version
      def previous_standard_version(base = latest_standard_version.version)
        standard_versions.where('version < ?', base).last
      end

      # Finds versions of this model.  Takes an options hash like <tt>find</tt>
      def find_standard_versions(options = {})
        relation = standard_versions
        relation = relation.where(options[:conditions]) if options[:conditions]
        relation = relation.joins(options[:joins]) if options[:joins]
        relation = relation.limit(options[:limit]) if options[:limit]
        relation = relation.order(options[:order]) if options[:order]
        relation
      end

      # Saves the object as a new version and also saves the original object as the new version.
      # Make sure to create (and thus save) any inner associations beforehand as these won't be saved here.
      def save_as_new_version(revision_comments = nil)
        return false unless valid?
        without_update_callbacks do
          set_new_version
          save_version_on_create(revision_comments)
          save
        end
      end

      def update_version(version_number_to_update, attributes)
        return false if version_number_to_update.nil? || version_number_to_update.to_i < 1
        return false if attributes.nil? || attributes.empty?
        return false unless (ver = find_standard_version(version_number_to_update))

        rtn = ver.update(attributes)

        if rtn
          # if the latest version has been updated then update the main table as well
          if version_number_to_update.to_i == send(self.class.version_column)
            return update_main_to_version(version_number_to_update, true)
          else
            return true
          end
        else
          return false
        end
      end

      def destroy_version(version_number)
        if (ver = find_standard_version(version_number))
          without_update_callbacks do
            # For fault tolerance (ie: to prevent data loss through premature deletion), first...
            # Check to see if the current (aka latest) version has to be deleted,
            # and if so update the main table with the data from the version that will become the latest
            if version_number.to_i == send(self.class.version_column)
              if standard_versions.count > 1
                to_be_latest_version = standard_versions[standard_versions.count - 2].version
              else
                return false
              end
              success = update_main_to_version(to_be_latest_version)
            end

            # Then... delete the version
            if success || Seek::Config.delete_asset_version_enabled
              return ver.destroy
            else
              return false
            end
          end
        end
      end

      def without_update_callbacks(&block)
        self.class.without_update_callbacks(&block)
      end

      def empty_callback() end #:nodoc:

      def visible_standard_versions(user = User.current_user)
        scopes = [ExplicitVersioning::VISIBILITY_INV[:public]]
        scopes << ExplicitVersioning::VISIBILITY_INV[:registered_users] if user&.person&.member?
        scopes << ExplicitVersioning::VISIBILITY_INV[:private] if can_manage?(user)

        standard_versions.where(visibility: scopes)
      end

      protected

      def set_new_version
        send("#{self.class.version_column}=", next_version)
      end

      # Saves a version of the model in the versioned table. This is called in the after_create callback by default
      def save_version_on_create(revision_comments = nil)
        rev = self.class.versioned_class.new
        clone_versioned_model(self, rev)
        rev.version = send(self.class.version_column)
        rev.send("#{self.class.revision_comments_column}=", revision_comments)
        rev.send("#{self.class.versioned_foreign_key}=", id)
        if rev.version > 1 && rev.respond_to?(:contributor) && User.current_user
          rev.contributor = User.current_user.person
        end
        rev.projects = projects
        saved = rev.save

        if saved
          # Now update timestamp columns on main model.
          # Note: main model doesnt get saved yet.
          update_timestamps(rev, self)
        end

        saved
      end

      def update_timestamps(from, to)
        ['updated_at'].each do |key|
          next unless to.has_attribute?(key) && from.has_attribute?(key)
          logger.debug("explicit_versioning - update_timestamps method - setting timestamp_column '#{key}'")
          if from.send("#{key}").nil?
            to.send("#{key}=", nil)
          else
            to.send("#{key}=", from.send("#{key}"))
          end
        end
      rescue => err
        logger.error('ERROR: An error occurred in the explicit_versioning plugin during the update_timestamps method (setting timestamp columns).')
        logger.error("ERROR DETAILS: #{err}")
      end

      # This method updates the latest version entry in the versioned table with the data
      # from the main table (since those two entries should always have the same data).
      def sync_latest_version
        ver = standard_versions.last
        if ver.nil?
          save_as_new_version
        else
          clone_versioned_model(self, ver)
          ver.save
        end
      end

      # This method updates the entry in the main table with the data from the version specified,
      # and also updates the corresponding version column in the main table to reflect this.
      # Note: this method on its own should not be used to revert to previous versions as it doesn't actualy delete any versions.
      def update_main_to_version(version_number, process_file_columns = true)
        if (ver = find_standard_version(version_number))
          clone_versioned_model(ver, self, process_file_columns)
          send("#{self.class.version_column}=", version_number)

          # Now update timestamp columns on main model.
          update_timestamps(ver, self)

          save
        else
          false
        end
      end

      # Clones a model.
      def clone_versioned_model(orig_model, new_model, process_file_columns = true)
        versioned_attributes.each do |key|
          # Make sure to ignore file columns, white list columns, timestamp columns and any other ignore columns
          unless file_columns.include?(key) ||
              allowed_list_columns.include?(key) ||
              timestamp_columns.include?(key) ||
              sync_ignore_columns.include?(key)
            next unless orig_model.respond_to?(key)
            next unless new_model.respond_to?("#{key}=")
            new_model.send("#{key}=", orig_model.send(key))
          end
        end

        if process_file_columns
          # Now copy over file columns
          begin
            file_columns.each do |key|
              if orig_model.has_attribute?(key)
                if orig_model.send(key).nil?
                  logger.debug('DEBUG: file column is nil')
                  new_model.send("#{key}=", nil)
                else
                  logger.debug('DEBUG: file column is not nil')
                  new_model.send("#{key}=", File.open(orig_model.send(key)))
                  FileUtils.cp(orig_model.send(key), new_model.send(key))
                end
              end
            end
          rescue => err
            logger.error('ERROR: An error occurred in the explicit_versioning plugin during the clone_versioned_model method (copying file columns).')
            logger.error("ERROR DETAILS: #{err}")
          end
        end

        # Now set white list columns
        begin
          allowed_list_columns.each do |key|
            if orig_model.has_attribute?(key)
              if orig_model.send(key).nil?
                new_model.send("#{key}=", nil)
              else
                new_model.send("#{key}=", orig_model.send(key))
              end
            end
          end
        rescue => err
          logger.error('ERROR: An error occurred in the explicit_versioning plugin during the clone_versioned_model method (setting white list columns).')
          logger.error("ERROR DETAILS: #{err}")
        end

        # Set version column accordingly.
        # if orig_model.is_a?(self.class.versioned_class)
        #  new_model[new_model.class.inheritance_column] = orig_model[self.class.versioned_inheritance_column]
        # elsif new_model.is_a?(self.class.versioned_class)
        #  new_model[self.class.versioned_inheritance_column] = orig_model[orig_model.class.inheritance_column]
        # end
      end

      # Gets the next available version for the current record, or 1 for a new record
      def next_version
        return 1 if new_record? || standard_versions.empty?
        (standard_versions.maximum(:version) || 0) + 1
      end

      # Returns an array of attribute keys that are versioned.  See non_versioned_columns
      def versioned_attributes
        attributes.keys.reject { |k| self.class.non_versioned_columns.include?(k) }
      end

      module ClassMethods
        # Finds a specific version of a specific row of this model
        def find_version(id, version)
          find_versions(id,
                        conditions: ["#{versioned_foreign_key} = ? AND version = ?", id, version],
                        limit: 1).first
        end

        # Finds versions of a specific model.  Takes an options hash like <tt>find</tt>
        def find_versions(id, options = {})
          versioned_class.find :all, {
              conditions: ["#{versioned_foreign_key} = ?", id],
              order: 'version'
          }.merge(options)
        end

        def non_versioned_columns
          @non_versioned_columns ||= [primary_key, inheritance_column, 'version', 'lock_version', versioned_inheritance_column, version_column]
        end

        # Returns an array of columns that are versioned.  See non_versioned_columns
        def versioned_columns
          @versioned_columns ||= columns.reject { |c| non_versioned_columns.include?(c.name) }
        end

        # Returns an instance of the dynamic versioned model
        def versioned_class
          const_get versioned_class_name
        end

        # Rake migration task to create the versioned table using options passed
        def create_versioned_table(create_table_options = {})
          # create version column in main table if it does not exist
          unless content_columns.find { |c| %w[version lock_version].include? c.name }
            connection.add_column table_name, :version, :integer, default: 1
          end

          connection.create_table(versioned_table_name, create_table_options) do |t|
            t.column versioned_foreign_key, :integer
            t.column :version, :integer
            t.column revision_comments_column, :text
          end

          updated_col = nil
          versioned_columns.each do |col|
            updated_col = col if !updated_col && %(updated_at updated_on).include?(col.name)
            connection.add_column versioned_table_name, col.name, col.type,
                                  limit: col.limit,
                                  default: col.default
          end

          if type_col = columns_hash[inheritance_column]
            connection.add_column versioned_table_name, versioned_inheritance_column, type_col.type,
                                  limit: type_col.limit,
                                  default: type_col.default
          end

          if updated_col.nil?
            connection.add_column versioned_table_name, :updated_at, :timestamp
          end
        end

        # Rake migration task to drop the versioned table
        def drop_versioned_table
          connection.drop_table versioned_table_name
        end

        # Executes the block with the update callbacks disabled.
        #
        #   Foo.without_update_callbacks do
        #     @foo.save
        #   end
        #
        def without_update_callbacks
          class_eval do
            CALLBACKS.each do |attr_name|
              alias_method "orig_#{attr_name}".to_sym, attr_name
              alias_method attr_name, :empty_callback
            end
          end
          yield
        ensure
          class_eval do
            CALLBACKS.each do |attr_name|
              alias_method attr_name, "orig_#{attr_name}".to_sym
            end
          end
        end
      end
    end
  end
end
