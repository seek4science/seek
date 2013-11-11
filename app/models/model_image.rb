class ModelImage < ActiveRecord::Base

  LARGE_SIZE = "1000x1000"
  belongs_to :model
  after_create :change_filename unless Rails.env=="test"

  acts_as_fleximage do
    image_directory Seek::Config.model_image_filestore_path
    use_creation_date_based_directories false
    image_storage_format :jpg
    output_image_jpg_quality 85
    require_image true
    missing_image_message 'is required'
    invalid_image_message 'was not a readable image'
  end

  validates_presence_of :model

  def original_image_format
    content_type.split("/").last
  end                                                                                                                                 #


  def self.original_path
    File.join(self.image_directory,"original")
  end

  def image_file= file
    # save_original_file
    if file.respond_to?(:content_type) && file.respond_to?(:original_filename)
      format = file.content_type.split("/").last
      FileUtils.mkdir_p(ModelImage.original_path)
      File.open(File.join(ModelImage.original_path,"#{file.original_filename}.#{format}"), 'wb') do |f|
        file.rewind
        f.write file.read
      end
    end

    super
  end

  def change_filename
    File.rename File.join(ModelImage.original_path,"#{original_filename}.#{original_image_format}"), File.join(ModelImage.original_path,"#{id}.#{original_image_format}")
  end

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
