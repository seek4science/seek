# it's fine to keep all avatars in one folder - as image IDs will be the same as record IDs in "avatars" table
# (hence will be unique, no matter what kind of owner -- person/project/institution -- we have)

# DECLARING WHAT "LARGE" AVATAR IS
LARGE_SIZE = '500'

class Avatar < ActiveRecord::Base
  acts_as_fleximage do
    image_directory Seek::Config.avatar_filestore_path
    use_creation_date_based_directories false
    image_storage_format      :jpg
    output_image_jpg_quality  100
    require_image             true
    missing_image_message     'is required'
    invalid_image_message     'was not a readable image'
  end
  acts_as_fleximage_extension

  validates_presence_of :owner

  belongs_to :owner,
             polymorphic: true

  has_many :people,
           foreign_key: :avatar_id,
           dependent: :nullify

  has_many :projects,
           foreign_key: :avatar_id,
           dependent: :nullify

  has_many :institutions,
           foreign_key: :avatar_id,
           dependent: :nullify

  has_many :programmes,
           foreign_key: :avatar_id,
           dependent: :nullify

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

  # provides a url to the avatar to be served from public/assets/ - resizing and copying the avatar across if necessary
  def public_asset_url(size = nil)
    size ||= 200

    if size == 'large'
      size = LARGE_SIZE
    end
    size = "#{size}x#{size}" if size.is_a?(Numeric)

    size = filter_size(size)
    resize_image(size)

    public_avatars_path = File.join(Rails.configuration.assets.prefix, 'avatar-images')
    public_avatar_dir = File.join(Rails.root, 'public', public_avatars_path)

    unless File.exist?(public_avatar_dir)
      FileUtils.mkdir_p public_avatar_dir
    end

    avatar_filename = "#{id}-#{size}.#{self.class.image_storage_format}"
    avatar_public_file_path = File.join(public_avatar_dir, avatar_filename)
    unless File.exist?(avatar_public_file_path)
      FileUtils.copy(full_cache_path(size), avatar_public_file_path)
    end

    File.join(public_avatars_path, avatar_filename)
  end
end
