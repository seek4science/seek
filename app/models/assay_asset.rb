class AssayAsset < ActiveRecord::Base
  belongs_to :asset, polymorphic: true
  belongs_to :assay

  belongs_to :relationship_type

  before_save :check_version

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :assay

  def check_version
    return unless asset.respond_to?(:latest_version)
    if version.nil? && !asset.nil? && (asset.class.name.end_with?('::Version') || (!asset.latest_version.nil? && asset.latest_version.class.name.end_with?('::Version')))
      self.version = asset.version
    end
  end

  def incoming_direction?
    direction == Direction::INCOMING
  end

  def outgoing_direction?
    direction == Direction::OUTGOING
  end

  # constants for recording the direction of the asset with its relationship to the assay
  module Direction
    INCOMING = 1
    OUTGOING = 2
    NODIRECTION = 0
  end
end
