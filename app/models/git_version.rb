class GitVersion < ApplicationRecord
  include Seek::Git::Util

  belongs_to :resource, polymorphic: true
  belongs_to :contributor, class_name: 'Person'
  belongs_to :git_repository
  has_many :git_annotations, inverse_of: :git_version

  before_create :set_version
  before_validation :set_git_info, on: :create
  before_validation :set_default_visibility, on: :create
  before_validation :assign_contributor, on: :create
  before_save :set_commit, unless: -> { ref.blank? }
  after_create :set_git_repository_resource

  accepts_nested_attributes_for :git_annotations

  store :resource_attributes, coder: JSON
  validate :git_repository_linkable

  include GitSupport

  alias_method :parent, :resource # ExplicitVersioning compatibility

  attr_writer :remote

  delegate :tag_counts, :scales, :managers, :attributions, :creators, :assets_creators, :is_asset?,
           :authorization_supported?, :defines_own_avatar?, :use_mime_type_for_avatar?, :avatar_key,
           :show_contributor_avatars?, :can_see_hidden_item?, :related_people, :projects, :programmes, to: :parent

  delegate_auth_to :parent

  def name
    super || "Version #{version}"
  end

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

  def remote?
    git_repository&.remote.present?
  end

  def lock
    unless mutable?
      errors.add(:base, 'is already frozen')
      return false
    end

    self.resource_attributes = resource.attributes
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
    git_annotations.where(key: key) ||
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
    git_version = self.dup
    git_version.name = nil
    git_version.comment = nil
    git_version.ref = nil
    git_version.version = (version + 1)
    git_version.resource_attributes = resource.attributes
    git_version.assign_attributes(extra_attributes)
    git_version.git_annotations = git_annotations.map(&:dup)
    git_version
  end

  private

  def set_version
    self.version = (resource.git_versions.maximum(:version) || 0) + 1
    self.name = "Version #{self.version}" if self[:name].blank?
  end

  def set_git_info
    if @remote.present?
      self.git_repository ||= GitRepository.find_or_create_by(remote: @remote)
    else
      self.git_repository ||= (resource.local_git_repository || resource.create_local_git_repository)
      self.ref = DEFAULT_LOCAL_REF if self.ref.blank?
    end
    self.git_repository ||= @remote.present? ? GitRepository.find_or_create_by(remote: @remote) : resource.local_git_repository || resource.create_local_git_repository
    self.mutable = git_repository&.remote.blank? if self.mutable.nil?
  end

  def set_commit
    self.commit = get_commit if commit.blank?
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

  # Check metadata, and parent resource for missing methods. Allows a Workflow::GitVersion to be used as a drop-in replacement for
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
      if setter
        resource_attributes[s_method] = *args
      else
        resource_attributes[s_method]
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
end
