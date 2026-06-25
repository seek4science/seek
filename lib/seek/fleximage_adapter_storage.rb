module Seek
  # Adapter-backed master-image storage for acts_as_fleximage models (Avatar, ModelImage).
  #
  # By default fleximage stores the master image only on local disk (its image_directory) and reads,
  # resizes and serves it from there. That breaks on multi-node S3 deployments: a node that never
  # wrote the file cannot find it. This concern keeps the master in Seek::Storage instead, so it lives
  # in S3 on the S3 backend — mirroring how ContentBlob already backs fleximage with the adapter.
  #
  # On the LOCAL backend this is a transparent no-op: every override falls straight through to
  # fleximage, so behaviour is unchanged.
  #
  # On the S3 backend:
  #   * after save, the freshly-written local master is uploaded to the adapter and the local copy removed
  #   * resize streams a temporary local copy of the master from the adapter (fleximage needs a real path)
  #   * existence checks and destroy cleanup go through the adapter
  #
  # Include this AFTER `acts_as_fleximage` and `acts_as_fleximage_extension` so the overrides win and
  # `super` reaches the fleximage / extension implementations.
  module FleximageAdapterStorage
    extend ActiveSupport::Concern

    included do
      after_save    :upload_master_to_adapter,  if: :remote_storage?
      after_destroy :delete_master_from_adapter, if: :remote_storage?
    end

    # The assets adapter (S3 'assets/' prefix, or asset_filestore_path on local).
    def storage_adapter
      Seek::Storage.adapter_for('dat')
    end

    # A stable per-record key, e.g. "avatar-123.png" / "model_image-7.png".
    def storage_key
      "#{self.class.name.underscore}-#{id}.#{self.class.image_storage_format}"
    end

    # True when the active backend has no local path for this key (i.e. S3). Mirrors the signal
    # ContentBlob uses: LocalAdapter#full_path always returns a path, S3Adapter#full_path returns nil.
    def remote_storage?
      storage_adapter.full_path(storage_key).nil?
    end

    # fleximage reads/writes the master via #file_path (a local path). During an S3-backed resize we
    # point it at a temporary local copy of the master streamed from the adapter.
    def file_path
      @resize_source_path || super
    end

    # On S3 the local master is removed after upload, so stream a temp copy for the resize. The
    # resized result is still cached locally, so this download only happens on the first resize of
    # each size on a given node.
    def resize_image(size = Seek::ActsAsFleximageExtension::STANDARD_SIZE)
      return super if !remote_storage? || cache_exists?(size) || !storage_adapter.exist?(storage_key)

      with_temporary_master do |tmp_path|
        @resize_source_path = tmp_path
        super
      end
    ensure
      @resize_source_path = nil
    end

    # On S3 the master lives in the adapter even when no local file is present on this node.
    def has_saved_image?
      return true if remote_storage? && storage_adapter.exist?(storage_key)

      super
    end

    private

    def local_master_path
      "#{directory_path}/#{id}.#{self.class.image_storage_format}"
    end

    # Runs after fleximage's post_save (which writes the local master), only when a new image was
    # uploaded this save. Uploads that file to the adapter, then drops the local copy.
    def upload_master_to_adapter
      return unless @uploaded_image
      return unless File.exist?(local_master_path)

      storage_adapter.copy_from_path(local_master_path, storage_key)
      File.delete(local_master_path)
    end

    def delete_master_from_adapter
      storage_adapter.delete(storage_key)
    rescue StandardError => e
      Rails.logger.error("Failed to delete master image from storage for #{self.class.name} #{id}: #{e.message}")
    end

    def with_temporary_master
      Tempfile.create(["#{self.class.name.underscore}-#{id}", ".#{self.class.image_storage_format}"]) do |tmp|
        tmp.binmode
        IO.copy_stream(storage_adapter.open(storage_key), tmp)
        tmp.flush
        yield tmp.path
      end
    end
  end
end
