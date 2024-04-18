module AttachmentFuExtensions
  def uploaded_data=(file_data)
    unless self.class == HelpAttachment || self.class == HelpImage #FIXME: This check is an indication that this extension is applied too broadly, I think.
      upload_results = super(file_data)
      self.original_filename = file_data.original_filename

      uuid_to_use=UUID.generate
      self.filename= "#{uuid_to_use}.dat"

      if upload_results && file_data.content_type=="image/tiff"
        #self.filename =self.filename + ".jpg"
        self.content_type = "image/jpeg"

        @uploaded_image = Magick::Image.read(file_data.path).first
        self.temp_paths.clear

        self.temp_paths.unshift write_to_temp_file(@uploaded_image.to_blob { self.format = 'JPEG' })
      end

      return upload_results
    else
      super(file_data)
    end
  end
end

Technoweenie::AttachmentFu::InstanceMethods.module_eval do
  prepend AttachmentFuExtensions
end
