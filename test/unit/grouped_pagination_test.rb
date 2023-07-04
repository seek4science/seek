# encoding: utf-8
require 'test_helper'

class GroupedPaginationTest < ActiveSupport::TestCase

  test 'first_letter' do
    p = FactoryBot.create :person, last_name: 'Aardvark', first_name: 'Fred'
    assert_not_nil p.first_letter
    assert_equal 'A', p.first_letter
  end

  test 'pages_accessor' do
    pages = Person.pages
    assert pages.length > 1
    ('A'..'Z').to_a.each { |letter| assert pages.include?(letter) }
  end

  test 'first_letter_ignore_space' do
    inv = FactoryBot.create :investigation, title: ' Inv'
    assert_equal 'I', inv.first_letter
  end

  test 'results_per_page_default' do
    assert_equal Seek::Config.results_per_page_default, Person.page_limit
    assert_equal Seek::Config.results_per_page_default, Investigation.page_limit
    assert_equal Seek::Config.results_per_page_default, Model.page_limit
  end

  test 'paginate_no_options' do
    FactoryBot.create :person, last_name: 'Aardvark', first_name: 'Fred'
    @people = Person.grouped_paginate default_page: 'first'
    assert_equal(('A'..'Z').to_a, @people.pages)
    assert @people.size > 0
    assert_equal 'A', @people.page
    assert_not_nil @people.page_totals
    assert_equal @people.size, @people.page_totals['A']

    @people.each do |p|
      assert_equal 'A', p.first_letter
    end
  end

  test 'paginate_by_page' do
    FactoryBot.create :person, last_name: 'Bobbins', first_name: 'Fred'
    FactoryBot.create :person, last_name: 'Brown', first_name: 'Fred'
    @people = Person.grouped_paginate page: 'B'
    assert_equal(('A'..'Z').to_a, @people.pages)
    assert @people.size > 0
    assert_equal 'B', @people.page
    assert_equal @people.size, @people.page_totals['B']
    @people.each do |p|
      assert_equal 'B', p.first_letter
    end
  end

  test 'sql_injection' do
    @people = Person.grouped_paginate page: "A or first_letter='B'"
    assert_equal 0, @people.size
    assert_equal(('A'..'Z').to_a, @people.pages)
    assert_equal "A or first_letter='B'", @people.page
  end

  test 'handle_oslash' do
    p = FactoryBot.create(:brand_new_person, last_name: 'Øyvind', email: 'sdfkjhsdfkjhsdf@email.com')
    assert_equal 'O', p.first_letter
  end

  test 'handle_umlaut' do
    p = FactoryBot.create(:brand_new_person, last_name: 'Ümlaut', email: 'sdfkjhsdfkjhsdf@email.com')
    assert_equal 'U', p.first_letter
  end

  test 'handle_accent' do
    p = FactoryBot.create(:brand_new_person, last_name: 'Ýiggle', email: 'sdfkjhsdfkjhsdf@email.com')
    assert_equal 'Y', p.first_letter
  end

  test 'extra_conditions_as_array' do
    FactoryBot.create :person, last_name: 'Aardvark', first_name: 'Fred'
    @people = Person.grouped_paginate page: 'A', conditions: ['last_name = ?', 'Aardvark']
    assert_equal 1, @people.size
    assert(@people.page_totals.select do |k, v|
      k != 'A' && v > 0
    end.empty?, 'All of the page totals should be 0')

    @people = Person.grouped_paginate page: 'B', conditions: ['last_name = ?', 'Aardvark']
    assert_equal 0, @people.size
    assert_equal 1, @people.page_totals['A']
  end

  # should jump to the first page that has content if :page=> isn't defined. Will use first page if no content is available
  test 'jump_to_first_page_with_content' do
    FactoryBot.create :person, last_name: 'Bobbins', first_name: 'Fred'
    FactoryBot.create :person, last_name: 'Davis', first_name: 'Fred'
    # delete those with A
    Person.where(['first_letter = ?', 'A']).each(&:delete)
    @people = Person.grouped_paginate default_page: 'first'
    assert @people.size > 0
    assert_equal 'B', @people.page

    @people = Person.grouped_paginate page: 'A'
    assert_equal 0, @people.size
    assert_equal 'A', @people.page

    # delete every person, and check it still returns the first page with empty content
    Person.all.each(&:delete)
    @people = Person.grouped_paginate default_page: 'first'
    assert_equal 0, @people.size
    assert_equal 'A', @people.page
  end

  test 'extra_condition_as_array_direct' do
    FactoryBot.create :person, last_name: 'Aardvark', first_name: 'Fred'
    @people = Person.grouped_paginate page: 'A', conditions: ["last_name = 'Aardvark'"]
    assert_equal 1, @people.size
    assert(@people.page_totals.select do |k, v|
      k != 'A' && v > 0
    end.empty?, 'All of the page totals should be 0')

    @people = Person.grouped_paginate page: 'B', conditions: ["last_name = 'Aardvark'"]
    assert_equal 0, @people.size
    assert_equal 1, @people.page_totals['A']
  end

  test 'extra_condition_as_string' do
    FactoryBot.create :person, last_name: 'Aardvark', first_name: 'Fred'
    @people = Person.grouped_paginate page: 'A', conditions: "last_name = 'Aardvark'"
    assert_equal 1, @people.size
    assert(@people.page_totals.select do |k, v|
      k != 'A' && v > 0
    end.empty?, 'All of the page totals should be 0')

    @people = Person.grouped_paginate page: 'B', conditions: "last_name = 'Aardvark'"
    assert_equal 0, @people.size
    assert_equal 1, @people.page_totals['A']
  end

  test 'condition_as_hash' do
    FactoryBot.create :person, last_name: 'Aardvark', first_name: 'Fred'
    @people = Person.grouped_paginate page: 'A', conditions: { last_name: 'Aardvark' }
    assert_equal 1, @people.size
    assert(@people.page_totals.select do |k, v|
      k != 'A' && v > 0
    end.empty?, 'All of the page totals should be 0')

    @people = Person.grouped_paginate page: 'B', conditions: { last_name: 'Aardvark' }
    assert_equal 0, @people.size
    assert_equal 1, @people.page_totals['A']
  end

  test 'order_by is preserved during pagination' do
    p1 = FactoryBot.create :person, last_name: 'Aardvark', first_name: 'Fred'
    p2 = FactoryBot.create :person, last_name: 'Azbo', first_name: 'John'
    @people = Person.order('last_name ASC').grouped_paginate(page: 'A')
    assert @people.size > 0
    assert_equal 'A', @people.page
    assert_equal p1, @people.first

    @people = Person.order('last_name DESC').grouped_paginate(page: 'A')
    assert @people.size > 0
    assert_equal 'A', @people.page
    assert_equal p2, @people.first
  end

  test 'show_all' do
    FactoryBot.create :person, last_name: 'Aardvark', first_name: 'Fred'
    FactoryBot.create :person, last_name: 'Jones', first_name: 'Fred'
    @people = Person.grouped_paginate page: 'all'
    assert_equal Person.all.size, @people.size
  end

  test 'post_fetch_pagination' do
    user = FactoryBot.create :user
    FactoryBot.create :sop, contributor: user.person
    FactoryBot.create :sop, contributor: user.person
    sops = Sop.all
    assert !sops.empty?
    sops.each { |s| User.current_user = s.contributor; s.save if s.valid? } # Set first letters
    refute_empty Sop.paginate_after_fetch(sops) # Check there's something on the first page
  end

  test 'maintains page totals after paging' do
    item1 = FactoryBot.create(:sop, title: 'AAA', updated_at: 2.days.ago)
    item2 = FactoryBot.create(:sop, title: 'BBB', updated_at: 1.days.ago)
    item3 = FactoryBot.create(:sop, title: 'BBC', updated_at: 1.days.ago)
    collection = [item1, item2, item3]

    paged_collection = Sop.paginate_after_fetch(collection, page: 'A')
    assert_equal 1, paged_collection.page_totals['A']
    assert_equal 2, paged_collection.page_totals['B']

    paged_collection = Sop.paginate_after_fetch(collection, page: 'B')
    assert_equal 1, paged_collection.page_totals['A']
    assert_equal 2, paged_collection.page_totals['B']
  end

  test 'ensure pagination works the same for relations and arrays' do
    check_both_pagination_methods(DataFile.all, page: 'P')
    check_both_pagination_methods(DataFile.all, page: 'top', order: 'title_asc')
    check_both_pagination_methods(DataFile.all, page: 'top', order: 'title_desc')
    check_both_pagination_methods(Publication.all)
    check_both_pagination_methods(Person.all)
    check_both_pagination_methods(Person.all, page: 'top')
    check_both_pagination_methods(Project.all)
    check_both_pagination_methods(Project.all, page: 'Z')
    check_both_pagination_methods(Investigation.all, page: 'banana')
    check_both_pagination_methods(Investigation.all, page: 'top')
  end

  private

  def check_both_pagination_methods(relation, opts = {})
    klass = relation.klass
    as_relation = klass.paginate_after_fetch(relation, opts)
    as_array = klass.paginate_after_fetch(relation.to_a, opts)

    assert_equal as_relation.map(&:id), as_array.map(&:id),
                 "Mismatch for class #{klass.name} with opts: #{opts.inspect}.\n\n"+
                     "Rel: #{as_relation.map { |x| "#{x.id} - #{x.title}" }.inspect}\n\n"+
                     "Arr: #{as_array.map { |x| "#{x.id} - #{x.title}" }.inspect}"
  end
end
