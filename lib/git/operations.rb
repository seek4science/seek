module Git
  module Operations
    include Git::Config

    DEFAULT_LOCAL_REF = 'refs/heads/master'

    def git_base
      git_repository.git_base
    end

    def file_contents(path, fetch_remote: false, &block)
      get_blob(path)&.file_contents(fetch_remote: fetch_remote, &block)
    end

    def object(path)
      return nil unless commit
      o = git_base.lookup(tree.entry(path)[:oid])
      if o.is_a?(Rugged::Blob)
        Git::Blob.new(self, o, path)
      elsif o.is_a?(Rugged::Tree)
        Git::Tree.new(self, o, path)
      else
        o
      end
    rescue Rugged::TreeError
      nil
    end

    def get_blob(path)
      return nil unless commit && path.present?
      tree.get_blob(path)
    end

    def get_tree(path)
      return nil unless commit && path.present?
      tree.get_tree(path)
    end

    def tree
      return nil unless commit
      Git::Tree.new(self, git_base.lookup(commit).tree)
    end

    def trees
      return [] unless commit
      tree.trees
    end

    def blobs
      return [] unless commit
      tree.blobs
    end

    def file_exists?(path)
      !object(path).nil?
    end

    def total_size
      return 0 unless commit
      tree.total_size
    end

    def no_content?
      persisted? && blobs.empty? && trees.empty?
    end

    # In the case that the repository was created but has no commits.
    def unborn?
      persisted? && commit.nil?
    end

    # Checkout the commit into the given directory.
    def in_dir(dir)
      return if commit.nil?
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

    def add_file(path, io, message: nil)
      message ||= "#{file_exists?(path) ? 'Updated' : 'Added'} #{path}"
      begin
        perform_commit(message) do |index|
          write_blob(index, path, io)
        end
      rescue Rugged::TreeError
        raise Git::InvalidPathException.new(path: path)
      end
    end

    # If the `replace` flag is set, remove any files not present in the new set.
    def add_files(path_io_pairs, message: nil, replace: false)
      message ||= "Added/updated #{path_io_pairs.count} files"
      begin
        perform_commit(message) do |index|
          if replace
            to_keep = Set.new(path_io_pairs.map(&:first))
            to_remove = []
            index.entries.each do |entry|
              to_remove << entry[:path] unless to_keep.include?(entry[:path])
            end
            to_remove.each do |path|
              index.remove(path)
              git_annotations.where(path: path).destroy_all if respond_to?(:git_annotations)
            end
          end
          path_io_pairs.each do |path, io|
            write_blob(index, path, io)
          end
        end
      rescue Rugged::TreeError
        raise Git::InvalidPathException.new
      end
    end

    def replace_files(path_io_pairs, message: nil)
      add_files(path_io_pairs, message: message, replace: true)
    end

    def remove_file(path, update_annotations: true)
      raise Git::PathNotFoundException.new(path: path) unless file_exists?(path)

      c = perform_commit("Deleted #{path}") do |index|
        index.remove(path)
      end

      git_annotations.where(path: path).destroy_all if respond_to?(:git_annotations) && update_annotations

      c
    end

    def move_file(oldpath, newpath, update_annotations: true)
      raise Git::PathNotFoundException.new(path: oldpath) unless file_exists?(oldpath)

      begin
        c = perform_commit("Moved #{oldpath} -> #{newpath}") do |index|
          existing = index[oldpath]
          index.add(path: newpath, oid: existing[:oid], mode: 0100644)
          index.remove(oldpath)
        end

        git_annotations.where(path: oldpath).update_all(path: newpath) if respond_to?(:git_annotations) && update_annotations

        c
      rescue Rugged::TreeError
        raise Git::InvalidPathException.new(path: newpath)
      end
    end

    private

    def perform_commit(message, &block)
      raise Git::ImmutableVersionException unless mutable?

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

    def write_blob(index, path, io)
      oid = git_base.write(io.read, :blob) # Write the file into the object DB
      index.add(path: path, oid: oid, mode: 0100644) # Add it to the index
    rescue Rugged::IndexError
      raise Git::InvalidPathException.new(path: path)
    end
  end
end
