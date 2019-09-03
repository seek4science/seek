class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include Seek::AnnotatableExtensions
  include Seek::VersionedResource
  include Seek::ExplicitVersioning
  include Seek::Favouritable
  include Seek::ActsAsFleximageExtension
  include Seek::UniquelyIdentifiable
  include Seek::YellowPages
  include Seek::GroupedPagination
  include Seek::Scalable
  include Seek::TitleTrimmer
  include Seek::ActsAsAsset
  include Seek::ActsAsISA
  include Seek::Doi::ActsAsDoiMintable
  include Seek::Doi::ActsAsDoiParent
  include Seek::ResearchObjects::ActsAsSnapshottable
  include Zenodo::ActsAsZenodoDepositable
  include SiteAnnouncements
  include Seek::Permissions::AuthorizationEnforcement
  include Seek::Permissions::ActsAsAuthorized
  include Seek::RelatedItems

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
    respond_to?(:avatar)
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
    include? Seek::Subscribable
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
end
