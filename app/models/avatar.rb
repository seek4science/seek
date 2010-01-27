# it's fine to keep all avatars in one folder - as image IDs will be the same as record IDs in "avatars" table
# (hence will be unique, no matter what kind of owner -- person/project/institution -- we have)
AVATAR_STORAGE_PATH = 'filestore/avatars'

# DECLARING WHAT "LARGE" AVATAR IS
LARGE_SIZE = "1000x1000"


class Avatar < ActiveRecord::Base
  
  acts_as_fleximage do
    image_directory AVATAR_STORAGE_PATH
    use_creation_date_based_directories false
    image_storage_format      :jpg
    output_image_jpg_quality  85
    require_image             true
    missing_image_message     'is required'
    invalid_image_message     'was not a readable image'
  end
  
  # UNCOMMENTING NEXT LINE CAUSES STACK OVERFLOW - NEEDS FURTHER INVESTIGATION
  #validates_associated :owner
  validates_presence_of :owner
  
  belongs_to :owner,
             :polymorphic => true
             
  has_many :people,
           :foreign_key => :avatar_id,
           :dependent => :nullify
  
  has_many :projects,
           :foreign_key => :avatar_id,
           :dependent => :nullify
           
  has_many :institutions,
           :foreign_key => :avatar_id,
           :dependent => :nullify
  
  
  def select!
    unless selected?      
      owner.update_attribute :avatar_id, id
      return true
    else
      return false
    end
  end
  
  def selected?
    owner.avatar_id && owner.avatar_id.to_i == id.to_i
  end
  
end
