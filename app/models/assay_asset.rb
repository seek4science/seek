class AssayAsset < ActiveRecord::Base
  
  belongs_to :asset
  belongs_to :assay

  named_scope :sops,:joins=>:asset,:conditions=>['assets.resource_type = ?','Sop'], :include => {:asset => {:resource => :versions}}
  named_scope :data_files,:joins=>:asset,:conditions=>['assets.resource_type = ?','DataFile'], :include => {:asset => {:resource => :versions}}
  named_scope :models,:joins=>:asset,:conditions=>['assets.resource_type = ?','Model'], :include => {:asset => {:resource => :versions}}

  belongs_to :relationship_type

  before_save :check_version

  def versioned_resource
    return asset.resource.versions.select{|x| x.version == version}.first
  end

  private

  def check_version   
    self.version=asset.resource.version if version.nil?
  end

end
