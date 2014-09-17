require 'test_helper'

class ImageFileDictionaryTest < ActiveSupport::TestCase

  test "singleton" do
    dic = Seek::ImageFileDictionary.instance
    assert dic.is_a?(Seek::ImageFileDictionary)

    dic2 = Seek::ImageFileDictionary.instance
    assert_same dic,dic2

    assert_raise NoMethodError do
      Seek::ImageFileDictionary.new
    end
  end

  test "image_filename_for_key" do
    assert_equal "famfamfam_silk/arrow_up.png",Seek::ImageFileDictionary.instance.image_filename_for_key(:arrow_up)
    assert_equal "famfamfam_silk/arrow_up.png",Seek::ImageFileDictionary.instance.image_filename_for_key("arrow_up")
    assert_nil Seek::ImageFileDictionary.instance.image_filename_for_key("keythatwill_never_exist")
  end


end