require 'test_helper'

class AvatarTest < ActiveSupport::TestCase
  test 'requires owner' do
    avatar = Avatar.new(image_file: File.open("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb'))
    refute avatar.valid?
    avatar.owner = Factory :project
    assert avatar.valid?
  end

  test 'special flag to skip owner validation' do
    avatar = Avatar.new(image_file: File.open("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb'))
    refute avatar.skip_owner_validation
    refute avatar.valid?

    avatar = Avatar.new(image_file: File.open("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb'), skip_owner_validation: true)
    assert avatar.skip_owner_validation
    assert avatar.valid?
  end
end
