# it's fine to keep all avatars in one folder - as image IDs will be the same as record IDs in "avatars" table
# (hence will be unique, no matter what kind of owner -- person/project/institution -- we have)

# DECLARING WHAT "LARGE" AVATAR IS
LARGE_SIZE = "1000x1000"


class Avatar < ActiveRecord::Base
  
  acts_as_fleximage do
    image_directory Seek::Config.avatar_filestore_path
    use_creation_date_based_directories false
    image_storage_format      :jpg
    output_image_jpg_quality  85
    require_image             true
    missing_image_message     'is required'
    invalid_image_message     'was not a readable image'
  end
  acts_as_fleximage_extension

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

  def public_asset_url size=""

    size = "#{size}x#{size}" if size.kind_of?(Numeric)

    size = filter_size(size)
    resize_image(size)

    public_avatars_dir = File.join(Rails.configuration.assets.prefix,"avatar-images")

    assets_dir = File.join(Rails.root,"public",public_avatars_dir)
    unless File.exists?(assets_dir)
      FileUtils.mkdir_p assets_dir
    end

    avatar_filename = "#{self.id}-#{size}.#{self.class.image_storage_format}"
    filepath = File.join(assets_dir,avatar_filename)
    unless File.exists?(filepath)
      FileUtils.copy(full_cache_path(size),filepath)
    end
    File.join(public_avatars_dir,avatar_filename)
  end
  
end
