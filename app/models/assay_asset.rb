class AssayAsset < ActiveRecord::Base
  
  belongs_to :asset, :polymorphic => true
  belongs_to :assay

  belongs_to :relationship_type

end
