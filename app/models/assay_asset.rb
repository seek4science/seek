class AssayAsset < ActiveRecord::Base
  belongs_to :asset, polymorphic: true, inverse_of: :assay_assets
  belongs_to :assay, inverse_of: :assay_assets

  belongs_to :relationship_type

  before_save :set_version

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :assay

  scope :incoming, -> { where(direction: Direction::INCOMING) }
  scope :outgoing, -> { where(direction: Direction::OUTGOING) }

  scope :validation, -> { joins(:relationship_type).where('relationship_types.key = ?', RelationshipType::VALIDATION) }
  scope :simulation, -> { joins(:relationship_type).where('relationship_types.key = ?', RelationshipType::SIMULATION) }
  scope :construction, -> { joins(:relationship_type).where('relationship_types.key = ?', RelationshipType::CONSTRUCTION) }

  enforce_authorization_on_association :assay, :edit
  enforce_authorization_on_association :asset, :view

  def set_version
    return if destroyed?
    return unless asset && asset.respond_to?(:latest_version) && asset.latest_version
    self.version = asset.version
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
