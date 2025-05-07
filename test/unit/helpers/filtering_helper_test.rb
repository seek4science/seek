require 'test_helper'

class FilteringHelperTest < ActionView::TestCase

  test 'max_filters_met?' do
    with_config_value(:max_filters, 2) do
      refute max_filters_met?
      @filters={}
      refute max_filters_met?
      @filters={'contributor'=>'1'}
      refute max_filters_met?

      @filters={'contributor'=>'1', 'creator'=>'1'}
      assert max_filters_met?
      @filters={'contributor'=>['1','2']}
      assert max_filters_met?
      @filters={'contributor'=>['1','2','3']}
      assert max_filters_met?

      # logged in but not fully registered
      user = FactoryBot.create(:brand_new_user)
      assert_nil user.person
      User.with_current_user(user) do
        assert max_filters_met?
      end

      person = FactoryBot.create(:person)
      User.with_current_user(person.user) do
        refute max_filters_met?
      end
    end
  end


end