require 'test_helper'

class AdminAnnotationsTest < ActionController::TestCase

  include AuthenticatedTestHelper

  tests AdminController

  test 'editing tags visible to admin' do
    login_as(:quentin)
    get :tags
    assert_response :success

    p = FactoryBot.create :person
    sop = FactoryBot.create :sop, policy: FactoryBot.create(:all_sysmo_viewable_policy)
    fish = FactoryBot.create :tag, annotatable: sop, source: p, value: 'fish'
    get :edit_tag, params: { id: fish.value.id }
    assert_response :success
  end

  test 'edit tag' do
    login_as(:quentin)
    p = FactoryBot.create :person
    sop = FactoryBot.create :sop, policy: FactoryBot.create(:all_sysmo_viewable_policy)
    fish = FactoryBot.create :tag, annotatable: sop, source: p, value: 'fish'
    assert_equal ['fish'], sop.annotations.select { |a| a.source == p }.collect { |a| a.value.text }

    golf = FactoryBot.create :tag, annotatable: sop, source: p, value: 'golf'
    post :edit_tag, params: { id: fish.value.id, tag_list: [golf.value.text, 'microbiology', 'spanish'] }
    assert_redirected_to action: :tags

    sop.reload
    assert_equal %w[golf microbiology spanish], sop.annotations.collect { |a| a.value.text }.uniq.sort
  end

  test 'edit tag to itself' do
    login_as(:quentin)
    p = FactoryBot.create :person
    sop = FactoryBot.create :sop, policy: FactoryBot.create(:all_sysmo_viewable_policy)
    fish = FactoryBot.create :tag, annotatable: sop, source: p, value: FactoryBot.create(:text_value, text: 'fish')
    assert_equal ['fish'], sop.annotations.select { |a| a.source == p }.collect { |a| a.value.text }

    post :edit_tag, params: { id: fish.value.id, tag_list: [fish.value.text] }
    assert_redirected_to action: :tags

    sop.reload
    assert_equal ['fish'], sop.annotations.select { |a| a.source == p }.collect { |a| a.value.text }
  end

  test 'editing tags blocked for non admin' do
    login_as(:aaron)
    get :tags
    assert_redirected_to :root
    assert_not_nil flash[:error]

    p = FactoryBot.create :person
    sop = FactoryBot.create :sop, policy: FactoryBot.create(:all_sysmo_viewable_policy)
    fish = FactoryBot.create :tag, annotatable: sop, source: p, value: 'fish'

    get :edit_tag, params: { id: fish.value.id }
    assert_redirected_to :root
    assert_not_nil flash[:error]

    post :edit_tag, params: { id: fish.value.id, tag_list: %w[microbiology spanish] }
    assert_redirected_to :root
    assert_not_nil flash[:error]

    post :delete_tag, params: { id: fish.value.id }
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'edit tag to multiple' do
    login_as(:quentin)
    person = FactoryBot.create :person
    person.tools = %w[linux ruby fishing]
    person.save!
    person.expertise = ['fishing']
    person.save!

    updated_at = person.updated_at

    assert_equal %w[fishing linux ruby], person.tools.uniq.sort
    assert_equal ['fishing'], person.expertise.uniq

    sleep(2) # for timestamp test

    golf = FactoryBot.create(:text_value, text: 'golf')
    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    post :edit_tag, params: { id: fishing.value.id, tag_list: [golf.text, 'microbiology', 'spanish'] }
    assert_redirected_to action: :tags
    assert_nil flash[:error]

    person = Person.find(person.id)
    expected_tools = %w[golf linux microbiology ruby spanish]
    expected_expertise = %w[golf microbiology spanish]

    person.reload
    assert_equal expected_tools, person.tools.uniq.sort
    assert_equal expected_expertise, person.expertise.uniq.sort

    assert_equal updated_at.to_s, person.updated_at.to_s,
                 "timestamps were modified for taggable and shouldn't have been"

    assert person.annotations_with_attribute('expertise').select { |a| a.value.text == 'fishing' }.blank?
  end

  test 'edit tag includes orginal' do
    login_as(:quentin)
    person = FactoryBot.create :person
    person.tools = %w[linux ruby fishing]
    person.save!
    person.expertise = ['fishing']
    person.save!

    assert_equal %w[fishing linux ruby], person.tools.uniq.sort
    assert_equal ['fishing'], person.expertise.uniq

    golf = FactoryBot.create(:tag, annotatable: person, source: User.current_user, value: 'golf')
    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_not_nil fishing

    post :edit_tag, params: { id: fishing.value.id, tag_list: [golf.value.text, 'fishing', 'spanish'] }
    assert_redirected_to action: :tags
    assert_nil flash[:error]

    person = Person.find(person.id)
    expected_tools = %w[fishing golf linux ruby spanish]
    expected_expertise = %w[fishing golf spanish]

    person.reload
    assert_equal expected_tools, person.tools.uniq.sort
    assert_equal expected_expertise, person.expertise.uniq.sort

    assert !person.annotations_with_attribute('expertise').select { |a| a.value.text == 'fishing' }.blank?
  end

  test 'edit tag to new tag' do
    login_as(:quentin)
    person = FactoryBot.create :person
    person.tools = %w[linux ruby fishing]
    person.save!
    person.expertise = ['fishing']
    person.save!

    assert_equal %w[fishing linux ruby], person.tools.uniq.sort
    assert_equal ['fishing'], person.expertise.uniq

    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_not_nil fishing

    assert person.annotations_with_attribute('expertise').select { |a| a.value.text == 'sparrow' }.blank?

    post :edit_tag, params: { id: fishing.value.id, tag_list: ['sparrow'] }
    assert_redirected_to action: :tags
    assert_nil flash[:error]

    person = Person.find(person.id)
    expected_tools = %w[linux ruby sparrow]
    expected_expertise = ['sparrow']

    person.reload
    assert_equal expected_tools, person.tools.uniq.sort
    assert_equal expected_expertise, person.expertise.uniq
  end

  test 'edit tag to blank' do
    login_as(:quentin)
    person = FactoryBot.create :person
    person.tools = %w[linux ruby fishing]
    person.save!
    person.expertise = ['fishing']
    person.save!

    assert_equal %w[fishing linux ruby], person.tools.uniq.sort
    assert_equal ['fishing'], person.expertise.uniq

    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_not_nil fishing

    post :edit_tag, params: { id: fishing.value.id, tag_list: [''] }
    assert_response :not_acceptable
    refute_nil flash[:error]

    person = Person.find(person.id)
    expected_tools = %w[fishing linux ruby]
    expected_expertise = ['fishing']

    person.reload
    assert_equal expected_tools, person.tools.sort
    assert_equal expected_expertise, person.expertise
  end

  test 'edit tag to existing tag' do
    login_as(:quentin)
    person = FactoryBot.create :person
    person.tools = %w[linux ruby fishing]
    person.save!
    person.expertise = ['fishing']
    person.save!

    assert_equal %w[fishing linux ruby], person.tools.uniq.sort
    assert_equal ['fishing'], person.expertise.uniq

    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_not_nil fishing

    golf = FactoryBot.create(:tag, annotatable: person, source: users(:quentin), value: 'golf')
    post :edit_tag, params: { id: fishing.value.id, tag_list: [golf.value.text] }
    assert_redirected_to action: :tags
    assert_nil flash[:error]

    person = Person.find(person.id)
    expected_tools = %w[golf linux ruby]
    expected_expertise = ['golf']

    person.reload
    assert_equal expected_tools, person.tools.uniq.sort
    assert_equal expected_expertise, person.expertise.uniq
  end

  test 'delete_tag' do
    login_as(:quentin)

    person = FactoryBot.create :person
    person.tools = ['fishing']
    person.save!
    person.expertise = ['fishing']
    person.save!

    assert_equal ['fishing'], person.tools.uniq
    assert_equal ['fishing'], person.expertise.uniq

    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_not_nil fishing

    # must be a post
    get :delete_tag, params: { id: fishing.value.id }
    assert_redirected_to action: :tags
    assert_not_nil flash[:error]

    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_not_nil fishing

    post :delete_tag, params: { id: fishing.value.id }
    assert_redirected_to action: :tags
    assert_nil flash[:error]

    fishing = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'fishing' }
    assert_nil fishing

    person = Person.find(person.id)
    assert_equal [], person.tools
    assert_equal [], person.expertise
  end

  test 'edit tag to different case' do
    login_as(FactoryBot.create(:admin))
    person = FactoryBot.create :person
    person.tools = ['network analysis']
    person.save!
    person.expertise = ['network analysis']
    person.save!

    assert_equal ['network analysis'], person.tools
    assert_equal ['network analysis'], person.expertise

    tag = person.annotations_with_attribute('expertise').find { |a| a.value.text == 'network analysis' }
    post :edit_tag, params: { id: tag.value.id, tag_list: ['Network Analysis'] }
    assert_redirected_to action: :tags
    assert_nil flash[:error]

    person = Person.find(person.id)
    expected_tools = ['Network Analysis']
    expected_expertise = ['Network Analysis']

    person.reload
    assert_equal expected_tools, person.tools.uniq.sort
    assert_equal expected_expertise, person.expertise.uniq.sort

    assert person.annotations_with_attribute('expertise').select { |a| a.value.text == 'network analysis' }.blank?
  end
end
