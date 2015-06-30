require 'zip'

class Snapshot < ActiveRecord::Base

  belongs_to :resource, polymorphic: true

  has_one :content_blob, as: :asset, foreign_key: :asset_id

  before_save :set_snapshot_number

  def version # Hack to stop content blob moaning
    nil
  end

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
    self.snapshot_number = (resource.snapshots.select(:snapshot_number).map(&:snapshot_number).max || 0) + 1
  end

end
