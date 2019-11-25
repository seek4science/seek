require 'test_helper'

class ListSorterTest < ActiveSupport::TestCase
  test 'rules' do
    assert_equal 'last_name IS NULL, LOWER(last_name), LOWER(first_name)', Seek::ListSorter.order_for_view('Person', :index)
    assert_equal 'updated_at DESC', Seek::ListSorter.order_for_view('Sop', :index)
    assert_equal 'updated_at DESC', Seek::ListSorter.order_for_view('NewModelThatDoesntExist', :index)
    assert_equal 'updated_at DESC', Seek::ListSorter.order_for_view('NewModelThatDoesntExist', :related)
    assert_equal 'published_date DESC', Seek::ListSorter.order_for_view('Publication', :index)
    assert_equal 'updated_at DESC', Seek::ListSorter.order_for_view('Assay', :related)

    assert Seek::ListSorter::RULES.frozen?
  end

  test 'related_items' do
    p1 = Factory(:person, last_name: 'jones')
    p2 = Factory(:person, last_name: 'davis')
    p3 = Factory(:person, last_name: 'smith')
    p4 = Factory(:person, last_name: nil)

    i1 = Factory(:institution, title: 'Nottingham Uni')
    i2 = Factory(:institution, title: 'Bradford Uni')
    i3 = Factory(:institution, title: 'Yorkshire Uni')
    i4 = Factory(:institution, title: 'Manchester Uni')

    e1 = Factory(:event, start_date: 3.days.ago)
    e2 = Factory(:event, start_date: 1.day.ago)
    e3 = Factory(:event, start_date: 5.days.ago)

    s1 = Factory(:sop, title: 'sop1')
    s2 = Factory(:sop, title: 'sop2')
    s3 = Factory(:sop, title: 'sop3')

    s1.update_attribute(:updated_at, 6.days.ago)
    s2.update_attribute(:updated_at, 1.days.ago)
    s3.update_attribute(:updated_at, 3.days.ago)

    related_items_hash = {
      'Person' => { items: [p1, p2, p3, p4] },
      'Institution' => { items: [i1, i2, i3, i4] },
      'Event' => { items: [e1, e2, e3] },
      'Sop' => { items: [s1, s2, s3] }
    }

    Seek::ListSorter.related_items(related_items_hash)

    assert_equal [p2, p1, p3, p4], related_items_hash['Person'][:items]
    assert_equal [i2, i4, i1, i3], related_items_hash['Institution'][:items]
    assert_equal [e2, e1, e3], related_items_hash['Event'][:items]
    assert_equal [s2, s3, s1], related_items_hash['Sop'][:items]
  end

  test 'sort by order' do
    p1 = Factory(:person, last_name: 'jones', first_name: nil)
    p2 = Factory(:person, last_name: 'davis', first_name: nil)
    p3 = Factory(:person, last_name: 'smith', first_name: 'dave')
    p4 = Factory(:person, last_name: nil, first_name: 'bob')
    p5 = Factory(:person, last_name: 'smith', first_name: 'john')
    p6 = Factory(:person, last_name: 'davis', first_name: 'tom')
    p1.update_attribute(:updated_at, 6.days.ago)
    p2.update_attribute(:updated_at, 3.days.ago)
    p3.update_attribute(:updated_at, 1.days.ago)
    p4.update_attribute(:updated_at, 2.days.ago)
    p5.update_attribute(:updated_at, 8.days.ago)
    p6.update_attribute(:updated_at, 7.days.ago)
    people = [p1, p2, p3, p4, p5, p6]

    i1 = Factory(:institution, title: 'Nottingham Uni')
    i2 = Factory(:institution, title: 'Bradford Uni')
    i3 = Factory(:institution, title: 'Yorkshire Uni')
    i4 = Factory(:institution, title: 'Manchester Uni')
    i1.update_attribute(:updated_at, 6.days.ago)
    i2.update_attribute(:updated_at, 1.days.ago)
    i3.update_attribute(:updated_at, 3.days.ago)
    i4.update_attribute(:updated_at, 2.days.ago)
    institutions = [i1, i2, i3, i4]

    e1 = Factory(:event, start_date: 3.days.ago)
    e2 = Factory(:event, start_date: 1.day.ago)
    e3 = Factory(:event, start_date: 5.days.ago)
    e1.update_attribute(:updated_at, 1.days.ago)
    e2.update_attribute(:updated_at, 2.days.ago)
    e3.update_attribute(:updated_at, 3.days.ago)
    events = [e1, e2, e3]

    s1 = Factory(:sop, title: 'sop a')
    s2 = Factory(:sop, title: 'sop c')
    s3 = Factory(:sop, title: 'sop b')
    s1.update_attribute(:updated_at, 3.days.ago)
    s2.update_attribute(:updated_at, 2.days.ago)
    s3.update_attribute(:updated_at, 1.days.ago)
    sops = [s1, s2, s3]

    assert_equal [p6, p2, p1, p3, p5, p4], Seek::ListSorter.sort_by_order(people)
    assert_equal [p3, p4, p2, p1, p6, p5], Seek::ListSorter.sort_by_order(people, 'updated_at DESC')

    assert_equal [i2, i4, i1, i3], Seek::ListSorter.sort_by_order(institutions)
    assert_equal [i2, i4, i3, i1], Seek::ListSorter.sort_by_order(institutions, 'updated_at DESC')

    assert_equal [e2, e1, e3], Seek::ListSorter.sort_by_order(events)
    assert_equal [e1, e2, e3], Seek::ListSorter.sort_by_order(events, 'updated_at DESC')

    assert_equal [s1, s3, s2], Seek::ListSorter.sort_by_order(sops, 'LOWER(title)')
    assert_equal [s3, s2, s1], Seek::ListSorter.sort_by_order(sops)
  end

  test 'complex sorting' do
    Address = Struct.new(:country, :city)
    brisbane = Address.new('Australia', 'Brisbane')
    beijing = Address.new('China', 'Beijing')
    shanghai = Address.new('China', 'Shanghai')
    shenzhen = Address.new('China', 'Shenzhen')
    nil_city = Address.new('China', nil)
    marseille = Address.new('France', 'Marseille')
    paris = Address.new('France', 'Paris')
    unknown = Address.new('Unknown', nil)
    atlantis = Address.new(nil, 'Atlantis')
    valhalla = Address.new(nil, 'Valhalla')
    carthage = Address.new(nil, 'Carthage')
    places = [beijing, nil_city, valhalla, shanghai, paris, atlantis, brisbane, marseille, carthage, shenzhen, unknown]

    assert_equal [unknown, marseille, paris, beijing, shanghai, shenzhen, nil_city, brisbane, atlantis, carthage, valhalla], Seek::ListSorter.sort_by_order(places, 'country DESC, city ASC')
    assert_equal [brisbane, shenzhen, shanghai, beijing, nil_city, paris, marseille, unknown, valhalla, carthage, atlantis], Seek::ListSorter.sort_by_order(places, 'country ASC, city DESC')
  end

  test 'JSON API sorting' do
    assert_equal [:title_desc], Seek::ListSorter.keys_from_json_api_sort('Sop', '-title')
    assert_equal [:title_asc], Seek::ListSorter.keys_from_json_api_sort('Sop', 'title')
    assert_equal [], Seek::ListSorter.keys_from_json_api_sort('Sop', '-published_at')
    assert_equal [:created_at_asc], Seek::ListSorter.keys_from_json_api_sort('Sop', 'created_at')
    assert_equal [:created_at_asc, :title_desc, :updated_at_asc], Seek::ListSorter.keys_from_json_api_sort('Sop', 'created_at,,-title,updated_at')
    assert_equal [:created_at_asc, :updated_at_asc, :title_desc], Seek::ListSorter.keys_from_json_api_sort('Sop', 'created_at,dsgsg,updated_at,-title')
    assert_equal [:created_at_asc, :title_desc], Seek::ListSorter.keys_from_json_api_sort('Sop', 'created_at,-title,banana')
    assert_equal [:created_at_asc, :updated_at_asc], Seek::ListSorter.keys_from_json_api_sort('Sop', 'created_at,updated_at,-title;drop table users;--')
    assert_equal [:created_at_asc], Seek::ListSorter.keys_from_json_api_sort('Person', 'created_at,-title')
    assert_equal [:created_at_asc], Seek::ListSorter.keys_from_json_api_sort('Banana', 'created_at')
  end

  test 'keys from params' do
    assert_equal [:title_desc], Seek::ListSorter.keys_from_params('Sop', [:title_desc])
    assert_equal [], Seek::ListSorter.keys_from_params('Sop', [:published_at_desc])
    assert_equal [:title_asc], Seek::ListSorter.keys_from_params('Sop', ['title_asc'])
    assert_equal [:created_at_asc], Seek::ListSorter.keys_from_params('Sop', ['created_at_asc'])
    assert_equal [], Seek::ListSorter.keys_from_params('Sop', ['created_at'])
    assert_equal [:created_at_asc, :title_desc, :updated_at_asc], Seek::ListSorter.keys_from_params('Sop', ['created_at_asc', [], 'title_desc', 'updated_at_asc'])
    assert_equal [:created_at_asc, :updated_at_asc, :title_desc], Seek::ListSorter.keys_from_params('Sop', [:created_at_asc, 'updated_at_asc', 'title_desc'])
    assert_equal [:created_at_asc, :title_desc], Seek::ListSorter.keys_from_params('Sop', ['created_at_asc', nil, 'title_desc', '', 'banana'])
    assert_equal [:created_at_asc, :updated_at_asc], Seek::ListSorter.keys_from_params('Sop', ['created_at_asc', :updated_at_asc, '-title;drop table users;--'])
    assert_equal [:created_at_asc], Seek::ListSorter.keys_from_params('Person', ['created_at_asc', 'title_desc', 'junk'])
    assert_equal [:created_at_asc], Seek::ListSorter.keys_from_params('Banana', ['created_at_asc'])
    assert_equal [], Seek::ListSorter.keys_from_params('Banana', ['fred'])
  end

  test 'sort arrays and relations the same way' do
    Document.destroy_all
    Factory(:document, title: 'document a', updated_at: 3.days.ago, created_at: 1.days.ago)
    Factory(:document, title: 'document c', updated_at: 2.days.ago, created_at: 4.days.ago)
    Factory(:document, title: 'document b', updated_at: 1.days.ago, created_at: 3.days.ago)
    Factory(:document, title: 'document e', updated_at: 1.year.ago, created_at: 2.days.ago)
    Factory(:document, title: 'document d', updated_at: 1.days.from_now, created_at: 2.years.ago)

    [:updated_at_asc, :updated_at_desc, :title_desc, :created_at_desc, :created_at_asc, :title_asc].each do |order|
      sort_order = Seek::ListSorter.order_from_keys(order)
      as_relation = Seek::ListSorter.sort_by_order(Document.all, sort_order)
      as_array = Seek::ListSorter.sort_by_order(Document.all.to_a, sort_order)

      assert_equal as_relation.map(&:id), as_array.map(&:id),
                   "Mismatch with order: #{order}.\n\n"+
                       "Rel: #{as_relation.map { |x| "#{x.id} - #{x.title}" }.inspect}\n\n"+
                       "Arr: #{as_array.map { |x| "#{x.id} - #{x.title}" }.inspect}"
    end
  end
end
