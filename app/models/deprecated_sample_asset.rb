class DeprecatedSampleAsset < ActiveRecord::Base
  belongs_to :asset, polymorphic: true

  # check whether asset is of latest version
  before_save :check_version

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :asset

  # DEPRECATED
  belongs_to :deprecated_sample

  def versioned_asset
    if version
      asset.find_version version
    else
      asset.latest_version
    end
  end

  def check_version
    self.version = asset.version if asset && (version != asset.version)
  end
end
