require 'test_helper'

class AdminHelperTest < ActionView::TestCase
  test 'git helper' do
    refute git_link_tag.blank?
  end
end
