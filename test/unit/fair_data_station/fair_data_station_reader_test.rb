require 'test_helper'

class FairDataStationReaderTest < ActiveSupport::TestCase
  test 'read demo' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/demo.ttl"

    investigations = Seek::FairDataStation::Reader.new.parse_graph(path)
    assert_equal 1, investigations.count
    inv = investigations.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_INV_DRP007092', inv.resource_uri.to_s
    assert_equal 'INV_DRP007092', inv.identifier

    assert_equal 1, inv.studies.count
    study = inv.studies.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_INV_DRP007092/stu_DRP007092', study.resource_uri.to_s
    assert_equal 'DRP007092', study.identifier

    assert_equal 2, study.observation_units.count
    obs_unit = study.observation_units.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_INV_DRP007092/stu_DRP007092/obs_HIV-1_positive',
                 obs_unit.resource_uri.to_s
    assert_equal 'HIV-1_positive', obs_unit.identifier

    assert_equal 4, obs_unit.samples.count
    sample = obs_unit.samples.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_INV_DRP007092/stu_DRP007092/obs_HIV-1_positive/sam_DRS176892',
                 sample.resource_uri.to_s
    assert_equal 'DRS176892', sample.identifier

    assert_equal 1, sample.assays.count
    assay = sample.assays.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_INV_DRP007092/stu_DRP007092/obs_HIV-1_positive/sam_DRS176892/asy_DRR243856',
                 assay.resource_uri.to_s
    assert_equal 'DRR243856', assay.identifier
  end

  test 'read seek test case' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"

    investigations = Seek::FairDataStation::Reader.new.parse_graph(path)
    assert_equal 1, investigations.count
    inv = investigations.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_seek-test-investigation', inv.resource_uri.to_s
    assert_equal 'seek-test-investigation', inv.identifier

    assert_equal 2, inv.studies.count
    study = inv.studies.last
    assert_equal 'http://fairbydesign.nl/ontology/inv_seek-test-investigation/stu_seek-test-study-2',
                 study.resource_uri.to_s
    assert_equal 'seek-test-study-2', study.identifier

    assert_equal 2, study.observation_units.count
    obs_unit = study.observation_units.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_seek-test-investigation/stu_seek-test-study-2/obs_seek-test-obs-unit-2',
                 obs_unit.resource_uri.to_s
    assert_equal 'seek-test-obs-unit-2', obs_unit.identifier

    assert_equal 2, obs_unit.samples.count
    assert_equal 1, obs_unit.datasets.count
    dataset = obs_unit.datasets.first
    assert_equal 'http://fairbydesign.nl/data_sample/test-file-1.csv', dataset.resource_uri
    assert_equal 'test-file-1.csv', dataset.identifier
    assert_equal 'file', dataset.description
    assert_equal 'http://fairbydesign.nl/data_sample/test-file-1.csv', dataset.content_url
  end

  test 'annotations' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/demo.ttl"

    study = Seek::FairDataStation::Reader.new.parse_graph(path).first.studies.first

    assert_equal 14, study.annotations.count
    assert_includes study.annotations, ['http://fairbydesign.nl/ontology/center_name', 'NIID']
  end

  test 'additional metadata annotations' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/demo.ttl"

    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    assert_empty inv.additional_metadata_annotations

    study = inv.studies.first

    assert_equal 8, study.additional_metadata_annotations.count
    assert_includes study.additional_metadata_annotations, ['http://fairbydesign.nl/ontology/center_name', 'NIID']
    study.additional_metadata_annotations.each do |annotation|
      assert annotation[0].start_with?('http://fairbydesign.nl/ontology/'), "#{annotation[0]} is not expected"
    end

    # packageName not included
    assay = study.assays.first
    assert_equal 12, assay.additional_metadata_annotations.count
    refute_includes assay.additional_metadata_annotations,
                    ['http://fairbydesign.nl/ontology/packageName', 'Amplicon demultiplexed']
    assert_equal 'Amplicon demultiplexed', assay.package_name
    assert_nil study.package_name

    # non fairbydesign annotations
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    obs_unit = inv.studies.first.observation_units.first
    annotations = obs_unit.additional_metadata_annotations
    assert_equal 3, annotations.count
    pids = annotations.collect { |ann| ann[0] }
    assert_includes pids, 'https://w3id.org/mixs/0000811'
    sample = obs_unit.samples.first
    annotations = sample.additional_metadata_annotations
    assert_equal 4, annotations.count
    pids = annotations.collect { |ann| ann[0] }
    assert_includes pids, 'https://w3id.org/mixs/0000011'
    assert_includes pids, 'http://gbol.life/0.1/scientificName'
    assert_includes pids, 'http://purl.uniprot.org/core/organism'
  end

  test 'study assays' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/demo.ttl"

    investigations = Seek::FairDataStation::Reader.new.parse_graph(path)
    study = investigations.first.studies.first
    assert_equal 9, study.assays.count
    expected = %w[DRR243845 DRR243850 DRR243856 DRR243863 DRR243881 DRR243894 DRR243899 DRR243906
                  DRR243924]
    assert_equal expected, study.assays.collect(&:identifier).sort
  end

  test 'titles and descriptions' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/demo.ttl"

    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    study = inv.studies.first
    obs_unit = study.observation_units.first
    sample = obs_unit.samples.first
    assay = sample.assays.first

    assert_equal 'HIV-1 infected individuals in Ghana', inv.title
    assert_equal 'Exploration of HIV-1 infected individuals in Ghana', inv.description

    assert_equal 'Dysbiotic fecal microbiome in HIV-1 infected individuals in Ghana', study.title
    assert_equal 'This project is to analyze the dysbiosis of fecal microbiome in HIV-1 infected individuals in Ghana. Gut microbiome dysbiosis has been correlated to the progression of non-AIDS diseases such as cardiovascular and metabolic disorders. Because the microbiome composition is different among races and countries, analyses of the composition in different regions is important to understand the pathogenesis unique to specific regions. In the present study, we examined fecal microbiome compositions in HIV-1 infected individuals in Ghana. In a cross-sectional case-control study, age- and gender-matched HIV-1 infected Ghanaian adults (HIV-1 [+]; n = 55) and seronegative controls (HIV-1 [-]; n = 55) were enrolled. Alpha diversity of fecal microbiome in HIV-1 (+) was significantly reduced compared to HIV-1 (-) and associated with CD4 counts. HIV-1 (+) showed reduction in varieties of bacteria including most abundant Faecalibacterium but enrichment of Proteobacteria. It should be noted that Ghanaian HIV-1 (+) exhibited enrichment of Dorea and Blautia, whose depletion has been reported in HIV-1 infected in most of other cohorts. Prevotella has been indicated to be enriched in HIV-1-infected MSM (men having sex with men) but was depleted in HIV-1 (+) of our cohort. The present study revealed the characteristic of dysbiotic fecal microbiome in HIV-1 infected Ghanaians, a representative of West African populations.',
                 study.description

    assert_equal 'HIV-1 infected', obs_unit.title
    assert_equal 'HIV-1 infected individuals routinely attending an HIV/AIDS clinic in Ghana, were enrolled into the study. They were identified to reside in 7 communities in the Eastern Region of Ghana.',
                 obs_unit.description

    assert_equal 'sample DRS176892', sample.title
    assert_equal 'Sample obtained from Single age 30 collected on 2017-09-13 from the human gut', sample.description

    assert_equal 'Assay - DRR243856', assay.title
    assert_equal 'Illumina MiSeq paired end sequencing of SAMD00244451', assay.description
  end

  test 'datasets' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/demo.ttl"

    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    study = inv.studies.first
    obs_unit = study.observation_units.first
    sample = obs_unit.samples.first
    assay = sample.assays.first

    datasets = assay.datasets
    assert_equal 2, datasets.count
    assert_equal ['http://fairbydesign.nl/data_sample/DRR243856_1.fastq.gz', 'http://fairbydesign.nl/data_sample/DRR243856_2.fastq.gz'],
                 datasets.collect(&:resource_uri).collect(&:to_s).sort
    assert_equal ['DRR243856_1.fastq.gz', 'DRR243856_2.fastq.gz'], datasets.collect(&:identifier).sort
    assert_equal ['demultiplexed forward file', 'demultiplexed reverse file'], datasets.collect(&:description).sort
    assert_equal ['http://fairbydesign.nl/data_sample/DRR243856_1.fastq.gz', 'http://fairbydesign.nl/data_sample/DRR243856_2.fastq.gz'],
                 datasets.collect(&:content_url).collect(&:to_s).sort

    assert_equal 0, inv.datasets.count
    assert_equal 0, study.datasets.count
    assert_equal 0, obs_unit.datasets.count
    assert_equal 0, sample.datasets.count
  end

  test 'candidates_for_extended_metadata and validate generated json' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    candidates = Seek::FairDataStation::Reader.new.candidates_for_extended_metadata(path)
    assert_equal 4, candidates.count
    assert_equal %w[Investigation Study ObservationUnit Assay], candidates.collect(&:type_name)
    candidates.each do |candidate|
      assert_nothing_raised do
        Seek::ExtendedMetadataType::ExtendedMetadataTypeExtractor.valid_emt_json?(candidate.to_extended_metadata_type_json)
      end
    end

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/demo.ttl"
    candidates = Seek::FairDataStation::Reader.new.candidates_for_extended_metadata(path)
    assert_equal 2, candidates.count
    assert_equal %w[Study Assay], candidates.collect(&:type_name)
    candidates.each do |candidate|
      assert_nothing_raised do
        Seek::ExtendedMetadataType::ExtendedMetadataTypeExtractor.valid_emt_json?(candidate.to_extended_metadata_type_json)
      end
    end
  end
end
