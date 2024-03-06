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

  test 'annotations' do
    path = "#{Rails.root}/test/fixtures/files/fairdatastation/demo.ttl"

    study = BioInd::FairData::Reader.parse_graph(path).first.studies.first

    assert_equal 14, study.annotations.count
    assert_includes study.annotations, ["http://fairbydesign.nl/ontology/center_name", "NIID"]
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

    assert_nil assay.title
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

    investigation = BioInd::FairData::Reader.construct_isa(inv, contributor, [project])
    studies = investigation.studies.to_a
    assays = studies.first.assays.to_a
    data_files = assays.first.assay_assets.to_a.collect(&:asset)

    assert_equal 1, studies.count
    assert_equal 9, assays.count
    assert_equal 2, data_files.count

    assert investigation.valid?
    assert studies.first.valid?

    pp assays.first.errors unless assays.first.valid?
    assert assays.first.valid?

    pp data_files.first.errors unless data_files.first.valid?
    assert data_files.first.valid?

    assert_difference('Investigation.count',1) do
      assert_difference('Study.count',1) do
        assert_difference('Assay.count', 9) do
          assert_difference('AssayAsset.count', 18) do
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
