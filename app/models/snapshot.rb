require 'zip'

# Investigation "snapshot"
class Snapshot < ActiveRecord::Base

  belongs_to :resource, polymorphic: true
  has_one :content_blob, as: :asset, foreign_key: :asset_id

  before_save :set_snapshot_number

  # Must quack like an asset version to behave with DOI code
  alias_attribute :parent, :resource
  alias_attribute :parent_id, :resource_id
  alias_attribute :version, :snapshot_number

  def manifest
    zip = Zip::File.open(content_blob.filepath)

    begin
      value = zip.read('.ro/manifest.json')
    rescue Errno::ENOENT
      value = nil
    ensure
      zip.close
    end

    value
  end

  private

  def set_snapshot_number
    self.snapshot_number = (resource.snapshots.maximum(:snapshot_number) || 0) + 1
  end

end
