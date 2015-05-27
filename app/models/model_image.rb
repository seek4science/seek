class ModelImage < ActiveRecord::Base
  DEFAULT_SIZE = '200x200'
  LARGE_SIZE = '1000x1000'
  belongs_to :model

  acts_as_fleximage do
    image_directory Seek::Config.model_image_filestore_path
    use_creation_date_based_directories false
    image_storage_format :png
    require_image true
    missing_image_message 'is required'
    invalid_image_message 'was not a readable image'
  end
  acts_as_fleximage_extension

  validates_presence_of :model

  #FIXME: to make it look like a content blob, migration needs creating
  alias_method :filepath, :file_path

  def select!
    unless selected?
      model.update_attribute :model_image_id, id
      return true
    else
      return false
    end
  end

  def selected?
    model.model_image_id && model.model_image_id.to_i == id.to_i
  end
end
