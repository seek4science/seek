class GitVersion < ApplicationRecord
  class ImmutableVersionException < StandardError; end

  include Seek::Git::Util

  attr_writer :git_repository_remote
  belongs_to :resource, polymorphic: true
  belongs_to :git_repository
  has_many :git_annotations
  before_validation :set_git_version_and_repo, on: :create
  before_save :set_commit, unless: -> { ref.blank? }

  accepts_nested_attributes_for :git_annotations

  include GitSupport

  def metadata
    JSON.parse(super || '{}')
  end

  def metadata= m
    super(m.to_json)
  end

  def latest_git_version?
    resource.latest_git_version == self
  end

  def is_a_version?
    true
  end

  def freeze_version
    self.metadata = resource.attributes
    self.mutable = false
    save!
  end

  def proxy
    resource.class.proxy_class.new(resource, self)
  end

  def add_file(path, io)
    message = file_exists?(path) ? 'Updated' : 'Added'
    perform_commit("#{message} #{path}") do |index|
      oid = git_base.write(io.read, :blob) # Write the file into the object DB
      index.add(path: path, oid: oid, mode: 0100644) # Add it to the index
    end
  end

  def path_for_key(annotation_key)
    persisted? ? git_annotations.where(key: annotation_key.to_s).first&.path : git_annotations.detect { |ga| ga.key.to_s == annotation_key.to_s }&.path
  end

  def commit
    super || get_commit
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

  def set_git_version_and_repo
    if @git_repository_remote
      self.git_repository = GitRepository.where(remote: @git_repository_remote).first_or_initialize
    else
      self.git_repository = resource.local_git_repository || resource.build_local_git_repository
    end
  end
end
