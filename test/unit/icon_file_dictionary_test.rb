require 'test_helper'

class IconFileDictionaryTest < ActiveSupport::TestCase

  test "singleton" do
    dic = Seek::IconFileDictionary.instance
    assert dic.is_a?(Seek::IconFileDictionary)

    dic2 = Seek::IconFileDictionary.instance
    assert_same dic,dic2

    assert_raise NoMethodError do
      Seek::IconFileDictionary.new
    end
  end

  test "icon_filename_for_key" do
    assert_equal "famfamfam_silk/arrow_up.png",Seek::IconFileDictionary.instance.icon_filename_for_key(:arrow_up)
    assert_equal "famfamfam_silk/arrow_up.png",Seek::IconFileDictionary.instance.icon_filename_for_key("arrow_up")
    assert_nil Seek::IconFileDictionary.instance.icon_filename_for_key("keythatwill_never_exist")
  end


end