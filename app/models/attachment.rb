class Attachment < ActiveRecord::Base

  ATTACHMENT_STORAGE_PATH = 'public/attachments_fu'

  belongs_to :attachable, :polymorphic => true

  has_attachment :storage => :file_system,
                 :path_prefix => ATTACHMENT_STORAGE_PATH,
                 :max_size => 100.gigabytes,
                 :thumbnails => { :thumb => [200, 150], :geometry => 'x50' }

  validates_as_attachment

  #include all image types,but attachment.image? with content types defined in attachment_fu,e.g. tif image not included
  def is_image?
    self.content_type.index('image')== 0
  end

  def source_uri=(uri)
    url = open(URI.parse(uri))
    (class << url; self; end;).class_eval do
      define_method(:original_filename) { base_uri.path.split('/').last }
    end

    self.uploaded_data = url
  end

  def file_exists?
    File.exist?(filepath)
  end

  def filepath
      "#{RAILS_ROOT}/public/#{public_filename}"
  end

end
