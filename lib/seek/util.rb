module Seek
  module Util
    # This method removes the special Rails parameters from a params hash provided.
    #
    # NOTE: the provided params collection will not be affected.
    # Instead, a new hash will be returned.
    def self.remove_rails_special_params_from(params, additional_to_remove = [])
      # TODO: Refactor me to use strong param filtering
      params = params.to_unsafe_h if params.is_a?(ActionController::Parameters)
      return {} if params.blank?

      special_params = %w[id format controller action commit].concat(additional_to_remove)
      params.reject { |k, _v| special_params.include?(k.to_s.downcase) }
    end

    def self.clear_cached
      @cache = {}
    end

    def self.ensure_models_loaded
      cache('models_loaded') do
        Dir.glob("#{Rails.root}/app/models/**/*.rb").each do |file|
          unless file.start_with?("#{Rails.root}/app/models/concerns")
            model_name = file.gsub('.rb', '').gsub(File::SEPARATOR, '/').gsub("#{Rails.root}/app/models/", '')
            model_name.camelize.constantize
          end
        end
        true
      end
    end

    def self.persistent_classes
      cache('persistent_classes') do
        ensure_models_loaded
        filter_disabled(ApplicationRecord.descendants)
      end
    end

    # List of activerecord model classes that are directly creatable by a standard user (e.g. uploading a new DataFile, creating a new Assay, but NOT creating a new Project)
    # returns a list of all types that respond_to and return true for user_creatable?
    def self.user_creatable_types
      # FIXME: the user_creatable? is a bit mis-leading since we now support creation of people, projects, programmes by certain people in certain roles.
      cache('creatable_model_classes') do
        persistent_classes.select do |c|
          c.user_creatable?
        end.sort_by { |a| [a.is_asset? ? -1 : 1, a.is_isa? ? -1 : 1, a.name] }
      end
    end

    def self.authorized_types
      cache('policy_authorised_types') do
        persistent_classes.select do |c|
          c.respond_to?(:authorization_supported?) && c.authorization_supported?
        end.sort_by(&:name)
      end
    end

    def self.searchable_types
      # FIXME: hard-coded extra types - are are these items now user_creatable?
      # FIXME: remove the reliance on user-creatable, partly by respond_to?(:reindex) but also take into account if it has been enabled or not
      #- could add a searchable? method
      extras = [Person, Programme, Project, Institution, Organism, HumanDisease]
      cache('searchable_types') { filter_disabled(user_creatable_types | extras).sort_by(&:name) }
    end

    def self.rdf_capable_types
      cache('rdf_capable_types') do
        Seek::Rdf::JERMVocab.defined_types.keys
      end
    end

    def self.asset_types
      cache('asset_types') do
        persistent_classes.select(&:is_asset?).sort_by(&:name)
      end
    end

    def self.inline_viewable_content_types
      # FIXME: needs to be discovered rather than hard-code classes here
      [DataFile, Document, FileTemplate, Model, Presentation, Sop]
    end

    def self.multi_files_asset_types
      asset_types.select do |c|
        c.instance_methods.include?(:content_blobs)
      end
    end

    def self.is_multi_file_asset_type?(klass)
      multi_files_asset_types.any? { |c| c.name == klass.name }
    end

    def self.doiable_asset_types
      cache('doiable_types') do
        persistent_classes.select(&:supports_doi?).sort_by(&:name)
      end
    end

    def self.uuid_types
      cache('uuid_types') do
        persistent_classes.select { |c| c.method_defined?(:uuid) }.sort_by(&:name)
      end
    end

    # determines the batch size for bulk inserts, as sqlite3 below version 3.7.11 doesn't handle it and requires a size
    # of 1
    def self.bulk_insert_batch_size
      cache('bulk_insert_batch_size') do
        default_size = 100
        if database_type == 'sqlite3' && !sqlite3_supports_bulk_inserts
          Rails.logger.info('Sqlite3 version < 3.7.11 detected, so using single rather than bulk inserts')
          1
        else
          default_size
        end
      end
    end

    # whether the sqlite3 version can support bulk inserts, needs to be 3.7.11 or greater
    def self.sqlite3_supports_bulk_inserts
      Gem::Version.new(sqlite3_version) >= Gem::Version.new('3.7.11')
    end

    # the version of the current sqlite3 database
    def self.sqlite3_version
      cache('sqlite3_version') do
        ActiveRecord::Base.connection.select_one('SELECT SQLITE_VERSION()').values[0]
      end
    end

    def self.database_type
      ActiveRecord::Base.connection.instance_values['config'][:adapter]
    end

    def self.delayed_job_pids
      directory = "#{Rails.root}/tmp/pids"
      Daemons::PidFile.find_files(directory, 'delayed_job').collect do |path|
        file = path.sub("#{directory}/", '').sub('.pid', '')
        Daemons::PidFile.new(directory, file)
      end
    end

    # Use this to avoid needlessly regenerating the url helper module each time a route needs to be accessed
    def self.routes
      @_routes ||= Rails.application.routes.url_helpers
    end

    def self.python_exec(cmd)
      "python3.9 #{cmd}"
    end

    def self.lookup_class(class_name, raise: true)
      c = persistent_class_lookup[class_name]
      raise NameError, "#{class_name} not an appropriate class" if c.nil? && raise
      c
    end

    private

    def self.persistent_class_lookup
      cache('persistent_class_lookup') do
        lookup = {}
        persistent_classes.each do |klass|
          lookup[klass.name] = klass
        end
        lookup
      end
    end

    def self.cache(name, &block)
      @cache ||= {}
      if Rails.env.development? # Don't use caching in development mode
        block.call
      else
        @cache[name] ||= block.call
      end
    end

    def self.filter_disabled(types)
      types.select(&:feature_enabled?)
    end

  end
end
