Technoweenie::AttachmentFu::InstanceMethods.module_eval do


  @@image_mime_types ||= {".gif" => "image/gif", ".ief" => "image/ief", ".jpe" => "image/jpeg", ".jpeg" => "image/jpeg", ".jpg" => "image/jpeg", ".pbm" => "image/x-portable-bitmap", ".pgm" => "image/x-portable-graymap", ".png" => "image/png", ".pnm" => "image/x-portable-anymap", ".ppm" => "image/x-portable-pixmap", ".ras" => "image/cmu-raster", ".rgb" => "image/x-rgb", ".tif" => "image/tiff", ".tiff" => "image/tiff", ".xbm" => "image/x-xbitmap", ".xpm" => "image/x-xpixmap", ".xwd" => "image/x-xwindowdump"}.freeze


  def image?
    self.class.image?(content_type) || @@image_mime_types.values.include?(content_type)
  end

  def uploaded_data_with_extension=(file_data)
    unless self.class == ForumAttachment #FIXME: This check is an indication that this extension is applied too broadly, I think.
      upload_results = self.uploaded_data_without_extension=file_data
      self.original_filename = file_data.original_filename

      uuid_to_use="#{UUIDTools::UUID.random_create.to_s}"
      self.filename= "#{uuid_to_use}.dat"

      if upload_results && file_data.content_type=="image/tiff"
        #self.filename =self.filename + ".jpg"
        self.content_type = "image/jpeg"

        @uploaded_image = Magick::Image.read(file_data.path).first
        self.temp_paths.clear

        self.temp_paths.unshift write_to_temp_file(@uploaded_image.to_blob { self.format = 'JPEG' })
      end

      return upload_result
    else
      self.uploaded_data_without_extension=(file_data)
    end
  end

  alias_method_chain :uploaded_data=, :extension

end