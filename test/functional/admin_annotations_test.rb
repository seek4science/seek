require 'test_helper'

class AdminAnnotationsTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  tests AdminController

  test 'editing tags visible to admin' do
    login_as(:quentin)
    get :tags
    assert_response :success

    p = Factory :person
    sop = Factory :sop, policy: Factory(:all_sysmo_viewable_policy)
    fish = Factory :tag, annotatable: sop, source: p, value: 'fish'
    get :edit_tag, id: fish.value.id
    assert_response :success
  end

  test 'edit tag' do
    login_as(:quentin)
    p = Factory :person
    sop = Factory :sop, policy: Factory(:all_sysmo_viewable_policy)
    fish = Factory :tag, annotatable: sop, source: p, value: 'fish'
    assert_equal ['fish'], sop.annotations.select { |a| a.source == p }.collect { |a| a.value.text }

    golf = Factory :tag, annotatable: sop, source: p, value: 'golf'
    post :edit_tag, id: fish.value.id, tag_list: "#{golf.value.text}, microbiology, spanish"
    assert_redirected_to action: :tags

    sop.reload
    assert_equal %w(golf microbiology spanish), sop.annotations.collect { |a| a.value.text }.uniq.sort
  end

  test 'edit tag to itself' do
    login_as(:quentin)
    p = Factory :person
    sop = Factory :sop, policy: Factory(:all_sysmo_viewable_policy)
    fish = Factory :tag, annotatable: sop, source: p, value: Factory(:text_value, text: 'fish')
    assert_equal ['fish'], sop.annotations.select { |a| a.source == p }.collect { |a| a.value.text }

    post :edit_tag, id: fish.value.id, tag_list: fish.value.text
    assert_redirected_to action: :tags

    sop.reload
    assert_equal ['fish'], sop.annotations.select { |a| a.source == p }.collect { |a| a.value.text }
  end

  test 'editing tags blocked for non admin' do
    login_as(:aaron)
    get :tags
    assert_redirected_to :root
    assert_not_nil flash[:error]

    p = Factory :person
    sop = Factory :sop, policy: Factory(:all_sysmo_viewable_policy)
    fish = Factory :tag, annotatable: sop, source: p, value: 'fish'

    get :edit_tag, id: fish.value.id
    assert_redirected_to :root
    assert_not_nil flash[:error]

    post :edit_tag, id: fish.value.id, tag_list: 'microbiology, spanish'
    assert_redirected_to :root
    assert_not_nil flash[:error]

    post :delete_tag, id: fish.value.id
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'edit tag to multiple' do
    login_as(:quentin)
    person = Factory :person
    person.tools = %w(linux ruby fishing)
    person.expertise = ['fishing']
    person.save!

    updated_at = person.updated_at

    assert_equal %w(fishing linux ruby), person.tools.collect(&:text).uniq.sort
    assert_equal ['fishing'], person.expertise.collect(&:text).uniq

    sleep(2) # for timestamp test

    golf = Factory(:text_value, text: 'golf')
    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    post :edit_tag, id: fishing.value.id, tag_list: "#{golf.text}, microbiology, spanish"
    assert_redirected_to action: :tags
    assert_nil flash[:error]

    person = Person.find(person.id)
    expected_tools = %w(golf linux microbiology ruby spanish)
    expected_expertise = %w(golf microbiology spanish)

    person.reload
    assert_equal expected_tools, person.tools.collect(&:text).uniq.sort
    assert_equal expected_expertise, person.expertise.collect(&:text).uniq.sort

    assert_equal updated_at.to_s, person.updated_at.to_s, "timestamps were modified for taggable and shouldn't have been"

    assert person.annotations_with_attribute('expertise').select { |a| a.value.text == 'fishing' }.blank?
  end

  test 'edit tag includes orginal' do
    login_as(:quentin)
    person = Factory :person
    person.tools = %w(linux ruby fishing)
    person.expertise = ['fishing']
    person.save!

    assert_equal %w(fishing linux ruby), person.tools.collect(&:text).uniq.sort
    assert_equal ['fishing'], person.expertise.collect(&:text).uniq

    golf = Factory(:tag, annotatable: person, source: User.current_user, value: 'golf')
    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_not_nil fishing

    post :edit_tag, id: fishing.value.id, tag_list: "#{golf.value.text}, fishing, spanish"
    assert_redirected_to action: :tags
    assert_nil flash[:error]

    person = Person.find(person.id)
    expected_tools = %w(fishing golf linux ruby spanish)
    expected_expertise = %w(fishing golf spanish)

    person.reload
    assert_equal expected_tools, person.tools.collect(&:text).uniq.sort
    assert_equal expected_expertise, person.expertise.collect(&:text).uniq.sort

    assert !person.annotations_with_attribute('expertise').select { |a| a.value.text == 'fishing' }.blank?
  end

  test 'edit tag to new tag' do
    login_as(:quentin)
    person = Factory :person
    person.tools = %w(linux ruby fishing)
    person.expertise = ['fishing']
    person.save!

    assert_equal %w(fishing linux ruby), person.tools.collect(&:text).uniq.sort
    assert_equal ['fishing'], person.expertise.collect(&:text).uniq

    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_not_nil fishing

    assert person.annotations_with_attribute('expertise').select { |a| a.value.text == 'sparrow' }.blank?

    post :edit_tag, id: fishing.value.id, tag_list: 'sparrow'
    assert_redirected_to action: :tags
    assert_nil flash[:error]

    person = Person.find(person.id)
    expected_tools = %w(linux ruby sparrow)
    expected_expertise = ['sparrow']

    person.reload
    assert_equal expected_tools, person.tools.collect(&:text).uniq.sort
    assert_equal expected_expertise, person.expertise.collect(&:text).uniq
  end

  test 'edit tag to blank' do
    login_as(:quentin)
    person = Factory :person
    person.tools = %w(linux ruby fishing)
    person.expertise = ['fishing']
    person.save!

    assert_equal %w(fishing linux ruby), person.tools.collect(&:text).uniq.sort
    assert_equal ['fishing'], person.expertise.collect(&:text).uniq

    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_not_nil fishing

    post :edit_tag, id: fishing.value.id, tag_list: ''
    assert_redirected_to action: :tags
    assert_nil flash[:error]

    person = Person.find(person.id)
    expected_tools = %w(linux ruby)
    expected_expertise = []

    person.reload
    assert_equal expected_tools, person.tools.collect(&:text).uniq.sort
    assert_equal expected_expertise, person.expertise.collect(&:text)
  end

  test 'edit tag to existing tag' do
    login_as(:quentin)
    person = Factory :person
    person.tools = %w(linux ruby fishing)
    person.expertise = ['fishing']
    person.save!

    assert_equal %w(fishing linux ruby), person.tools.collect(&:text).uniq.sort
    assert_equal ['fishing'], person.expertise.collect(&:text).uniq

    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_not_nil fishing

    golf = Factory(:tag, annotatable: person, source: users(:quentin), value: 'golf')
    post :edit_tag, id: fishing.value.id, tag_list: golf.value.text
    assert_redirected_to action: :tags
    assert_nil flash[:error]

    person = Person.find(person.id)
    expected_tools = %w(golf linux ruby)
    expected_expertise = ['golf']

    person.reload
    assert_equal expected_tools, person.tools.collect(&:text).uniq.sort
    assert_equal expected_expertise, person.expertise.collect(&:text).uniq
  end

  test 'delete_tag' do
    login_as(:quentin)

    person = Factory :person
    person.tools = ['fishing']
    person.expertise = ['fishing']
    person.save!

    assert_equal ['fishing'], person.tools.collect(&:text).uniq
    assert_equal ['fishing'], person.expertise.collect(&:text).uniq

    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_not_nil fishing

    # must be a post
    get :delete_tag, id: fishing.value.id
    assert_redirected_to action: :tags
    assert_not_nil flash[:error]

    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_not_nil fishing

    post :delete_tag, id: fishing.value.id
    assert_redirected_to action: :tags
    assert_nil flash[:error]

    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_nil fishing

    person = Person.find(person.id)
    assert_equal [], person.tools
    assert_equal [], person.expertise
  end
end
