require 'test_helper'

class ListSorterTest < ActiveSupport::TestCase
  test 'rules' do
    expected = {
      'Person' => { 'index' => 'last_name', 'related' => 'last_name' },
      'Institution' => { 'index' => 'title', 'related' => 'title' },
      'Event' => { 'index' => 'start_date', 'related' => 'start_date' },
      'Publication' => { 'index' => 'published_date', 'related' => 'published_date' },
      'Other' => { 'index' => 'title', 'related' => 'updated_at' }
    }

    assert_equal expected, Seek::ListSorter::RULES

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

  test 'index items' do
    p1 = Factory(:person, last_name: 'jones')
    p2 = Factory(:person, last_name: 'davis')
    p3 = Factory(:person, last_name: 'smith')
    p4 = Factory(:person, last_name: nil)
    p1.update_attribute(:updated_at, 6.days.ago)
    p2.update_attribute(:updated_at, 3.days.ago)
    p3.update_attribute(:updated_at, 1.days.ago)
    p4.update_attribute(:updated_at, 2.days.ago)
    people = [p1, p2, p3, p4]

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

    Seek::ListSorter.index_items(people, 'all')
    assert_equal [p2, p1, p3, p4], people
    Seek::ListSorter.index_items(people, 'latest')
    assert_equal [p3, p4, p2, p1], people

    Seek::ListSorter.index_items(institutions, 'all')
    assert_equal [i2, i4, i1, i3], institutions
    Seek::ListSorter.index_items(institutions, 'latest')
    assert_equal [i2, i4, i3, i1], institutions

    Seek::ListSorter.index_items(events, 'all')
    assert_equal [e2, e1, e3], events
    Seek::ListSorter.index_items(events, 'latest')
    assert_equal [e1, e2, e3], events

    Seek::ListSorter.index_items(sops, 'all')
    assert_equal [s1, s3, s2], sops
    Seek::ListSorter.index_items(sops, 'latest')
    assert_equal [s3, s2, s1], sops
  end
end
