module GitSupport
  extend ActiveSupport::Concern

  def git_base
    git_repository.git_base
  end

  def file_contents(path, &block)
    blob = object(path)
    return unless blob&.is_a?(Rugged::Blob)

    if block_given?
      block.call(StringIO.new(blob.content)) # Rugged does not support streaming blobs :(
    else
      blob.content
    end
  end

  def object(path)
    return nil unless commit
    git_base.lookup(tree.path(path)[:oid])
  rescue Rugged::TreeError
    nil
  end

  def tree
    git_base.lookup(commit).tree if commit
  end

  def trees
    t = []
    return t unless commit

    tree.each_tree { |tree| t << tree }
    t
  end

  def blobs
    b = []
    return b unless commit

    tree.each_blob { |blob| b << blob }
    b
  end

  def file_exists?(path)
    !object(path).nil?
  end

  # Checkout the commit into the given directory.
  def in_dir(dir)
    base = git_base.base
    wd = base.workdir
    base.workdir = dir
    base.checkout_tree(tree.oid, strategy: [:dont_update_index, :force, :no_refresh])
  ensure
    if base && wd
      base.workdir = wd
    end
  end

  def in_temp_dir
    Dir.mktmpdir do |dir|
      in_dir(dir)
      yield dir
    end
  end
end
