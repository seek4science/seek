module UploadHelper
  def fixture_file_upload(path, mime_type = nil, binary = false)
    if self.class.respond_to?(:fixture_path) && self.class.fixture_path
      path = File.join(self.class.fixture_path, path)
    end
    Rack::Test::UploadedFile.new(path, mime_type, binary)
  end
end
