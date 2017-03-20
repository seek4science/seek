require 'test_helper'

class ImageFileDictionaryTest < ActiveSupport::TestCase
  test 'singleton' do
    dic = Seek::ImageFileDictionary.instance
    assert dic.is_a?(Seek::ImageFileDictionary)

    dic2 = Seek::ImageFileDictionary.instance
    assert_same dic, dic2

    assert_raise NoMethodError do
      Seek::ImageFileDictionary.new
    end
  end

  test 'image_filename_for_key' do
    assert_equal 'crystal_project/16x16/actions/1uparrow.png', Seek::ImageFileDictionary.instance.image_filename_for_key(:arrow_up)
    assert_equal 'crystal_project/16x16/actions/1uparrow.png', Seek::ImageFileDictionary.instance.image_filename_for_key('arrow_up')
    assert_nil Seek::ImageFileDictionary.instance.image_filename_for_key('keythatwill_never_exist')
  end

  test 'images exist' do
    dic = Seek::ImageFileDictionary.instance
    fails = []
    dic.image_files.each do |file_path|
      fails << file_path unless File.exist?(File.join(Rails.root, 'app', 'assets', 'images', file_path))
    end

    assert_empty fails, "images found in dictionary that don't exist in app/assets/images"
  end
end
