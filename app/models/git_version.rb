class GitVersion < ApplicationRecord
  class ImmutableVersionException < StandardError; end

  include Seek::Git::Util

  attr_writer :git_repository_remote
  belongs_to :resource, polymorphic: true
  belongs_to :git_repository
  has_many :git_annotations
  before_validation :set_default_visibility, on: :create
  before_save :set_commit, unless: -> { ref.blank? }

  accepts_nested_attributes_for :git_annotations

  include GitSupport

  def resource_attributes
    JSON.parse(super || '{}')
  end

  def resource_attributes= m
    super(m.to_json)
  end

  def latest_git_version?
    resource.latest_git_version == self
  end

  def is_a_version?
    true
  end

  def freeze_version
    self.resource_attributes = resource.attributes
    self.mutable = false
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

  def path_for_key(annotation_key)
    persisted? ? git_annotations.where(key: annotation_key.to_s).first&.path : git_annotations.detect { |ga| ga.key.to_s == annotation_key.to_s }&.path
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

  private

  def set_commit
    self.commit ||= get_commit
  end

  def get_commit
    git_repository.resolve_ref(ref) if ref
  end

  def perform_commit(message, &block)
    raise ImmutableVersionException unless mutable?

    index = git_base.index

    index.read_tree(git_base.head.target.tree) unless git_base.head_unborn?

    yield index

    options = {}
    options[:tree] = index.write_tree(git_base.base) # Write a new tree with the changes in `index`, and get back the oid
    options[:author] = git_author
    options[:committer] = git_author
    options[:message] ||= message
    options[:parents] =  git_base.empty? ? [] : [git_base.head.target].compact
    options[:update_ref] = ref

    self.commit = Rugged::Commit.create(git_base.base, options)
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
