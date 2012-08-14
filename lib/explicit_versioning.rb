module Jits
  module Acts
    # Based heavily on the acts_as_versioned plugin
    module ExplicitVersioning
      CALLBACKS = [:sync_latest_version]
      def self.included(mod) # :nodoc:
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def explicit_versioning(options = {}, &extension)
          # don't allow multiple calls
          return if self.included_modules.include?(Jits::Acts::ExplicitVersioning::ActMethods)

          send :include, Jits::Acts::ExplicitVersioning::ActMethods

          cattr_accessor :versioned_class_name, :versioned_foreign_key, :versioned_table_name, :versioned_inheritance_column,
            :version_column, :version_sequence_name, :non_versioned_columns, :file_columns, :white_list_columns, :revision_comments_column,
            :version_association_options, :timestamp_columns, :sync_ignore_columns

          self.versioned_class_name         = options[:class_name]  || "Version"
          self.versioned_foreign_key        = options[:foreign_key] || self.to_s.foreign_key
          self.versioned_table_name         = options[:table_name]  || "#{table_name_prefix}#{base_class.name.demodulize.underscore}_versions#{table_name_suffix}"
          self.versioned_inheritance_column = options[:inheritance_column] || "versioned_#{inheritance_column}"
          self.version_column               = options[:version_column]     || 'version'
          self.non_versioned_columns        = [self.primary_key, inheritance_column, 'version', 'lock_version', versioned_inheritance_column, version_column]
          self.file_columns                 = options[:file_columns] || []
          self.white_list_columns           = options[:white_list_columns] || []
          self.revision_comments_column     = options[:revision_comments_column]  || "revision_comments"
          self.version_association_options  = {
                                                :class_name  => "#{self.to_s}::#{versioned_class_name}",
                                                :foreign_key => "#{versioned_foreign_key}",
                                                :order       => 'version',
                                                :dependent   => :destroy
                                              }.merge(options[:association_options] || {})
          self.timestamp_columns            = options[:timestamp_columns]  || [ "created_at", "updated_at" ]
          self.sync_ignore_columns          = options[:sync_ignore_columns]  || []

          class_eval do
            has_many :versions, version_association_options

            before_create :set_new_version
            after_create :save_version_on_create
            after_update :sync_latest_version
          end

          # create the dynamic versioned model
          const_set(versioned_class_name, Class.new(ActiveRecord::Base)).class_eval do
            def self.reloadable? ; false ; end          
            def latest_version
              parent.latest_version
            end
            
            def versions
              parent.versions
            end

            #This assumes that people defining habtm relationships inside
            #the block passed to 'explicit_versioning()' want those habtm relationships
            #set based on a relationship of the same name on the object being versioned
            #example:
            #class Person
            #  has_and_belongs_to_many :events
            #  explicit_versioning() do
            #    has_and_belongs_to_many :events, :join_table => 'person_versions_events'
            #  end
            #This will ensure that the current links to events in the people_events table is copied into the person_versions_events table
            #when the Person::Version object is created
            def self.has_and_belongs_to_many *args
              name = args.first
              after_create proc {|item| item.send("#{name}=", item.parent.send(name))}
              super
            end
          end

          versioned_class.set_table_name versioned_table_name
          versioned_class.belongs_to self.to_s.demodulize.underscore.to_sym,
            :class_name  => "::#{self.to_s}",
            :foreign_key => versioned_foreign_key

          #add a generic method, independent of the model, that gets the thing being versioned.
          versioned_class.belongs_to :parent,
            :class_name  => "::#{self.to_s}",
            :foreign_key => versioned_foreign_key


          if block_given?
            versioned_class.class_eval(&extension)
          end

        end
      end

      module ActMethods
        def self.included(base) # :nodoc:
          base.extend ClassMethods
        end

        # Finds a specific version of this model.
        def find_version(version)
          return version if version.is_a?(self.class.versioned_class)
          return nil if version.is_a?(ActiveRecord::Base)
          find_versions(:conditions => ['version = ?', version], :limit => 1).first
        end

        # Returns the most recent version
        def latest_version
          versions.last
        end

        # Finds versions of this model.  Takes an options hash like <tt>find</tt>
        def find_versions(options = {})
          versions.find(:all, options)
        end

        # Saves the object as a new version and also saves the original object as the new version.
        # Make sure to create (and thus save) any inner associations beforehand as these won't be saved here.
        def save_as_new_version(revision_comment=nil)
          return false unless self.valid?
          without_update_callbacks do
            set_new_version
            self.save
            self.reload
            save_version_on_create(revision_comment)
          end
        end

        def update_version(version_number_to_update, attributes)
          return false if version_number_to_update.nil? or version_number_to_update.to_i < 1
          return false if attributes.nil? or attributes.empty?
          return false unless (ver = find_version(version_number_to_update))

          rtn = ver.update_attributes(attributes)

          if rtn
            # if the latest version has been updated then update the main table as well
            if version_number_to_update.to_i == eval("#{self.class.version_column}")
              return update_main_to_version(version_number_to_update, true)
            else
              return true
            end
          else
            return false
          end
        end

        def destroy_version(version_number)
          if (ver = find_version(version_number))
            without_update_callbacks do
              # For fault tolerance (ie: to prevent data loss through premature deletion), first...
              # Check to see if the current (aka latest) version has to be deleted,
              # and if so update the main table with the data from the version that will become the latest
              if version_number.to_i == eval("#{self.class.version_column}")
                if versions.count > 1
                  to_be_latest_version = versions[versions.count-2].version
                else
                  return false
                end
                success = update_main_to_version(to_be_latest_version)
              end

              # Then... delete the version
              if success
                retrn ver.destroy
              else
                return false
              end
            end
          end
        end

        def describe_version(version_number)
          return "" if versions.count < 2
          return "(earliest)" if version_number == versions.first.version
          return "(latest)" if version_number == versions.last.version
          return ""
        end

        def without_update_callbacks(&block)
          self.class.without_update_callbacks(&block)
        end

        def empty_callback() end #:nodoc:

        protected

          def set_new_version
            self.send("#{self.class.version_column}=", self.next_version)
          end

          # Saves a version of the model in the versioned table. This is called in the after_create callback by default
          def save_version_on_create(revision_comment=nil)
            rev = self.class.versioned_class.new
            self.clone_versioned_model(self, rev)
            rev.version = send(self.class.version_column)
            rev.send("#{self.class.revision_comments_column}=", revision_comment)
            rev.send("#{self.class.versioned_foreign_key}=", self.id)
            saved = rev.save

            if saved
              # Now update timestamp columns on main model.
              # Note: main model doesnt get saved yet.
              update_timestamps(rev, self)
            end

            return saved
          end

          def update_timestamps(from, to)
            begin
              self.timestamp_columns.each do |key|
                if to.has_attribute?(key)
                  logger.debug("explicit_versioning - update_timestamps method - setting timestamp_column '#{key}'")
                  if eval("from.#{key}.nil?")
                    to.send("#{key}=", nil)
                  else
                    to.send("#{key}=", eval("from.#{key}"))
                  end
                end
              end
            rescue => err
              logger.error("ERROR: An error occurred in the explicit_versioning plugin during the update_timestamps method (setting timestamp columns).")
              logger.error("ERROR DETAILS: #{err}")
            end
          end

          # This method updates the latest version entry in the versioned table with the data
          # from the main table (since those two entries should always have the same data).
          def sync_latest_version
            ver = versions.last
            if (ver.nil?)
              save_as_new_version
            else
              clone_versioned_model(self, ver)
              ver.save
            end            
          end

          # This method updates the entry in the main table with the data from the version specified,
          # and also updates the corresponding version column in the main table to reflect this.
          # Note: this method on its own should not be used to revert to previous versions as it doesn't actualy delete any versions.
          def update_main_to_version(version_number, process_file_columns=true)
            if (ver = find_version(version_number))
              clone_versioned_model(ver, self, process_file_columns)
              self.send("#{self.class.version_column}=", version_number)

              # Now update timestamp columns on main model.
              update_timestamps(ver, self)

              return self.save
            else
              return false
            end
          end

          # Clones a model.
          def clone_versioned_model(orig_model, new_model, process_file_columns=true)
            self.versioned_attributes.each do |key|
              # Make sure to ignore file columns, white list columns, timestamp columns and any other ignore columns
              unless self.file_columns.include?(key) ||
                     self.white_list_columns.include?(key) ||
                     self.timestamp_columns.include?(key) ||
                     self.sync_ignore_columns.include?(key)
                new_model.send("#{key}=", eval("orig_model.#{key}")) if orig_model.respond_to?(key)
              end
            end

            if process_file_columns
              # Now copy over file columns
              begin
                self.file_columns.each do |key|
                  if orig_model.has_attribute?(key)
                    if eval("orig_model.#{key}.nil?")
                      logger.debug("DEBUG: file column is nil")
                      new_model.send("#{key}=", nil)
                    else
                      logger.debug("DEBUG: file column is not nil")
                      new_model.send("#{key}=", File.open(eval("orig_model.#{key}")))
                      FileUtils.cp(eval("orig_model.#{key}"), eval("new_model.#{key}"))
                    end
                  end
                end
              rescue => err
                logger.error("ERROR: An error occurred in the explicit_versioning plugin during the clone_versioned_model method (copying file columns).")
                logger.error("ERROR DETAILS: #{err}")
              end
            end

            # Now set white list columns
            begin
              self.white_list_columns.each do |key|
                if orig_model.has_attribute?(key)
                  if eval("orig_model.#{key}.nil?")
                    new_model.send("#{key}=", nil)
                  else
                    new_model.send("#{key}=", eval("orig_model.#{key}"))
                  end
                end
              end
            rescue => err
              logger.error("ERROR: An error occurred in the explicit_versioning plugin during the clone_versioned_model method (setting white list columns).")
              logger.error("ERROR DETAILS: #{err}")
            end

            # Set version column accordingly.
            if orig_model.is_a?(self.class.versioned_class)
              new_model[new_model.class.inheritance_column] = orig_model[self.class.versioned_inheritance_column]
            elsif new_model.is_a?(self.class.versioned_class)
              new_model[self.class.versioned_inheritance_column] = orig_model[orig_model.class.inheritance_column]
            end
          end

          # Gets the next available version for the current record, or 1 for a new record
          def next_version
            return 1 if new_record? || versions.empty?
            (versions.calculate(:max, :version) || 0) + 1
          end

          # Returns an array of attribute keys that are versioned.  See non_versioned_columns
          def versioned_attributes
            self.attributes.keys.select { |k| !self.class.non_versioned_columns.include?(k) }
          end

        module ClassMethods
          # Finds a specific version of a specific row of this model
          def find_version(id, version)
            find_versions(id,
              :conditions => ["#{versioned_foreign_key} = ? AND version = ?", id, version],
              :limit => 1).first
          end

          # Finds versions of a specific model.  Takes an options hash like <tt>find</tt>
          def find_versions(id, options = {})
            versioned_class.find :all, {
              :conditions => ["#{versioned_foreign_key} = ?", id],
              :order      => 'version' }.merge(options)
          end

          # Returns an array of columns that are versioned.  See non_versioned_columns
          def versioned_columns
            self.columns.select { |c| !non_versioned_columns.include?(c.name) }
          end

          # Returns an instance of the dynamic versioned model
          def versioned_class
            const_get versioned_class_name
          end

          # Rake migration task to create the versioned table using options passed
          def create_versioned_table(create_table_options = {})
            # create version column in main table if it does not exist
            if !self.content_columns.find { |c| %w(version lock_version).include? c.name }
              self.connection.add_column table_name, :version, :integer, :default=>1
            end

            self.connection.create_table(versioned_table_name, create_table_options) do |t|
              t.column versioned_foreign_key, :integer
              t.column :version, :integer
              t.column revision_comments_column, :text
            end

            updated_col = nil
            self.versioned_columns.each do |col|
              updated_col = col if !updated_col && %(updated_at updated_on).include?(col.name)
              self.connection.add_column versioned_table_name, col.name, col.type,
                :limit => col.limit,
                :default => col.default
            end

            if type_col = self.columns_hash[inheritance_column]
              self.connection.add_column versioned_table_name, versioned_inheritance_column, type_col.type,
                :limit => type_col.limit,
                :default => type_col.default
            end

            if updated_col.nil?
              self.connection.add_column versioned_table_name, :updated_at, :timestamp
            end
          end

          # Rake migration task to drop the versioned table
          def drop_versioned_table
            self.connection.drop_table versioned_table_name
          end

          # Executes the block with the update callbacks disabled.
          #
          #   Foo.without_update_callbacks do
          #     @foo.save
          #   end
          #
          def without_update_callbacks(&block)
            class_eval do
              CALLBACKS.each do |attr_name|
                alias_method "orig_#{attr_name}".to_sym, attr_name
                alias_method attr_name, :empty_callback
              end
            end
            block.call
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
end

ActiveRecord::Base.class_eval do
  include Jits::Acts::ExplicitVersioning
end
