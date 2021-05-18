class GitVersion < ApplicationRecord
  class ImmutableVersionException < StandardError; end
  DEFAULT_LOCAL_REF = 'refs/heads/master'

  include Seek::Git::Util

  belongs_to :resource, polymorphic: true
  belongs_to :contributor, class_name: 'Person'
  belongs_to :git_repository
  has_many :git_annotations

  before_create :set_version
  before_validation :set_git_info, on: :create
  before_validation :set_default_visibility, on: :create
  before_validation :assign_contributor, on: :create
  before_save :set_commit, unless: -> { ref.blank? }

  accepts_nested_attributes_for :git_annotations

  store :resource_attributes, coder: JSON

  include GitSupport

  alias_method :parent, :resource # ExplicitVersioning compatibility

  attr_writer :remote

  delegate :tag_counts, :scales, :managers, :attributions, :creators, :assets_creators, :is_asset?,
           :authorization_supported?, :defines_own_avatar?, :use_mime_type_for_avatar?, :avatar_key,
           :show_contributor_avatars?, :can_see_hidden_item?, :related_people, :projects, :programmes, to: :parent

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

  def freeze
    raise ImmutableVersionException unless mutable?

    self.resource_attributes = resource.attributes
    self.mutable = false
    self.ref = git_base.tags.create(unique_git_tag, commit).canonical_name
    save!
  end

  def add_file(path, io, message: nil)
    message ||= (file_exists?(path) ? 'Updated' : 'Added')
    perform_commit("#{message} #{path}") do |index|
      oid = git_base.write(io.read, :blob) # Write the file into the object DB
      index.add(path: path, oid: oid, mode: 0100644) # Add it to the index
    end
  end

  def add_files(path_io_pairs, message: nil)
    message ||= "Added/updated #{path_io_pairs.count} files"
    perform_commit(message) do |index|
      path_io_pairs.each do |path, io|
        oid = git_base.write(io.read, :blob) # Write the file into the object DB
        index.add(path: path, oid: oid, mode: 0100644) # Add it to the index
      end
    end
  end

  def remove_file(path)
    perform_commit("Deleted #{path}") do |index|
      index.remove(path)
    end
  end

  def move_file(oldpath, newpath)
    perform_commit("Moved #{oldpath} -> #{newpath}") do |index|
      existing = index[oldpath]
      index.add(path: newpath, oid: existing[:oid], mode: 0100644)
      index.remove(oldpath)
    end
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

  private

  def set_version
    self.version = (resource.git_versions.maximum(:version) || 0) + 1
    self.name ||= "v#{version}"
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

  def perform_commit(message, &block)
    raise ImmutableVersionException unless mutable?

    index = git_base.index

    is_initial = git_base.head_unborn?

    index.read_tree(git_base.head.target.tree) unless is_initial

    yield index

    options = {}
    options[:tree] = index.write_tree(git_base.base) # Write a new tree with the changes in `index`, and get back the oid
    options[:author] = git_author
    options[:committer] = git_author
    options[:message] ||= message
    options[:parents] =  git_base.empty? ? [] : [git_base.head.target].compact
    options[:update_ref] = ref unless is_initial

    self.commit = Rugged::Commit.create(git_base.base, options)

    if is_initial
      r = ref.blank? ? DEFAULT_LOCAL_REF : ref
      git_base.references.create(r, self.commit)
      git_base.head = r if git_base.head.blank?
    end

    self.commit
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
    if resource_attributes.key?(method.to_s) && args.empty?
      resource_attributes[method.to_s]
    elsif resource.respond_to?(method)
      resource.public_send(method, *args, &block)
    else
      super
    end
  end
end
