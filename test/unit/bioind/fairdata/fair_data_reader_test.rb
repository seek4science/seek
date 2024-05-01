require 'test_helper'

class FairDataReaderTest < ActiveSupport::TestCase
  test 'read demo' do
    path = "#{Rails.root}/test/fixtures/files/fairdatastation/demo.ttl"

    investigations = BioInd::FairData::Reader.parse_graph(path)
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

  test 'read indpensim' do
    path = "#{Rails.root}/test/fixtures/files/fairdatastation/indpensim.ttl"

    investigations = BioInd::FairData::Reader.parse_graph(path)
    assert_equal 1, investigations.count
    inv = investigations.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_indpensim', inv.resource_uri.to_s
    assert_equal 'indpensim', inv.identifier

    assert_equal 1, inv.studies.count
    study = inv.studies.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_indpensim/stu_Penicillin_production', study.resource_uri.to_s
    assert_equal 'Penicillin_production', study.identifier

    assert_equal 100, study.observation_units.count
    obs_unit = study.observation_units.first
    assert_equal 'http://fairbydesign.nl/ontology/inv_indpensim/stu_Penicillin_production/obs_IndPenSim_V3_Batch_1',
                 obs_unit.resource_uri.to_s
    assert_equal 'IndPenSim_V3_Batch_1', obs_unit.identifier

    assert_equal 0, obs_unit.samples.count
    assert_equal 1, obs_unit.datasets.count
    dataset = obs_unit.datasets.first
    assert_equal 'https://data.yoda.wur.nl/research-bioindustry/Use%20cases/Simulation%20datasets/IndPenSim/IndPenSim_V3_Batch_1.csv.gz', dataset.resource_uri
    assert_equal 'IndPenSim_V3_Batch_1.csv.gz', dataset.identifier
    assert_equal 'file', dataset.description
    assert_equal 'https://data.yoda.wur.nl/research-bioindustry/Use%20cases/Simulation%20datasets/IndPenSim/IndPenSim_V3_Batch_1.csv.gz', dataset.content_url
  end

  test 'annotations' do
    path = "#{Rails.root}/test/fixtures/files/fairdatastation/demo.ttl"

    study = BioInd::FairData::Reader.parse_graph(path).first.studies.first

    assert_equal 14, study.annotations.count
    assert_includes study.annotations, ["http://fairbydesign.nl/ontology/center_name", "NIID"]
  end

  test 'additional metadata annotations' do
    path = "#{Rails.root}/test/fixtures/files/fairdatastation/demo.ttl"

    inv = BioInd::FairData::Reader.parse_graph(path).first
    assert_empty inv.additional_metadata_annotations

    study = inv.studies.first

    assert_equal 8, study.additional_metadata_annotations.count
    assert_includes study.annotations, ["http://fairbydesign.nl/ontology/center_name", "NIID"]
    study.additional_metadata_annotations.each do |annotation|
      assert annotation[0].start_with?('http://fairbydesign.nl/ontology/'), "#{annotation[0]} is not expected"
    end

    # non fairbydesign annotations
    path = "#{Rails.root}/test/fixtures/files/fairdatastation/indpensim.ttl"
    inv = BioInd::FairData::Reader.parse_graph(path).first
    obs_unit = inv.studies.first.observation_units.first
    annotations = obs_unit.additional_metadata_annotations
    assert_equal 5, annotations.count
    pids = annotations.collect{|ann| ann[0]}
    assert_includes pids, 'http://gbol.life/0.1/scientificName'
    assert_includes pids, 'http://purl.uniprot.org/core/organism'
  end

  test 'study assays' do
    path = "#{Rails.root}/test/fixtures/files/fairdatastation/demo.ttl"

    investigations = BioInd::FairData::Reader.parse_graph(path)
    study = investigations.first.studies.first
    assert_equal 9, study.assays.count
    expected = %w[DRR243845 DRR243850 DRR243856 DRR243863 DRR243881 DRR243894 DRR243899 DRR243906
                  DRR243924]
    assert_equal expected, study.assays.collect(&:identifier).sort
  end

  test 'titles and descriptions' do
    path = "#{Rails.root}/test/fixtures/files/fairdatastation/demo.ttl"

    inv = BioInd::FairData::Reader.parse_graph(path).first
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
    path = "#{Rails.root}/test/fixtures/files/fairdatastation/demo.ttl"

    inv = BioInd::FairData::Reader.parse_graph(path).first
    study = inv.studies.first
    obs_unit = study.observation_units.first
    sample = obs_unit.samples.first
    assay = sample.assays.first

    datasets = assay.datasets
    assert_equal 2, datasets.count
    assert_equal ['http://fairbydesign.nl/data_sample/DRR243856_1.fastq.gz', 'http://fairbydesign.nl/data_sample/DRR243856_2.fastq.gz'], datasets.collect(&:resource_uri).collect(&:to_s).sort
    assert_equal ['DRR243856_1.fastq.gz', 'DRR243856_2.fastq.gz'], datasets.collect(&:identifier).sort
    assert_equal ['demultiplexed forward file', 'demultiplexed reverse file'], datasets.collect(&:description).sort
    assert_equal ['http://fairbydesign.nl/data_sample/DRR243856_1.fastq.gz', 'http://fairbydesign.nl/data_sample/DRR243856_2.fastq.gz'], datasets.collect(&:content_url).collect(&:to_s).sort

    assert_equal 0, inv.datasets.count
    assert_equal 0, study.datasets.count
    assert_equal 0, obs_unit.datasets.count
    assert_equal 0, sample.datasets.count
  end

  test 'construct seek isa' do
    path = "#{Rails.root}/test/fixtures/files/fairdatastation/demo.ttl"
    inv = BioInd::FairData::Reader.parse_graph(path).first

    contributor = FactoryBot.create(:person)
    project = contributor.projects.first
    FactoryBot.create(:experimental_assay_class)
    FactoryBot.create(:fairdatastation_virtual_demo_sample_type)

    investigation = BioInd::FairData::Reader.construct_isa(inv, contributor, [project])
    studies = investigation.studies.to_a
    obs_units = studies.first.observation_units.to_a
    assays = studies.first.assays.to_a
    data_files = assays.first.assay_assets.to_a.collect(&:asset).select{|a| a.is_a?(DataFile)}
    samples = obs_units.first.samples.to_a

    assay_samples = assays.collect{|a| a.samples.to_a}.flatten
    assert_equal 9, assay_samples.count
    assert_equal samples, (assay_samples & samples)

    assert_equal 1, studies.count
    assert_equal 9, assays.count
    assert_equal 2, data_files.count
    assert_equal 2, obs_units.count
    assert_equal 4, samples.count

    assert investigation.valid?
    assert studies.first.valid?

    pp assays.first.errors unless assays.first.valid?
    assert assays.first.valid?

    pp data_files.first.errors unless data_files.first.valid?
    assert data_files.first.valid?

    assert_difference('Investigation.count', 1) do
      assert_difference('Study.count', 1) do
        assert_difference('ObservationUnit.count', 2) do
          assert_difference('Sample.count', 9) do
            assert_difference('Assay.count', 9) do
              assert_difference('AssayAsset.count', 27) do
                assert_difference('DataFile.count', 18) do
                  User.with_current_user(contributor.user) do
                    investigation.save!
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  test 'populate extended metadata and samples' do
    study_metadata_type = FactoryBot.create(:fairdata_virtual_demo_study_extended_metadata)
    FactoryBot.create(:study_extended_metadata_type)
    FactoryBot.create(:fairdata_virtual_demo_study_extended_metadata_partial)
    assay_metadata_type = FactoryBot.create(:fairdata_virtual_demo_assay_extended_metadata)
    FactoryBot.create(:simple_assay_extended_metadata_type)
    FactoryBot.create(:simple_investigation_extended_metadata_type_with_description_and_label)
    FactoryBot.create(:experimental_assay_class)
    sample_type = FactoryBot.create(:fairdatastation_virtual_demo_sample_type)

    path = "#{Rails.root}/test/fixtures/files/fairdatastation/demo.ttl"
    inv = BioInd::FairData::Reader.parse_graph(path).first
    contributor = FactoryBot.create(:person)
    project = contributor.projects.first

    investigation = BioInd::FairData::Reader.construct_isa(inv, contributor, [project])
    assert_nil investigation.extended_metadata

    study = investigation.studies.first
    refute_nil study.extended_metadata
    assert_equal study_metadata_type, study.extended_metadata.extended_metadata_type

    assert_equal 'DRP007092', study.extended_metadata.get_attribute_value('Alias')
    assert_equal 'NIID', study.extended_metadata.get_attribute_value('Centre Name')
    assert_equal 'human gut metagenome', study.extended_metadata.get_attribute_value('Centre Project Name')
    assert_equal 'PRJDB10485', study.extended_metadata.get_attribute_value('External Ids')
    assert_equal 'DRA010770', study.extended_metadata.get_attribute_value('Submission Accession')
    assert_equal 'DRA010770', study.extended_metadata.get_attribute_value('Submission Alias')
    assert_equal 'AIDS Research Center2022-8-31', study.extended_metadata.get_attribute_value('Submission Lab Name')

    assay = study.assays.first
    refute_nil assay.extended_metadata
    assert_equal assay_metadata_type, assay.extended_metadata.extended_metadata_type

    assert_equal 'NMIMR', assay.extended_metadata.get_attribute_value('Facility')
    assert_equal 'CCTACGGGNGGCWGCAG', assay.extended_metadata.get_attribute_value('Forward Primer')
    assert_equal 'Illumina MiSeq', assay.extended_metadata.get_attribute_value('Instrument Model')
    assert_equal 'PCR', assay.extended_metadata.get_attribute_value('Library Selection')
    assert_equal 'METAGENOMIC', assay.extended_metadata.get_attribute_value('Library Source')
    assert_equal 'AMPLICON', assay.extended_metadata.get_attribute_value('Library Strategy')

    assert_difference('ExtendedMetadata.count', 10) do
      User.with_current_user(contributor.user) do
        study.save!
      end
    end

    sample = study.observation_units.first.samples.first
    refute_nil sample.sample_type
    assert_equal sample_type, sample.sample_type
    assert_equal 'sample DRS176892', sample.title
    assert_equal 'Sample obtained from Single age 30 collected on 2017-09-13 from the human gut', sample.get_attribute_value('Description')
    assert_equal 'Homo sapiens', sample.get_attribute_value('Host')
    assert_equal 'HIV-1 positive', sample.get_attribute_value('Host disease stat')
    assert_equal 'Single', sample.get_attribute_value('Marital status')
    assert_equal 'Trader', sample.get_attribute_value('Occupation')
    assert_equal 'human gut metagenome', sample.get_attribute_value('Scientific name')
    assert_equal '408170', sample.get_attribute_value('Organism')

  end

  test 'observation_unit datasets created in construct_isa' do
    path = "#{Rails.root}/test/fixtures/files/fairdatastation/indpensim.ttl"
    inv = BioInd::FairData::Reader.parse_graph(path).first

    contributor = FactoryBot.create(:person)
    project = contributor.projects.first
    FactoryBot.create(:experimental_assay_class)
    FactoryBot.create(:fairdatastation_virtual_demo_sample_type)

    investigation = BioInd::FairData::Reader.construct_isa(inv, contributor, [project])
    assert_equal 100, investigation.studies.first.observation_units.to_a.count
    observation_unit = investigation.studies.first.observation_units.first
    assert_equal 1, observation_unit.observation_unit_assets.select{|oua| oua.asset_type == 'DataFile'}.collect(&:asset).count

    df = observation_unit.observation_unit_assets.first.asset
    assert_equal 'Dataset: IndPenSim_V3_Batch_1.csv.gz', df.title
    assert_equal 'file', df.description

    assert_difference('DataFile.count',96) do
      assert_difference('ObservationUnitAsset.count',96) do
        disable_authorization_checks {
          investigation.save!
        }
      end
    end

    pp DataFile.all.collect(&:title).inspect
  end

  test 'populate obsv unit extended metadata' do
    ext_metadata_type = FactoryBot.create(:fairdata_indpensim_obsv_unit_extended_metadata)
    FactoryBot.create(:experimental_assay_class)

    path = "#{Rails.root}/test/fixtures/files/fairdatastation/indpensim.ttl"
    inv = BioInd::FairData::Reader.parse_graph(path).first
    contributor = FactoryBot.create(:person)
    project = contributor.projects.first

    investigation = BioInd::FairData::Reader.construct_isa(inv, contributor, [project])
    assert_nil investigation.extended_metadata

    assert_difference('ExtendedMetadata.count', 100) do
      User.with_current_user(contributor.user) do
        investigation.save!
      end
    end

    assert_equal 1, investigation.studies.count
    study = investigation.studies.first
    assert_equal 100, study.observation_units.count
    obvs_unit = study.observation_units.first
    refute_nil obvs_unit.extended_metadata
    assert_equal ext_metadata_type, obvs_unit.extended_metadata.extended_metadata_type

    assert_equal 'FermentorX', obvs_unit.extended_metadata.get_attribute_value('Brand')
    assert_equal 'batch', obvs_unit.extended_metadata.get_attribute_value('Fermentation')
    assert_equal '100,000 litre', obvs_unit.extended_metadata.get_attribute_value('Volume')
    assert_equal 'Penicillium chrysogenum', obvs_unit.extended_metadata.get_attribute_value('Scientific Name')
    assert_equal '5076', obvs_unit.extended_metadata.get_attribute_value('Organism')
  end

end
