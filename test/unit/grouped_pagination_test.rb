# encoding: utf-8
require 'test_helper'

class GroupedPaginationTest < ActiveSupport::TestCase

  test 'first_letter' do
    p = Factory :person, last_name: 'Aardvark', first_name: 'Fred'
    assert_not_nil p.first_letter
    assert_equal 'A', p.first_letter
  end

  test 'pages_accessor' do
    pages = Person.pages
    assert pages.length > 1
    ('A'..'Z').to_a.each { |letter| assert pages.include?(letter) }
  end

  test 'first_letter_ignore_space' do
    inv = Factory :investigation, title: ' Inv'
    assert_equal 'I', inv.first_letter
  end

  test 'latest_limit' do
    assert_equal Seek::Config.limit_latest, Person.page_limit
    assert_equal Seek::Config.limit_latest, Project.page_limit
    assert_equal Seek::Config.limit_latest, Institution.page_limit
    assert_equal Seek::Config.limit_latest, Investigation.page_limit
    assert_equal Seek::Config.limit_latest, Study.page_limit
    assert_equal Seek::Config.limit_latest, Assay.page_limit
    assert_equal Seek::Config.limit_latest, DataFile.page_limit
    assert_equal Seek::Config.limit_latest, Model.page_limit
    assert_equal Seek::Config.limit_latest, Sop.page_limit
    assert_equal Seek::Config.limit_latest, Publication.page_limit
    assert_equal Seek::Config.limit_latest, Event.page_limit
    assert_equal Seek::Config.limit_latest, Strain.page_limit
  end

  test 'paginate_no_options' do
    Factory :person, last_name: 'Aardvark', first_name: 'Fred'
    @people = Person.paginate default_page: 'first'
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
    Factory :person, last_name: 'Bobbins', first_name: 'Fred'
    Factory :person, last_name: 'Brown', first_name: 'Fred'
    @people = Person.paginate page: 'B'
    assert_equal(('A'..'Z').to_a, @people.pages)
    assert @people.size > 0
    assert_equal 'B', @people.page
    assert_equal @people.size, @people.page_totals['B']
    @people.each do |p|
      assert_equal 'B', p.first_letter
    end
  end

  test 'sql_injection' do
    @people = Person.paginate page: "A or first_letter='B'"
    assert_equal 0, @people.size
    assert_equal(('A'..'Z').to_a, @people.pages)
    assert_equal "A or first_letter='B'", @people.page
  end

  test 'handle_oslash' do
    p = Person.new(last_name: 'Øyvind', email: 'sdfkjhsdfkjhsdf@email.com')
    assert p.save
    assert_equal 'O', p.first_letter
  end

  test 'handle_umlaut' do
    p = Person.new(last_name: 'Ümlaut', email: 'sdfkjhsdfkjhsdf@email.com')
    assert p.save
    assert_equal 'U', p.first_letter
  end

  test 'handle_accent' do
    p = Person.new(last_name: 'Ýiggle', email: 'sdfkjhsdfkjhsdf@email.com')
    assert p.save
    assert_equal 'Y', p.first_letter
  end

  test 'extra_conditions_as_array' do
    Factory :person, last_name: 'Aardvark', first_name: 'Fred'
    @people = Person.paginate page: 'A', conditions: ['last_name = ?', 'Aardvark']
    assert_equal 1, @people.size
    assert(@people.page_totals.select do |k, v|
      k != 'A' && v > 0
    end.empty?, 'All of the page totals should be 0')

    @people = Person.paginate page: 'B', conditions: ['last_name = ?', 'Aardvark']
    assert_equal 0, @people.size
    assert_equal 1, @people.page_totals['A']
  end

  # should jump to the first page that has content if :page=> isn't defined. Will use first page if no content is available
  test 'jump_to_first_page_with_content' do
    Factory :person, last_name: 'Bobbins', first_name: 'Fred'
    Factory :person, last_name: 'Davis', first_name: 'Fred'
    # delete those with A
    Person.where(['first_letter = ?', 'A']).each(&:delete)
    @people = Person.paginate default_page: 'first'
    assert @people.size > 0
    assert_equal 'B', @people.page

    @people = Person.paginate page: 'A'
    assert_equal 0, @people.size
    assert_equal 'A', @people.page

    # delete every person, and check it still returns the first page with empty content
    Person.all.each(&:delete)
    @people = Person.paginate default_page: 'first'
    assert_equal 0, @people.size
    assert_equal 'A', @people.page
  end

  test 'default_page_accessor' do
    thing = Class.new(ActiveRecord::Base) do
      include Seek::GroupedPagination
      grouped_pagination default_page: 'fish'
    end

    assert thing.default_page == 'fish'
  end

  test 'extra_condition_as_array_direct' do
    Factory :person, last_name: 'Aardvark', first_name: 'Fred'
    @people = Person.paginate page: 'A', conditions: ["last_name = 'Aardvark'"]
    assert_equal 1, @people.size
    assert(@people.page_totals.select do |k, v|
      k != 'A' && v > 0
    end.empty?, 'All of the page totals should be 0')

    @people = Person.paginate page: 'B', conditions: ["last_name = 'Aardvark'"]
    assert_equal 0, @people.size
    assert_equal 1, @people.page_totals['A']
  end

  test 'extra_condition_as_string' do
    Factory :person, last_name: 'Aardvark', first_name: 'Fred'
    @people = Person.paginate page: 'A', conditions: "last_name = 'Aardvark'"
    assert_equal 1, @people.size
    assert(@people.page_totals.select do |k, v|
      k != 'A' && v > 0
    end.empty?, 'All of the page totals should be 0')

    @people = Person.paginate page: 'B', conditions: "last_name = 'Aardvark'"
    assert_equal 0, @people.size
    assert_equal 1, @people.page_totals['A']
  end

  test 'condition_as_hash' do
    Factory :person, last_name: 'Aardvark', first_name: 'Fred'
    @people = Person.paginate page: 'A', conditions: { last_name: 'Aardvark' }
    assert_equal 1, @people.size
    assert(@people.page_totals.select do |k, v|
      k != 'A' && v > 0
    end.empty?, 'All of the page totals should be 0')

    @people = Person.paginate page: 'B', conditions: { last_name: 'Aardvark' }
    assert_equal 0, @people.size
    assert_equal 1, @people.page_totals['A']
  end

  test 'order_by' do
    p1 = Factory :person, last_name: 'Aardvark', first_name: 'Fred'
    p2 = Factory :person, last_name: 'Azbo', first_name: 'John'
    @people = Person.paginate page: 'A', order: 'name_asc'
    assert @people.size > 0
    assert_equal 'A', @people.page
    assert_equal p1, @people.first

    @people = Person.paginate page: 'A', order: 'name_desc'
    assert @people.size > 0
    assert_equal 'A', @people.page
    assert_equal p2, @people.first
  end

  test 'show_all' do
    Factory :person, last_name: 'Aardvark', first_name: 'Fred'
    Factory :person, last_name: 'Jones', first_name: 'Fred'
    @people = Person.paginate page: 'all'
    assert_equal Person.all.size, @people.size
  end

  test 'post_fetch_pagination' do
    user = Factory :user
    Factory :sop, contributor: user.person
    Factory :sop, contributor: user.person
    sops = Sop.all
    assert !sops.empty?
    sops.each { |s| User.current_user = s.contributor; s.save if s.valid? } # Set first letters
    refute_empty Sop.paginate_after_fetch(sops) # Check there's something on the first page
  end

  test 'pagination for default page using rails-setting plugin' do
    @people = Person.paginate
    assert_equal @people.page, Seek::Config.default_page('people')
    @projects = Project.paginate
    assert_equal @projects.page, Seek::Config.default_page('projects')
    @institutions = Institution.paginate
    assert_equal @institutions.page, Seek::Config.default_pages[:institutions]
    @investigations = Investigation.paginate
    assert_equal @investigations.page, Seek::Config.default_pages[:investigations]
    @studies = Study.paginate
    assert_equal @studies.page, Seek::Config.default_pages[:studies]
    @assays = Assay.paginate
    assert_equal @assays.page, Seek::Config.default_pages[:assays]
    @data_files = DataFile.paginate
    assert_equal @data_files.page, Seek::Config.default_pages[:data_files]
    @models = Model.paginate
    assert_equal @models.page, Seek::Config.default_page('models')
    @sops = Sop.paginate
    assert_equal @sops.page, Seek::Config.default_pages[:sops]
    @publications = Publication.paginate
    assert_equal @publications.page, Seek::Config.default_pages[:publications]
    @events = Event.paginate
    assert_equal @events.page, Seek::Config.default_pages[:events]
  end

  test 'order by updated_at for -latest- pagination for all item types' do
    item_types = [:person, :project, :institution, :investigation, :study, :assay, :data_file, :model, :sop, :presentation, :publication, :event, :strain]
    item_types.each do |type|
      item1 = Factory(type, updated_at: 2.second.ago)
      item2 = Factory(type, updated_at: 1.second.ago)

      klass = type.to_s.camelize.constantize
      latest_items = klass.paginate_after_fetch(klass.all, order: 'updated_at_desc')
      assert latest_items.index { |i| i.id == item2.id } < latest_items.index { |i| i.id == item1.id }, "#{type} out of order when explicit ordering"

      latest_items = klass.paginate_after_fetch(klass.all, page: 'top')
      assert latest_items.index { |i| i.id == item2.id } < latest_items.index { |i| i.id == item1.id }, "#{type} out of order when implicit ordering"
    end
  end

  test 'order by published_date for publications, for -all- and -alphabet- pagnation' do
    publication1 = Factory(:publication, title: 'AB', published_date: 2.days.ago)
    publication2 = Factory(:publication, title: 'AC', published_date: 1.days.ago)

    all_items = Publication.paginate_after_fetch(Publication.all, page: 'all')
    assert all_items.index(publication2) < all_items.index(publication1)

    pageA_items = Publication.paginate_after_fetch(Publication.all, page: 'A')
    assert pageA_items.index(publication2) < pageA_items.index(publication1)
  end

  test 'order by start_date for events, for -all- and -alphabet- pagnation' do
    event1 = Factory(:event, title: 'AB', start_date: 2.days.ago)
    event2 = Factory(:event, title: 'AC', start_date: 1.days.ago)

    all_items = Event.paginate_after_fetch(Event.all, page: 'all')
    assert all_items.index(event2) < all_items.index(event1)

    pageA_items = Event.paginate_after_fetch(Event.all, page: 'A')
    assert pageA_items.index(event2) < pageA_items.index(event1)
  end

  test 'order by title for projects and institutions, for -all- and -alphabet- pagnation' do
    yellow_pages = [:project, :institution]
    yellow_pages.each do |type|
      item1 = Factory(type, title: 'AB', updated_at: 2.days.ago)
      item2 = Factory(type, title: 'AC', updated_at: 1.days.ago)

      klass = type.to_s.camelize.constantize
      all_items = klass.paginate_after_fetch(klass.all, page: 'all')
      assert all_items.index(item1) < all_items.index(item2)

      pageA_items = klass.paginate_after_fetch(klass.all, page: 'A')
      assert pageA_items.index(item1) < pageA_items.index(item2)
    end
  end

  test 'order by title for the rest of item types,  for -all- and -alphabet- pagnation' do
    item_types = [:investigation, :study, :assay, :data_file, :model, :sop, :presentation, :strain]
    item_types.each do |type|
      item1 = Factory(type, title: 'AB', updated_at: 2.days.ago)
      item2 = Factory(type, title: 'AC', updated_at: 1.days.ago)

      klass = type.to_s.camelize.constantize
      all_items = klass.paginate_after_fetch(klass.all, page: 'all')
      assert all_items.index(item1) < all_items.index(item2)

      pageA_items = klass.paginate_after_fetch(klass.all, page: 'A')
      assert pageA_items.index(item1) < pageA_items.index(item2)
    end
  end

  test 'maintains page totals after paging' do
    item1 = Factory(:sop, title: 'AAA', updated_at: 2.days.ago)
    item2 = Factory(:sop, title: 'BBB', updated_at: 1.days.ago)
    item3 = Factory(:sop, title: 'BBC', updated_at: 1.days.ago)
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
