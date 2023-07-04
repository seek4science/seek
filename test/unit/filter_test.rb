require 'test_helper'

class FilterTest < ActiveSupport::TestCase
  test 'apply filter' do
    tag_filter = Seek::Filterer::FILTERS[:tag]

    abc_doc = FactoryBot.create(:document)
    abc_doc.annotate_with('abctag', 'tag', abc_doc.contributor)
    disable_authorization_checks { abc_doc.save! }
    xyz_doc = FactoryBot.create(:document)
    xyz_doc.annotate_with('xyztag', 'tag', xyz_doc.contributor)
    disable_authorization_checks { xyz_doc.save! }

    assert_includes_all tag_filter.apply(Document.all, ['abctag']).to_a, [abc_doc]
    assert_includes_all tag_filter.apply(Document.all, ['xyztag']).to_a, [xyz_doc]
    assert_includes_all tag_filter.apply(Document.all, ['abctag', 'xyztag']).to_a, [abc_doc, xyz_doc]
    assert_empty tag_filter.apply(Document.all, [2_000_000_000]).to_a
    assert_empty tag_filter.apply(Document.all, ['banana']).to_a
  end

  test 'apply ontology filter' do
    assay_type_filter = Seek::Filterer::FILTERS[:assay_type]
    tech_type_filter = Seek::Filterer::FILTERS[:technology_type]
    metab_exp_assay = FactoryBot.create(:experimental_assay,
                              assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Metabolomics',
                              technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography')
    gen_model_assay = FactoryBot.create(:modelling_assay,
                              assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Genome_scale')

    suggested_type = FactoryBot.create(:suggested_assay_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Metabolomics', label: 'bla')
    sug_type_exp_assay = FactoryBot.create(:experimental_assay,
                                 assay_type_uri: "suggested_assay_type:#{suggested_type.id}",
                                 technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography')

    assays = Assay.where(id: [metab_exp_assay.id, gen_model_assay.id, sug_type_exp_assay.id])

    # Assay type
    assert_includes_all assay_type_filter.apply(assays, ['http://jermontology.org/ontology/JERMOntology#Metabolomics']).to_a,
                        [metab_exp_assay, sug_type_exp_assay]
    assert_includes_all assay_type_filter.apply(assays, ['http://jermontology.org/ontology/JERMOntology#Metabolomics',
                                                         'http://jermontology.org/ontology/JERMOntology#Genome_scale']).to_a,
                        [metab_exp_assay, gen_model_assay, sug_type_exp_assay]
    assert_includes_all assay_type_filter.apply(assays, ['http://jermontology.org/ontology/JERMOntology#Genome_scale',
                                                         'http://jermontology.org/ontology/JERMOntology#Metabolite_profiling']).to_a,
                        [gen_model_assay]
    assert_empty assay_type_filter.apply(assays, ['http://jermontology.org/ontology/JERMOntology#Metabolite_profiling']).to_a
    assert_empty assay_type_filter.apply(assays, ['100000']).to_a

    # Tech type
    assert_includes_all tech_type_filter.apply(assays, ['http://jermontology.org/ontology/JERMOntology#Gas_chromatography']).to_a,
                        [metab_exp_assay, sug_type_exp_assay]
    assert_empty tech_type_filter.apply(assays, ['http://jermontology.org/ontology/JERMOntology#HPLC']).to_a
    assert_empty tech_type_filter.apply(assays, ['100000']).to_a
  end

  test 'apply search filter' do
    search_filter = Seek::Filtering::SearchFilter.new

    thing = FactoryBot.create(:document, title: "Thing One")
    thing2 = FactoryBot.create(:document, title: "Thing Two")

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

    new_thing = FactoryBot.create(:document)
    last_weeks_thing = FactoryBot.create(:document, created_at: 1.week.ago)
    last_months_thing = FactoryBot.create(:document, created_at: 1.month.ago)
    old_thing = FactoryBot.create(:document, created_at: 2.years.ago)

    assert_includes_all created_at_filter.apply(Document.all, ["#{2.weeks.ago}"]).to_a, [new_thing, last_weeks_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["#{2.months.ago}"]).to_a, [new_thing, last_weeks_thing, last_months_thing]
    assert_empty created_at_filter.apply(Document.all, ["#{3.months.from_now}"]).to_a
    assert_equal Document.all.to_a, created_at_filter.apply(Document.all, ["1920-20-10"]).to_a, "Bad date should not apply filtering."
  end

  test 'apply date filter with date range' do
    created_at_filter = Seek::Filtering::DateFilter.new(field: :created_at, presets: [24.hours, 1.year])

    new_thing = FactoryBot.create(:document)
    last_weeks_thing = FactoryBot.create(:document, created_at: 1.week.ago)
    last_months_thing = FactoryBot.create(:document, created_at: 1.month.ago)
    old_thing = FactoryBot.create(:document, created_at: 2.years.ago)

    assert_includes_all created_at_filter.apply(Document.all, ["#{2.weeks.ago}/#{2.weeks.from_now}"]).to_a, [new_thing, last_weeks_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["#{2.months.ago}/#{3.weeks.ago}"]).to_a, [last_months_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["#{3.years.ago}/#{3.weeks.ago}"]).to_a, [last_months_thing, old_thing]
    assert_empty created_at_filter.apply(Document.all, ["#{3.years.ago}/#{5.years.ago}"]).to_a
    assert_equal Document.all.to_a, created_at_filter.apply(Document.all, ["1920-13-13/1930-13-13"]).to_a, "Bad date range should not apply filtering."
  end

  test 'apply date filter with duration' do
    created_at_filter = Seek::Filtering::DateFilter.new(field: :created_at, presets: [24.hours, 1.year])

    new_thing = FactoryBot.create(:document)
    last_weeks_thing = FactoryBot.create(:document, created_at: 1.week.ago)
    last_months_thing = FactoryBot.create(:document, created_at: 1.month.ago)
    old_thing = FactoryBot.create(:document, created_at: 2.years.ago)

    assert_includes_all created_at_filter.apply(Document.all, ["PT2H"]).to_a, [new_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["P3W"]).to_a, [new_thing, last_weeks_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["P2M1D"]).to_a, [new_thing, last_weeks_thing, last_months_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["P10Y"]).to_a, [new_thing, last_weeks_thing, last_months_thing, old_thing]
    assert_equal Document.all.to_a, created_at_filter.apply(Document.all, ["PQETETWTYWYWTWERWER"]).to_a, "Bad duration should not apply filtering."
    assert_equal Document.all.to_a, created_at_filter.apply(Document.all, ["P1Y2W1D"]).to_a, "Can't mix weeks with other date units."
  end

  test 'apply date filter with multiple conditions' do
    created_at_filter = Seek::Filtering::DateFilter.new(field: :created_at, presets: [24.hours, 1.year])

    new_thing = FactoryBot.create(:document)
    last_weeks_thing = FactoryBot.create(:document, created_at: 1.week.ago)
    last_months_thing = FactoryBot.create(:document, created_at: 1.month.ago)
    old_thing = FactoryBot.create(:document, created_at: 2.years.ago)

    assert_includes_all created_at_filter.apply(Document.all, ["PT2H", "#{2.months.ago}/#{3.weeks.ago}"]).to_a, [new_thing, last_months_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["#{1.day.ago}/#{1.day.from_now}", "#{3.years.ago}/#{1.year.ago}"]).to_a, [new_thing, old_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["#{1.day.ago}/#{1.day.from_now}", "#{7.years.ago}/#{6.year.ago}"]).to_a, [new_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["PT2H", "P2W", "P2M"]).to_a, [new_thing, last_weeks_thing, last_months_thing]
    assert_includes_all created_at_filter.apply(Document.all, ["PT2H", "P2W", "PXYZ", "PDFSDGDS", "LBALSFASFA"]).to_a, [new_thing, last_weeks_thing] # Ignores junk
  end

  test 'apply year filter' do
    Publication.delete_all

    year_filter = Seek::Filtering::YearFilter.new(field: 'published_date')

    new_pub = FactoryBot.create(:publication, published_date: '2019-10-14')
    newish_pub = FactoryBot.create(:publication, published_date: '2019-01-01')
    old_pub = FactoryBot.create(:publication, published_date: '1970-10-10')

    assert_includes_all year_filter.apply(Publication.all, ['2019']).to_a, [new_pub, newish_pub]
    assert_includes_all year_filter.apply(Publication.all, ['1970']).to_a, [old_pub]
    assert_includes_all year_filter.apply(Publication.all, ['2019', '1970']).to_a, [new_pub, newish_pub, old_pub]
    assert_empty year_filter.apply(Publication.all, ['1996']).to_a
    assert_empty year_filter.apply(Publication.all, ['banana']).to_a
  end

  test 'get filter options' do
    tag_filter = Seek::Filterer::FILTERS[:tag]

    abc_doc = FactoryBot.create(:document)
    abc_doc.annotate_with('abctag', 'tag', abc_doc.contributor)
    disable_authorization_checks { abc_doc.save! }
    xyz_doc = FactoryBot.create(:document)
    xyz_doc.annotate_with('xyztag', 'tag', xyz_doc.contributor)
    disable_authorization_checks { xyz_doc.save! }

    options = tag_filter.options(Document.all, [])
    assert_equal 2, options.length
    abc_opt = get_option(options, 'abctag')
    assert_equal 1, abc_opt.count
    assert_equal 'abctag', abc_opt.label
    refute abc_opt.active?
    xyz_opt = get_option(options, 'xyztag')
    assert_equal 1, xyz_opt.count
    assert_equal 'xyztag', xyz_opt.label
    refute xyz_opt.active?

    options = tag_filter.options(Document.all, ['abctag'])
    assert_equal 2, options.length
    abc_opt = get_option(options, 'abctag')
    assert_equal 1, abc_opt.count
    assert_equal 'abctag', abc_opt.label
    assert abc_opt.active?
    xyz_opt = get_option(options, 'xyztag')
    assert_equal 1, xyz_opt.count
    assert_equal 'xyztag', xyz_opt.label
    refute xyz_opt.active?

    options = tag_filter.options(Document.all, ['abctag', 'xyztag'])
    assert_equal 2, options.length
    abc_opt = get_option(options, 'abctag')
    assert_equal 1, abc_opt.count
    assert_equal 'abctag', abc_opt.label
    assert abc_opt.active?
    xyz_opt = get_option(options, 'xyztag')
    assert_equal 1, xyz_opt.count
    assert_equal 'xyztag', xyz_opt.label
    assert xyz_opt.active?
  end

  test 'get filter options for ontology filters' do
    assay_type_filter = Seek::Filterer::FILTERS[:assay_type]
    tech_type_filter = Seek::Filterer::FILTERS[:technology_type]
    metab_exp_assay = FactoryBot.create(:experimental_assay,
                              assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Metabolomics',
                              technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography')
    gen_model_assay = FactoryBot.create(:modelling_assay,
                              assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Genome_scale')

    suggested_type = FactoryBot.create(:suggested_assay_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Metabolomics', label: 'bla')
    sug_type_exp_assay = FactoryBot.create(:experimental_assay,
                                 assay_type_uri: "suggested_assay_type:#{suggested_type.id}",
                                 technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography')

    assays = Assay.where(id: [metab_exp_assay.id, gen_model_assay.id, sug_type_exp_assay.id])

    # Assay type
    options = assay_type_filter.options(assays, [])
    assert_equal 2, options.length
    metab_opt = get_option(options, 'http://jermontology.org/ontology/JERMOntology#Metabolomics')
    assert_equal 2, metab_opt.count, "Should include the Metabolomics assay and the suggested type assay."
    assert_equal 'Metabolomics', metab_opt.label
    refute metab_opt.active?
    gen_opt = get_option(options, 'http://jermontology.org/ontology/JERMOntology#Genome_scale')
    assert_equal 1, gen_opt.count
    assert_equal 'Genome scale', gen_opt.label
    refute gen_opt.active?
    # Tech type
    options = tech_type_filter.options(assays, [])
    assert_equal 1, options.length
    gas_opt = get_option(options, 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography')
    assert_equal 2, gas_opt.count
    assert_equal 'Gas chromatography', gas_opt.label
    refute gas_opt.active?

    # Assay type
    options = assay_type_filter.options(assays, ['http://jermontology.org/ontology/JERMOntology#Metabolomics'])
    assert_equal 2, options.length
    metab_opt = get_option(options, 'http://jermontology.org/ontology/JERMOntology#Metabolomics')
    assert_equal 2, metab_opt.count
    assert_equal 'Metabolomics', metab_opt.label
    assert metab_opt.active?
    gen_opt = get_option(options, 'http://jermontology.org/ontology/JERMOntology#Genome_scale')
    assert_equal 1, gen_opt.count
    assert_equal 'Genome scale', gen_opt.label
    refute gen_opt.active?
    # Tech type
    options = tech_type_filter.options(assays, ['http://jermontology.org/ontology/JERMOntology#Gas_chromatography'])
    assert_equal 1, options.length
    gas_opt = get_option(options, 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography')
    assert_equal 2, gas_opt.count
    assert_equal 'Gas chromatography', gas_opt.label
    assert gas_opt.active?

    # Assay type
    options = assay_type_filter.options(assays,['http://jermontology.org/ontology/JERMOntology#Metabolomics',
                                                'http://jermontology.org/ontology/JERMOntology#Genome_scale'])
    assert_equal 2, options.length
    metab_opt = get_option(options, 'http://jermontology.org/ontology/JERMOntology#Metabolomics')
    assert_equal 2, metab_opt.count, "Should include the Metabolomics assay and the suggested type assay."
    assert_equal 'Metabolomics', metab_opt.label
    assert metab_opt.active?
    gen_opt = get_option(options, 'http://jermontology.org/ontology/JERMOntology#Genome_scale')
    assert_equal 1, gen_opt.count
    assert_equal 'Genome scale', gen_opt.label
    assert gen_opt.active?
  end

  test 'get filter options for filter with label mapping' do
    contributor_filter = Seek::Filterer::FILTERS[:contributor]

    person1 = FactoryBot.create(:person, first_name: 'Jane', last_name: 'Doe')
    person2 = FactoryBot.create(:person, first_name: 'John', last_name: 'Doe')

    person1_doc = FactoryBot.create(:document, contributor: person1)
    person1_other_doc = FactoryBot.create(:document, contributor: person1)
    person2_doc = FactoryBot.create(:document, contributor: person2)

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

    thing = FactoryBot.create(:document, title: "Thing One")
    thing2 = FactoryBot.create(:document, title: "Thing Two")

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
    presets = [24.hours, 1.year, Date.parse('1990-01-01')..Date.parse('2000-01-01')] # Very unlikely that a range will ever be used as a preset value...
    created_at_filter = Seek::Filtering::DateFilter.new(field: :created_at, presets: presets)

    new_thing = FactoryBot.create(:document)
    last_weeks_thing = FactoryBot.create(:document, created_at: 1.week.ago)
    last_months_thing = FactoryBot.create(:document, created_at: 1.month.ago)
    old_thing = FactoryBot.create(:document, created_at: 2.years.ago)
    ancient_thing = FactoryBot.create(:document, created_at: Time.parse('1995-01-01'))

    # No actives
    options = created_at_filter.options(Document.all, [])
    assert_equal 3, options.length
    p1_opt = get_option(options, 'PT24H')
    refute p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count
    range_opt = get_option(options, '1990-01-01/2000-01-01')
    refute range_opt.active?
    assert_equal 'between 1990-01-01 and 2000-01-01', range_opt.label
    assert_equal 1, range_opt.count

    # Preset duration active
    options = created_at_filter.options(Document.all, ['PT24H'])
    assert_equal 3, options.length
    p1_opt = get_option(options, 'PT24H')
    assert p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count
    range_opt = get_option(options, '1990-01-01/2000-01-01')
    refute range_opt.active?
    assert_equal 'between 1990-01-01 and 2000-01-01', range_opt.label
    assert_equal 1, range_opt.count

    # Preset range active
    options = created_at_filter.options(Document.all, ['1990-01-01/2000-01-01'])
    assert_equal 3, options.length
    p1_opt = get_option(options, 'PT24H')
    refute p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count
    range_opt = get_option(options, '1990-01-01/2000-01-01')
    assert range_opt.active?
    assert_equal 'between 1990-01-01 and 2000-01-01', range_opt.label
    assert_equal 1, range_opt.count

    # Custom duration active
    options = created_at_filter.options(Document.all, ['P2Y2M3D'])
    assert_equal 4, options.length, "Should be 1 option per preset, plus the user-specified option."
    p1_opt = get_option(options, 'PT24H')
    refute p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count
    range_opt = get_option(options, '1990-01-01/2000-01-01')
    refute range_opt.active?
    assert_equal 'between 1990-01-01 and 2000-01-01', range_opt.label
    assert_equal 1, range_opt.count
    user_opt = get_option(options, 'P2Y2M3D')
    assert user_opt.active?
    assert_equal 'in the last 2 years, 2 months, and 3 days', user_opt.label
    assert_nil user_opt.count

    # Date active
    options = created_at_filter.options(Document.all, ['1970-01-01'])
    assert_equal 4, options.length, "Should be 1 option per preset, plus the user-specified option."
    p1_opt = get_option(options, 'PT24H')
    refute p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count
    range_opt = get_option(options, '1990-01-01/2000-01-01')
    refute range_opt.active?
    assert_equal 'between 1990-01-01 and 2000-01-01', range_opt.label
    assert_equal 1, range_opt.count
    user_opt = get_option(options, '1970-01-01')
    assert user_opt.active?
    assert_equal 'since 1970-01-01', user_opt.label
    assert_nil user_opt.count

    # Date range active
    options = created_at_filter.options(Document.all, ['1970-01-01/1980-01-01'])
    assert_equal 4, options.length, "Should be 1 option per preset, plus the user-specified option."
    p1_opt = get_option(options, 'PT24H')
    refute p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count
    range_opt = get_option(options, '1990-01-01/2000-01-01')
    refute range_opt.active?
    assert_equal 'between 1990-01-01 and 2000-01-01', range_opt.label
    assert_equal 1, range_opt.count
    user_opt = get_option(options, '1970-01-01/1980-01-01')
    assert user_opt.active?
    assert_equal 'between 1970-01-01 and 1980-01-01', user_opt.label
    assert_nil user_opt.count

    # Multiple active options
    options = created_at_filter.options(Document.all, ['1970-01-01/1980-01-01', 'P3W'])
    assert_equal 5, options.length, "Should be 1 option per preset, plus the user-specified options."
    p1_opt = get_option(options, 'PT24H')
    refute p1_opt.active?
    assert_equal 'in the last 24 hours', p1_opt.label
    assert_equal 1, p1_opt.count
    p2_opt = get_option(options, 'P1Y')
    refute p2_opt.active?
    assert_equal 'in the last 1 year', p2_opt.label
    assert_equal 3, p2_opt.count
    range_opt = get_option(options, '1990-01-01/2000-01-01')
    refute range_opt.active?
    assert_equal 'between 1990-01-01 and 2000-01-01', range_opt.label
    assert_equal 1, range_opt.count
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

    new_pub = FactoryBot.create(:publication, published_date: '2019-10-14')
    newish_pub = FactoryBot.create(:publication, published_date: '2019-01-01')
    old_pub = FactoryBot.create(:publication, published_date: '1970-10-10')

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
    assert_equal 3, options.length
    # Active value should have an option, even if it returned no results.
    y1996_opt = get_option(options, '1996')
    assert y1996_opt.active?
    assert_equal '1996', y1996_opt.label
    assert_equal 0, y1996_opt.count
    y2019_opt = get_option(options, '2019')
    refute y2019_opt.active?
    assert_equal '2019', y2019_opt.label
    assert_equal 2, y2019_opt.count
    y1970_opt = get_option(options, '1970')
    refute y1970_opt.active?
    assert_equal '1970', y1970_opt.label
    assert_equal 1, y1970_opt.count
  end

  test 'filter should not return duplicates' do
    institution1 = FactoryBot.create(:institution, country: 'NZ')
    institution2 = FactoryBot.create(:institution, country: 'NZ')
    institution3 = FactoryBot.create(:institution, country: 'NZ')
    project1 = FactoryBot.create(:project)
    project2 = FactoryBot.create(:project)
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    person1.add_to_project_and_institution(project1, institution1)
    person1.add_to_project_and_institution(project2, institution2)
    person1.add_to_project_and_institution(project2, institution3)
    person2.add_to_project_and_institution(project1, institution3)
    person2.add_to_project_and_institution(project2, institution2)

    people = Person.where(id: [person1.id, person2.id])

    location_filter = Person.custom_filters[:location]

    assert_includes_all location_filter.apply(people, ['NZ']).to_a, [person1, person2]
    options = location_filter.options(people, [])
    nz_opt = get_option(options, 'NZ')
    refute nz_opt.active?
    assert_equal 'New Zealand', nz_opt.label
    assert_equal 2, nz_opt.count
  end

  test 'get active filter options even if they matched 0 records' do
    tag_filter = Seek::Filterer::FILTERS[:tag]

    cool_contributor = FactoryBot.create(:person)
    cool_blue_doc = FactoryBot.create(:document, contributor: cool_contributor)
    cool_blue_doc.annotate_with(['cool', 'blue'], 'tag', cool_contributor)
    disable_authorization_checks { cool_blue_doc.save! }

    hot_contributor = FactoryBot.create(:person)
    hot_red_doc = FactoryBot.create(:document, contributor: hot_contributor)
    hot_red_doc.annotate_with(['hot', 'red'], 'tag', hot_contributor)
    disable_authorization_checks { hot_red_doc.save! }

    # "hot" tag filter is active with no results, but should be included as an option anyway, so the user can see it.
    filtered = Document.where(contributor: cool_contributor)
    options = tag_filter.options(filtered, ['cool', 'hot'])
    assert_equal 3, options.length
    cool_opt = get_option(options, 'cool')
    assert_equal 1, cool_opt.count
    assert_equal 'cool', cool_opt.label
    assert cool_opt.active?
    blue_opt = get_option(options, 'blue')
    assert_equal 1, blue_opt.count
    assert_equal 'blue', blue_opt.label
    refute blue_opt.active?
    hot_opt = get_option(options, 'hot')
    assert_equal 0, hot_opt.count
    assert_equal 'hot', hot_opt.label
    assert hot_opt.active?

    # "hot" tag filter is not active and has no results, so we don't need to show it.
    filtered = Document.where(contributor: cool_contributor)
    options = tag_filter.options(filtered, ['cool'])
    assert_equal 2, options.length
    cool_opt = get_option(options, 'cool')
    assert_equal 1, cool_opt.count
    assert_equal 'cool', cool_opt.label
    assert cool_opt.active?
    blue_opt = get_option(options, 'blue')
    assert_equal 1, blue_opt.count
    assert_equal 'blue', blue_opt.label
    refute blue_opt.active?
    hot_opt = get_option(options, 'hot')
    assert_nil hot_opt
  end

  test 'get active filter options even if they are invalid' do
    contributor_filter = Seek::Filterer::FILTERS[:contributor]

    contributor = FactoryBot.create(:person)
    FactoryBot.create(:document, contributor: contributor)

    options = contributor_filter.options(Document.all, [contributor.id.to_s])
    assert_equal 1, options.length
    opt = get_option(options, contributor.id.to_s)
    assert_equal 1, opt.count
    assert_equal contributor.name, opt.label
    assert opt.active?

    # Apply some invalid options
    fake_id = Person.maximum(:id) + 100
    options = contributor_filter.options(Document.all, [fake_id, 'banana'])
    assert_equal 3, options.length
    fake_id_opt = get_option(options, fake_id.to_s)
    assert_equal 0, fake_id_opt.count
    assert_equal fake_id.to_s, fake_id_opt.label, "The label should just be the ID, since there is no real person with that ID, we can't get their name."
    assert fake_id_opt.active?
    banana_opt = get_option(options, 'banana')
    assert_equal 0, banana_opt.count
    assert_equal 'banana', banana_opt.label
    assert banana_opt.active?
    real_opt = get_option(options, contributor.id.to_s)
    assert_equal 1, real_opt.count
    assert_equal contributor.name, real_opt.label
    refute real_opt.active?
  end

  private

  def assert_includes_all(collection, things)
    assert_equal things.length, collection.length
    things.each do |thing|
      assert_includes collection, thing
    end
  end

  def get_option(options, value)
    options.detect { |o| o.value == value }
  end
end
