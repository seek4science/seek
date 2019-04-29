class AssetsCreator < ApplicationRecord
  belongs_to :asset, :polymorphic => true
  belongs_to :creator, :class_name => 'Person'

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :asset
end
