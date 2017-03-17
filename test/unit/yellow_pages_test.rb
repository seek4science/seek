require 'test_helper'

# Tests specific to yellow pages assets in general
class UserYellowPagesTest < ActiveSupport::TestCase
  test 'user_creatable' do
    assert !Person.user_creatable?, 'Profiles should not be user creatable'
    assert !Project.user_creatable?, 'Projects should not be user creatable'
    assert !Institution.user_creatable?, 'Institutions should not be user creatable'
  end

  test 'are yellow pages' do
    assert Person.is_yellow_pages?
    assert Project.is_yellow_pages?
    assert Institution.is_yellow_pages?
  end
end
