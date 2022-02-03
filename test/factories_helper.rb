require_relative './password_helper.rb'

module FactoriesHelper
  include PasswordHelper

  def fixture_file_upload(path, mime_type = nil, binary = false)
    Rack::Test::UploadedFile.new(Pathname.new(File.join("#{Rails.root}/test/fixtures/files", path)), mime_type, binary)
  end
end
