class AssayAsset < ActiveRecord::Base
  
  belongs_to :asset
  belongs_to :assay

  named_scope :sops,:joins=>:asset,:conditions=>['assets.resource_type = ?','Sop']
  named_scope :data_files,:joins=>:asset,:conditions=>['assets.resource_type = ?','DataFile']
  named_scope :models,:joins=>:asset,:conditions=>['assets.resource_type = ?','Model']

  before_save :check_version

  def versioned_resource
    return asset.resource.find_version(version)
  end

  private

  def check_version   
    self.version=asset.resource.version if version.nil?
  end

end
