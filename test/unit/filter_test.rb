require 'test_helper'

class FilterTest < ActiveSupport::TestCase
  test 'apply filter' do
    tag_filter = Seek::Filterer::FILTERS[:tag]

    abc_doc = Factory(:document)
    abc_doc.annotate_with('abctag', 'tag', abc_doc.contributor)
    disable_authorization_checks { abc_doc.save! }
    abc = TextValue.where(text: 'abctag').first.id
    xyz_doc = Factory(:document)
    xyz_doc.annotate_with('xyztag', 'tag', xyz_doc.contributor)
    disable_authorization_checks { xyz_doc.save! }
    xyz = TextValue.where(text: 'xyztag').first.id

    assert_includes_all tag_filter.apply(Document.all, [abc]).to_a, [abc_doc]
    assert_includes_all tag_filter.apply(Document.all, [xyz]).to_a, [xyz_doc]
    assert_includes_all tag_filter.apply(Document.all, [abc, xyz]).to_a, [abc_doc, xyz_doc]
    assert_includes_all tag_filter.apply(Document.all, [abc.to_s, xyz.to_s]).to_a, [abc_doc, xyz_doc]
    assert_empty tag_filter.apply(Document.all, [2_000_000_000]).to_a
    assert_empty tag_filter.apply(Document.all, ['banana']).to_a
  end

  test 'apply search filter' do
    search_filter = Seek::Filtering::SearchFilter.new

    thing = Factory(:document, title: "Thing One")
    thing2 = Factory(:document, title: "Thing Two")

    with_config_value(:solr_enabled, false) do
      assert_includes_all search_filter.apply(Document.all, ["Thing"]).to_a, [thing, thing2]
    end
    # These would work if solr worked in tests:
    # assert_includes_all search_filter.apply(Document.all, ["One"]).to_a, [thing]
    # assert_includes_all search_filter.apply(Document.all, ["Two"]).to_a, [thing2]
    # assert_empty search_filter.apply(Document.all, ["Banana"]).to_a
  end

  test 'apply date filter with date' do
    created_at_filter = Seek::Filtering::DateFilter.new(field: :created_at, presets: [24.hours, 1.year])

    new_thing = Factory(:document)
    last_weeks_thing = Factory(:document, created_at: 1.week.ago)
    last_months_thing = Factory(:document, created_at: 1.month.ago)
    old_thing = Factory(:document, created_at: 2.years.ago)

    assert_includes_all created_at_filter.apply(Document.all, ["#{2.weeks.ago}"]).to_a, [new_thing, last_weeks_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["#{2.months.ago}"]).to_a, [new_thing, last_weeks_thing, last_months_thing]
    assert_empty created_at_filter.apply(Document.all, ["#{3.months.from_now}"]).to_a
    assert_equal Document.all.to_a, created_at_filter.apply(Document.all, ["1920-20-10"]).to_a, "Bad date should not apply filtering."
  end

  test 'apply date filter with date range' do
    created_at_filter = Seek::Filtering::DateFilter.new(field: :created_at, presets: [24.hours, 1.year])

    new_thing = Factory(:document)
    last_weeks_thing = Factory(:document, created_at: 1.week.ago)
    last_months_thing = Factory(:document, created_at: 1.month.ago)
    old_thing = Factory(:document, created_at: 2.years.ago)

    assert_includes_all created_at_filter.apply(Document.all, ["#{2.weeks.ago}/#{2.weeks.from_now}"]).to_a, [new_thing, last_weeks_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["#{2.months.ago}/#{3.weeks.ago}"]).to_a, [last_months_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["#{3.years.ago}/#{3.weeks.ago}"]).to_a, [last_months_thing, old_thing]
    assert_empty created_at_filter.apply(Document.all, ["#{3.years.ago}/#{5.years.ago}"]).to_a
    assert_equal Document.all.to_a, created_at_filter.apply(Document.all, ["1920-13-13/1930-13-13"]).to_a, "Bad date range should not apply filtering."
  end

  test 'apply date filter with duration' do
    created_at_filter = Seek::Filtering::DateFilter.new(field: :created_at, presets: [24.hours, 1.year])

    new_thing = Factory(:document)
    last_weeks_thing = Factory(:document, created_at: 1.week.ago)
    last_months_thing = Factory(:document, created_at: 1.month.ago)
    old_thing = Factory(:document, created_at: 2.years.ago)

    assert_includes_all created_at_filter.apply(Document.all, ["PT2H"]).to_a, [new_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["P3W"]).to_a, [new_thing, last_weeks_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["P2M1D"]).to_a, [new_thing, last_weeks_thing, last_months_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["P10Y"]).to_a, [new_thing, last_weeks_thing, last_months_thing, old_thing]
    assert_equal Document.all.to_a, created_at_filter.apply(Document.all, ["PQETETWTYWYWTWERWER"]).to_a, "Bad duration should not apply filtering."
    assert_equal Document.all.to_a, created_at_filter.apply(Document.all, ["P1Y2W1D"]).to_a, "Can't mix weeks with other date units."
  end

  test 'apply date filter with multiple conditions' do
    created_at_filter = Seek::Filtering::DateFilter.new(field: :created_at, presets: [24.hours, 1.year])

    new_thing = Factory(:document)
    last_weeks_thing = Factory(:document, created_at: 1.week.ago)
    last_months_thing = Factory(:document, created_at: 1.month.ago)
    old_thing = Factory(:document, created_at: 2.years.ago)

    assert_includes_all created_at_filter.apply(Document.all, ["PT2H", "#{2.months.ago}/#{3.weeks.ago}"]).to_a, [new_thing, last_months_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["#{1.day.ago}/#{1.day.from_now}", "#{3.years.ago}/#{1.year.ago}"]).to_a, [new_thing, old_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["#{1.day.ago}/#{1.day.from_now}", "#{7.years.ago}/#{6.year.ago}"]).to_a, [new_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["PT2H", "P2W", "P2M"]).to_a, [new_thing, last_weeks_thing, last_months_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["PT2H", "P2W", "PXYZ", "PDFSDGDS", "LBALSFASFA"]).to_a, [new_thing, last_weeks_thing] # Ignores junk
  end

  test 'apply year filter' do
    Publication.delete_all

    year_filter = Seek::Filtering::YearFilter.new(field: 'published_date')

    new_pub = Factory(:publication, published_date: '2019-10-14')
    newish_pub = Factory(:publication, published_date: '2019-01-01')
    old_pub = Factory(:publication, published_date: '1970-10-10')

    assert_includes_all year_filter.apply(Publication.all, ['2019']).to_a, [new_pub, newish_pub]
    assert_includes_all year_filter.apply(Publication.all, ['1970']).to_a, [old_pub]
    assert_includes_all year_filter.apply(Publication.all, ['2019', '1970']).to_a, [new_pub, newish_pub, old_pub]
    assert_empty year_filter.apply(Publication.all, ['1996']).to_a
    assert_empty year_filter.apply(Publication.all, ['banana']).to_a
  end

  test 'get filter options' do
    tag_filter = Seek::Filterer::FILTERS[:tag]

    abc_doc = Factory(:document)
    abc_doc.annotate_with('abctag', 'tag', abc_doc.contributor)
    disable_authorization_checks { abc_doc.save! }
    abc = TextValue.where(text: 'abctag').first.id.to_s
    xyz_doc = Factory(:document)
    xyz_doc.annotate_with('xyztag', 'tag', xyz_doc.contributor)
    disable_authorization_checks { xyz_doc.save! }
    xyz = TextValue.where(text: 'xyztag').first.id.to_s

    options = tag_filter.options(Document.all, [])
    assert_equal 2, options.length
    abc_opt = get_option(options, abc)
    assert_equal 1, abc_opt.count
    assert_equal 'abctag', abc_opt.label
    refute abc_opt.active?
    xyz_opt = get_option(options, xyz)
    assert_equal 1, xyz_opt.count
    assert_equal 'xyztag', xyz_opt.label
    refute xyz_opt.active?

    options = tag_filter.options(Document.all, [abc])
    assert_equal 2, options.length
    abc_opt = get_option(options, abc)
    assert_equal 1, abc_opt.count
    assert_equal 'abctag', abc_opt.label
    assert abc_opt.active?
    xyz_opt = get_option(options, xyz)
    assert_equal 1, xyz_opt.count
    assert_equal 'xyztag', xyz_opt.label
    refute xyz_opt.active?

    options = tag_filter.options(Document.all, [abc, xyz])
    assert_equal 2, options.length
    abc_opt = get_option(options, abc)
    assert_equal 1, abc_opt.count
    assert_equal 'abctag', abc_opt.label
    assert abc_opt.active?
    xyz_opt = get_option(options, xyz)
    assert_equal 1, xyz_opt.count
    assert_equal 'xyztag', xyz_opt.label
    assert xyz_opt.active?
  end

  test 'get filter options for filter with label mapping' do
    contributor_filter = Seek::Filterer::FILTERS[:contributor]

    person1 = Factory(:person, first_name: 'Jane', last_name: 'Doe')
    person2 = Factory(:person, first_name: 'John', last_name: 'Doe')

    person1_doc = Factory(:document, contributor: person1)
    person1_other_doc = Factory(:document, contributor: person1)
    person2_doc = Factory(:document, contributor: person2)

    options = contributor_filter.options(Document.all, [])
    assert_equal 2, options.length
    p1_opt = get_option(options, person1.id.to_s)
    refute p1_opt.active?
    assert_equal "Jane Doe", p1_opt.label
    assert_equal 2, p1_opt.count
    p2_opt = get_option(options, person2.id.to_s)
    refute p2_opt.active?
    assert_equal "John Doe", p2_opt.label
    assert_equal 1, p2_opt.count

    options = contributor_filter.options(Document.all, [person1.id.to_s])
    assert_equal 2, options.length
    p1_opt = get_option(options, person1.id.to_s)
    assert p1_opt.active?
    assert_equal "Jane Doe", p1_opt.label
    assert_equal 2, p1_opt.count
    p2_opt = get_option(options, person2.id.to_s)
    refute p2_opt.active?
    assert_equal "John Doe", p2_opt.label
    assert_equal 1, p2_opt.count

    options = contributor_filter.options(Document.all, [person1.id.to_s, person2.id.to_s])
    assert_equal 2, options.length
    p1_opt = get_option(options, person1.id.to_s)
    assert p1_opt.active?
    assert_equal "Jane Doe", p1_opt.label
    assert_equal 2, p1_opt.count
    p2_opt = get_option(options, person2.id.to_s)
    assert p2_opt.active?
    assert_equal "John Doe", p2_opt.label
    assert_equal 1, p2_opt.count

  end

  test 'get search filter options' do
    search_filter = Seek::Filtering::SearchFilter.new

    thing = Factory(:document, title: "Thing One")
    thing2 = Factory(:document, title: "Thing Two")

    with_config_value(:solr_enabled, false) do
      options = search_filter.options(Document.all, ["Thing"])
      assert_empty options
    end

    with_config_value(:solr_enabled, true) do
      options = search_filter.options(Document.all, ["Thing"])
      assert_equal 1, options.length
      option = options.first
      assert_equal 'Thing', option.value
      assert_equal 'Thing', option.label
      assert option.active?
    end
  end

  test 'get date filter options' do
    presets = [24.hours, 1.year]
    created_at_filter = Seek::Filtering::DateFilter.new(field: :created_at, presets: presets)

    new_thing = Factory(:document)
    last_weeks_thing = Factory(:document, created_at: 1.week.ago)
    last_months_thing = Factory(:document, created_at: 1.month.ago)
    old_thing = Factory(:document, created_at: 2.years.ago)

    # No actives
    options = created_at_filter.options(Document.all, [])
    assert_equal 2, options.length
    p1_opt = get_option(options, 'PT24H')
    refute p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count

    # Preset duration active
    options = created_at_filter.options(Document.all, ['PT24H'])
    assert_equal 2, options.length
    p1_opt = get_option(options, 'PT24H')
    assert p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count

    # Custom duration active
    options = created_at_filter.options(Document.all, ['P2Y2M3D'])
    assert_equal 3, options.length, "Should be 1 option per preset, plus the user-specified option."
    p1_opt = get_option(options, 'PT24H')
    refute p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count
    user_opt = get_option(options, 'P2Y2M3D')
    assert user_opt.active?
    assert_equal 'in the last 2 years, 2 months, and 3 days', user_opt.label
    assert_nil user_opt.count

    # Date active
    options = created_at_filter.options(Document.all, ['1970-01-01'])
    assert_equal 3, options.length, "Should be 1 option per preset, plus the user-specified option."
    p1_opt = get_option(options, 'PT24H')
    refute p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count
    user_opt = get_option(options, '1970-01-01')
    assert user_opt.active?
    assert_equal 'since 1970-01-01', user_opt.label
    assert_nil user_opt.count

    # Date range active
    options = created_at_filter.options(Document.all, ['1970-01-01/1980-01-01'])
    assert_equal 3, options.length, "Should be 1 option per preset, plus the user-specified option."
    p1_opt = get_option(options, 'PT24H')
    refute p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count
    user_opt = get_option(options, '1970-01-01/1980-01-01')
    assert user_opt.active?
    assert_equal 'between 1970-01-01 and 1980-01-01', user_opt.label
    assert_nil user_opt.count

    # Multiple active options
    options = created_at_filter.options(Document.all, ['1970-01-01/1980-01-01', 'P3W'])
    assert_equal 4, options.length, "Should be 1 option per preset, plus the user-specified options."
    p1_opt = get_option(options, 'PT24H')
    refute p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count
    user_opt1 = get_option(options, '1970-01-01/1980-01-01')
    assert user_opt1.active?
    assert_equal 'between 1970-01-01 and 1980-01-01', user_opt1.label
    assert_nil user_opt1.count
    user_opt2 = get_option(options, 'P3W')
    assert user_opt2.active?
    assert_equal 'in the last 3 weeks', user_opt2.label
    assert_nil user_opt2.count
  end

  test 'get year filter options' do
    Publication.delete_all

    year_filter = Seek::Filtering::YearFilter.new(field: 'published_date')

    new_pub = Factory(:publication, published_date: '2019-10-14')
    newish_pub = Factory(:publication, published_date: '2019-01-01')
    old_pub = Factory(:publication, published_date: '1970-10-10')

    options = year_filter.options(Publication.all, [])
    assert_equal 2, options.length
    y2019_opt = get_option(options, '2019')
    refute y2019_opt.active?
    assert_equal '2019', y2019_opt.label
    assert_equal 2, y2019_opt.count
    y1970_opt = get_option(options, '1970')
    refute y1970_opt.active?
    assert_equal '1970', y1970_opt.label
    assert_equal 1, y1970_opt.count

    options = year_filter.options(Publication.all, ['2019'])
    assert_equal 2, options.length
    y2019_opt = get_option(options, '2019')
    assert y2019_opt.active?
    assert_equal '2019', y2019_opt.label
    assert_equal 2, y2019_opt.count
    y1970_opt = get_option(options, '1970')
    refute y1970_opt.active?
    assert_equal '1970', y1970_opt.label
    assert_equal 1, y1970_opt.count

    options = year_filter.options(Publication.all, ['2019', '1970'])
    assert_equal 2, options.length
    y2019_opt = get_option(options, '2019')
    assert y2019_opt.active?
    assert_equal '2019', y2019_opt.label
    assert_equal 2, y2019_opt.count
    y1970_opt = get_option(options, '1970')
    assert y1970_opt.active?
    assert_equal '1970', y1970_opt.label
    assert_equal 1, y1970_opt.count

    options = year_filter.options(Publication.all, ['1996'])
    assert_equal 2, options.length
    y2019_opt = get_option(options, '2019')
    refute y2019_opt.active?
    assert_equal '2019', y2019_opt.label
    assert_equal 2, y2019_opt.count
    y1970_opt = get_option(options, '1970')
    refute y1970_opt.active?
    assert_equal '1970', y1970_opt.label
    assert_equal 1, y1970_opt.count
  end

  private

  def assert_includes_all(collection, things)
    assert_equal collection.length, things.length
    things.each do |thing|
      assert_includes collection, thing
    end
  end

  def get_option(options, value)
    options.detect { |o| o.value == value }
  end
end
