class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include HasFilters
  include Seek::AnnotatableExtensions
  include Seek::VersionedResource
  include Seek::ExplicitVersioning
  include Git::Versioning
  include Seek::Favouritable
  include Seek::ActsAsDiscussable
  include Seek::ActsAsFleximageExtension
  include Seek::UniquelyIdentifiable
  include Seek::ActsAsYellowPages
  include Seek::GroupedPagination
  include Seek::TitleTrimmer
  include Seek::ActsAsAsset
  include Seek::ActsAsISA
  include HasCustomMetadata
  include Seek::Doi::ActsAsDoiMintable
  include Seek::Doi::ActsAsDoiParent
  include Seek::ResearchObjects::ActsAsSnapshottable
  include Zenodo::ActsAsZenodoDepositable
  include SiteAnnouncements
  include Seek::Permissions::AuthorizationEnforcement
  include Seek::Permissions::ActsAsAuthorized
  include Seek::RelatedItems
  include HasTasks
  include HasControlledVocabularyAnnotations

  include Annotations::Acts::Annotatable
  include Annotations::Acts::AnnotationSource
  include Annotations::Acts::AnnotationValue

  def self.is_taggable?
    false # defaults to false, unless it includes Taggable which will override this and check the configuration
  end

  # takes and ignores arguments for use in :after_add => :update_timestamp, etc.
  def update_timestamp(*_args)
    current_time = current_time_from_proper_timezone

    write_attribute('updated_at', current_time) if respond_to?(:updated_at)
    write_attribute('updated_on', current_time) if respond_to?(:updated_on)
  end

  def defines_own_avatar?
    false
  end

  def use_mime_type_for_avatar?
    false
  end

  def avatar_key
    thing = self
    thing = thing.parent if thing.class.name.include?('::Version')
    return nil if thing.use_mime_type_for_avatar? || thing.defines_own_avatar?
    "#{thing.class.name.underscore}_avatar"
  end

  def show_contributor_avatars?
    respond_to?(:contributor) || respond_to?(:creators)
  end

  def is_downloadable?
    (respond_to?(:content_blob) || respond_to?(:content_blobs))
  end

  # a method that can be overridden for cases where an item is downloadable, but for some reason (e.g. size), is disabled
  def download_disabled?
    !is_downloadable?
  end

  def versioned?
    respond_to? :versions
  end

  def suggested_type?
    self.class.include? Seek::Ontologies::SuggestedType
  end

  def self.subscribable?
    false
  end

  def subscribable?
    self.class.subscribable?
  end

  def self.supports_doi?
    false
  end

  def supports_doi?
    self.class.supports_doi?
  end

  def self.with_search_query(q)
    if searchable? && Seek::Config.solr_enabled
      ids = solr_cache(q) do
        search = search do |query|
          query.keywords(q)
          query.paginate(page: 1, per_page: unscoped.count)
        end
        search.hits.map(&:primary_key)
      end

      where(id: ids)
    else
      all
    end
  end

  def self.solr_cache(query)
    init_solr_cache
    RequestStore.store[:solr][table_name][:last_query] = query
    RequestStore.store[:solr][table_name][query] ||= yield if block_given?
    RequestStore.store[:solr][table_name][query] || []
  end

  def self.last_solr_query
    init_solr_cache
    RequestStore.store[:solr][table_name][:last_query]
  end

  def self.init_solr_cache
    RequestStore.store[:solr] ||= {}
    RequestStore.store[:solr][table_name] ||= { results: {} }
  end

  has_filter query: Seek::Filtering::SearchFilter.new
  has_filter created_at: Seek::Filtering::DateFilter.new(field: :created_at,
                                                         presets: [24.hours, 1.week, 1.month, 1.year, 5.years])
  has_filter updated_at: Seek::Filtering::DateFilter.new(field: :updated_at,
                                                         presets: [24.hours, 1.week, 1.month, 1.year, 5.years])

  def is_a_version?
    false
  end

  def is_git_versioned?
    false
  end

  def contributor_credited?
    return false unless respond_to?(:contributor) && respond_to?(:creators)
    creators.empty?
  end

  def cache_key_fragment
    base = "#{self.class.name.underscore}-#{id}"
    base << "-#{version}" if versioned?
    base
  end

  def self.feature_enabled?
    method = "#{name.underscore.pluralize}_enabled"
    !Seek::Config.respond_to?(method) || Seek::Config.send(method)
  end

  # TODO: Decide what this should actually do, since it doesn't check user roles etc.
  def self.user_creatable?
    false
  end

  def allowed_table_columns
    Seek::IndexTableColumnDefinitions.allowed_columns(self)
  end

  def default_table_columns
    Seek::IndexTableColumnDefinitions.default_columns(self)
  end

  def required_table_columns
    Seek::IndexTableColumnDefinitions.required_columns(self)
  end

  #TODO: this could potentially be moved into a module that pulls together all the generated cache keys into one place
  def list_item_title_cache_key_prefix
    "rli_title_#{cache_key}"
  end

  def updated_last_by
    ActivityLog.where(activity_loggable:self, action:'update').last&.culprit&.person
  end
end
