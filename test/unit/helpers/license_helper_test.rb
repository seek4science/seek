# frozen_string_literal: true

require 'test_helper'

class LicenseHelperTest < ActionView::TestCase

  test 'prompt for license' do

    person = Factory(:person)
    someone_else = Factory(:person)

    User.with_current_user(person.user) do
      sop = Factory(:sop, license: 'Apache-2.0', contributor: person)
      assert_nil prompt_for_license(sop, sop.latest_version)

      sop = Factory(:sop, license: nil, contributor: person)
      refute_nil text = prompt_for_license(sop, sop.latest_version)
      assert text =~ /Click here to choose a license/i

      sop = Factory(:sop, license: 'notspecified', contributor: person)
      refute_nil text = prompt_for_license(sop, sop.latest_version)
      assert text =~ /Click here to choose a license/i

      # not the owner
      sop = Factory(:sop, license: nil, contributor: someone_else)
      assert_nil prompt_for_license(sop, sop.latest_version)

      sop = Factory(:sop, license: 'notspecified', contributor: someone_else)
      assert_nil prompt_for_license(sop, sop.latest_version)
    end

  end

end