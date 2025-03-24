module Git
  class Version < ApplicationRecord
    # Attributes that should not be copied in from parent resource
    SYNC_IGNORE_ATTRIBUTES = %w(id version doi visibility created_at updated_at).freeze
    cattr_accessor :git_sync_ignore_attributes

    belongs_to :resource, polymorphic: true, inverse_of: :git_versions
    belongs_to :contributor, class_name: 'Person'
    belongs_to :git_repository, class_name: 'Git::Repository'
    has_many :git_annotations, inverse_of: :git_version, dependent: :destroy, class_name: 'Git::Annotation', foreign_key: :git_version_id
    has_many :remote_source_annotations, -> { where(key: 'remote_source') }, autosave: true,
             inverse_of: :git_version, dependent: :destroy, class_name: 'Git::Annotation', foreign_key: :git_version_id

    before_validation :set_version, on: :create
    before_validation :set_git_info, on: :create
    before_validation :set_default_visibility, on: :create
    before_validation :assign_contributor, on: :create
    before_save :set_commit, unless: -> { ref.blank? }
    after_create :set_resource_version
    after_create :set_git_repository_resource

    accepts_nested_attributes_for :git_annotations

    store :resource_attributes, coder: JSON
    validates :name, length: { minimum: 1 }
    validates :git_repository, presence: true
    validate :git_repository_linkable

    include Git::Operations
    include Seek::UrlValidation
    acts_as_favouritable


    alias_method :parent, :resource # ExplicitVersioning compatibility

    attr_writer :remote

    delegate :tag_counts, :managers, :attributions, :creators, :assets_creators, :is_asset?,
             :authorization_supported?, :defines_own_avatar?, :use_mime_type_for_avatar?, :avatar_key,
             :show_contributor_avatars?, :can_see_hidden_item?, :related_people, :projects, :programmes, to: :parent

    delegate_auth_to :parent

    # def name
    #   super || "Version #{version}"
    # end

    def latest_git_version?
      resource.latest_git_version == self
    end

    def is_a_version?
      true
    end

    def is_git_versioned?
      true
    end

    def mutable?
      if persisted?
        super
      else
        git_repository&.remote.blank?
      end
    end

    def remote
      @remote || git_repository&.remote
    end

    def remote?
      @remote.present? || git_repository&.remote.present?
    end

    def lock
      unless mutable?
        errors.add(:base, 'is already frozen')
        return false
      end
      if unborn?
        errors.add(:base, 'has no content')
        return false
      end

      self.mutable = false
      self.ref = git_base.tags.create(unique_git_tag, commit).canonical_name
      save!
    end

    def commit
      super || get_commit
    end

    def visibility= key
      super(Seek::ExplicitVersioning::VISIBILITY_INV[key.to_sym] || Seek::ExplicitVersioning::VISIBILITY_INV[self.class.default_visibility])
    end

    def visibility
      Seek::ExplicitVersioning::VISIBILITY[super]
    end

    def can_change_visibility?
      !latest_git_version? && doi.blank?
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

    def git_version
      self
    end

    def cache_key_fragment
      "#{resource_type.underscore}-#{resource_id}-#{commit}"
    end

    def path_for_key(key)
      find_git_annotation(key)&.path
    end

    def find_git_annotation(key)
      git_annotations.where(key: key).first ||
        git_annotations.detect { |a| a.key.to_s == key.to_s }
    end

    def find_git_annotations(key)
      git_annotations.where(key: key).to_a |
        git_annotations.select { |a| a.key.to_s == key.to_s }
    end

    def ro_crate?
      file_exists?('ro-crate-metadata.json') || file_exists?('ro-crate-metadata.jsonld')
    end

    def revision_comments
      comment
    end

    def commit_object
      git_base.lookup(commit)
    end

    def set_default_metadata
      if git_repository.remote?
        self.name = (ref.split('/').last + ((branch? && commit) ? " @ #{commit.first(7)}" : '')) if self[:name].blank?
        self.comment ||= commit_object&.message
      end
    end

    def tag?
      ref.start_with?('refs/tags')
    end

    def branch?
      ref.start_with?('refs/heads') || ref.start_with?('refs/remotes')
    end

    # Initialize a follow-up version to this one, with the version number bumped.
    def next_version(extra_attributes = {})
      resource.git_versions.build.tap do |gv|
        [:visibility, :git_repository_id, :ref, :commit, :root_path].each do |attr|
          gv.send("#{attr}=", send(attr))
        end
        gv.comment = nil
        gv.ref = nil
        gv.version = (version + 1)
        gv.name = "Version #{gv.version}"
        gv.set_resource_attributes(resource.attributes)
        gv.assign_attributes(extra_attributes)
        gv.git_annotations = git_annotations.map(&:dup)
      end
    end

    def to_schema_ld
      Seek::BioSchema::Serializer.new(self).json_ld
    end

    def schema_org_supported?
      Seek::BioSchema::Serializer.supported?(resource)
    end

    def sync_resource_attributes
      set_resource_attributes(resource.attributes)
      save(validate: false)
    end

    def remote_sources= hash
      to_keep = []
      existing = remote_source_annotations.to_a

      hash.each do |path, url|
        annotation = existing.detect { |a| a.path == path }
        if annotation.nil? || annotation.value != url
          annotation ||= remote_source_annotations.build(path: path)
          annotation.value = url
        end

        to_keep << annotation
      end

      to_destroy = existing - to_keep
      to_destroy.each(&:mark_for_destruction)

      hash
    end

    def remote_sources
      h = {}

      remote_source_annotations.each do |ann|
        h[ann.path] = ann.value
      end

      h
    end

    def set_resource_attributes(attrs)
      self.resource_attributes = attrs.with_indifferent_access.except(*self.class.sync_ignore_attributes)
    end

    def self.sync_ignore_attributes
      git_sync_ignore_attributes + SYNC_IGNORE_ATTRIBUTES
    end

    def set_default_git_repository
      if @remote.present?
        self.git_repository ||= Git::Repository.find_or_create_by(remote: @remote)
      else
        self.git_repository ||= (resource.local_git_repository || Git::Repository.create)
        self.ref = DEFAULT_LOCAL_REF if self.ref.blank?
      end
    end

    def immutable_error
      return nil if mutable?
      if remote?
        I18n.t('git.modify_immutable_remote_error')
      else
        I18n.t('git.modify_immutable_error')
      end
    end

    def add_remote_file(path, url, fetch: true, message: nil)
      raise URI::InvalidURIError, "URL (#{url}) must be a valid, accessible remote URL" unless valid_url?(url)

      add_file(path, StringIO.new(''), message: message).tap do
        self.remote_sources = remote_sources.merge(path => url)
        RemoteGitContentFetchingJob.perform_later(self, path) if fetch
      end
    end

    def fetch_remote_file(path)
      io = get_blob(path)&.remote_content
      add_file(path, io, message: "Fetched #{path} from URL") if io
    end

    def search_terms
      []
    end

    private

    def set_version
      self.version = (resource.git_versions.maximum(:version) || 0) + 1
      self.name = "Version #{self.version}" if self[:name].blank?
    end

    def set_git_info
      set_default_git_repository
      self.mutable = git_repository&.remote.blank? if self.mutable.nil?
    end

    def set_commit
      self.commit = get_commit if self[:commit].blank?
    end

    def get_commit
      git_repository.resolve_ref(ref) if ref
    end

    def unique_git_tag
      [name.gsub(/[ :~^]/,'-'), "version-#{version}", "_seek_git_version_#{id}"].each do |t|
        if Rugged::Reference.valid_name?("refs/tags/#{t}") && !git_base.tags[t]
          return t
        end
      end

      x = 1
      while true
        t = "_seek_unique_tag_#{x}"
        if Rugged::Reference.valid_name?("refs/tags/#{t}") && !git_base.tags[t]
          return t
        end

        x += 1
      end
    end

    def assign_contributor
      self.contributor ||= User.current_user&.person
    end

    # Check metadata, and parent resource for missing methods. Allows a Workflow::Git::Version to be used as a drop-in replacement for
    #  Workflow::Version etc.
    def respond_to_missing?(name, include_private = false)
      resource_attributes.key?(name.to_s) || super
    end

    def method_missing(method, *args, &block)
      s_method = method.to_s
      setter = false
      if s_method.end_with?('=')
        setter = true
        s_method.chomp!('=')
        method = s_method.to_sym
      end
      if resource_attributes.key?(s_method)
        args.unshift(s_method)
        if setter
          resource_attributes.send(:[]=, *args)
        else
          resource_attributes.send(:[], *args)
        end
      elsif !setter && resource.respond_to?(method)
        resource.public_send(method, *args, &block)
      else
        super
      end
    end

    def git_repository_linkable
      unless git_repository.remote? || git_repository.resource.blank? || git_repository.resource == resource
        errors.add(:git_repository, 'already linked to another resource')
      end
    end

    def set_git_repository_resource
      git_repository.update_attribute(:resource, resource) unless git_repository.remote?
    end

    def set_resource_version
      resource.update_column(:version, version)
    end
  end
end
