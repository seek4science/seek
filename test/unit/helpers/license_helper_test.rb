# frozen_string_literal: true

require 'test_helper'

class LicenseHelperTest < ActionView::TestCase

  test 'prompt for license' do

    person = FactoryBot.create(:person)
    someone_else = FactoryBot.create(:person)

    User.with_current_user(person.user) do
      sop = FactoryBot.create(:sop, license: 'Apache-2.0', contributor: person)
      assert_nil prompt_for_license(sop, sop.latest_version)

      sop = FactoryBot.create(:sop, license: nil, contributor: person)
      refute_nil text = prompt_for_license(sop, sop.latest_version)
      assert text =~ /Click here to choose a license/i

      sop = FactoryBot.create(:sop, license: 'notspecified', contributor: person)
      refute_nil text = prompt_for_license(sop, sop.latest_version)
      assert text =~ /Click here to choose a license/i

      # not the owner
      sop = FactoryBot.create(:sop, license: nil, contributor: someone_else)
      assert_nil prompt_for_license(sop, sop.latest_version)

      sop = FactoryBot.create(:sop, license: 'notspecified', contributor: someone_else)
      assert_nil prompt_for_license(sop, sop.latest_version)
    end

  end

  test 'describe license' do
    assert_equal '<a target="_blank" href="https://spdx.org/licenses/CC-BY-4.0">Creative Commons Attribution 4.0 International (CC-BY-4.0)</a>', describe_license('CC-BY-4.0')

    assert_match /<a target="_blank" href="https:\/\/choosealicense.com\/no-permission\/">No license - no permission to use unless the owner grants a licence<\/a>/, describe_license(nil)
    assert_match /<a target="_blank" href="https:\/\/choosealicense.com\/no-permission\/">No license - no permission to use unless the owner grants a licence<\/a>/, describe_license(Seek::License::NULL_LICENSE)
  end

end