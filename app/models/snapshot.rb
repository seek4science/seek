class Snapshot < ActiveRecord::Base

  belongs_to :resource, polymorphic: true

  has_one :content_blob, as: :asset, foreign_key: :asset_id

  before_save :set_snapshot_number

  def version # Hack to stop content blob moaning
    nil
  end

  private

  def set_snapshot_number
    snapshot_number = (resource.snapshots.select(:snapshot_number).map(&:snapshot_number).max || 0) + 1
  end

end
