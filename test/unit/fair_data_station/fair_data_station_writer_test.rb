require 'test_helper'

class FairDataStationWriterTest < ActiveSupport::TestCase

  test 'construct seek isa' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/demo.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    policy = FactoryBot.create(:public_policy)

    contributor = FactoryBot.create(:person)
    project = contributor.projects.first
    FactoryBot.create(:experimental_assay_class)
    # private but visible to the contributor
    sample_type = FactoryBot.create(:fairdatastation_virtual_demo_sample_type, contributor: contributor, policy: FactoryBot.create(:private_policy))
    investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, [project], policy)

    studies = investigation.studies.to_a
    obs_units = studies.first.observation_units.to_a
    assays = studies.first.assays.to_a
    data_files = assays.first.assay_assets.to_a.collect(&:asset).select { |a| a.is_a?(DataFile) }
    samples = obs_units.first.samples.to_a

    assay_samples = assays.collect { |a| a.samples.to_a }.flatten
    assert_equal 9, assay_samples.count
    assert_equal samples, (assay_samples & samples)

    assert_equal 1, studies.count
    assert_equal 9, assays.count
    assert_equal 2, data_files.count
    assert_equal 2, obs_units.count
    assert_equal 4, samples.count

    assert_equal Policy::MANAGING, investigation.policy.access_type
    assert_equal Policy::MANAGING, studies.first.policy.access_type
    assert_equal Policy::MANAGING, obs_units.first.policy.access_type
    assert_equal Policy::MANAGING, assays.first.policy.access_type
    assert_equal Policy::MANAGING, samples.first.policy.access_type
    assert_equal Policy::MANAGING, data_files.first.policy.access_type

    refute_equal investigation.policy, studies.first.policy
    refute_equal investigation.policy, obs_units.first.policy
    refute_equal investigation.policy, assays.first.policy
    refute_equal investigation.policy, samples.first.policy
    refute_equal investigation.policy, data_files.first.policy

    assert investigation.valid?
    assert studies.first.valid?

    pp assays.first.errors unless assays.first.valid?
    assert assays.first.valid?

    pp data_files.first.errors unless data_files.first.valid?
    assert data_files.first.valid?

    assert_equal 'INV_DRP007092', investigation.external_identifier
    assert_equal 'DRP007092', studies.first.external_identifier
    assert_equal 'DRR243856', assays.first.external_identifier
    assert_equal 'DRR243856_1.fastq.gz', data_files.first.external_identifier
    assert_equal 'HIV-1_positive', obs_units.first.external_identifier
    assert_equal 'DRS176892', samples.first.external_identifier
    assert_equal sample_type, samples.first.sample_type

    assert_difference('Investigation.count', 1) do
      assert_difference('Study.count', 1) do
        assert_difference('ObservationUnit.count', 2) do
          assert_difference('Sample.count', 9) do
            assert_difference('Assay.count', 9) do
              assert_difference('AssayAsset.count', 27) do
                assert_difference('DataFile.count', 18) do
                  assert_difference('ActivityLog.count', 40) do
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
    (logs = ActivityLog.last(40)).each do |log|
      assert_equal 'create', log.action
      assert_equal contributor, log.culprit
      assert_equal 'fair data station import', log.data
    end
    investigation.reload
    assert_equal 1, investigation.activity_logs.count
    assert_includes logs, investigation.activity_logs.first
    study = investigation.studies.first
    assert_equal 1, study.activity_logs.count
    assert_includes logs, study.activity_logs.first
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

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/demo.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    contributor = FactoryBot.create(:person)
    project = contributor.projects.first

    investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, [project], Policy.default)
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
    assert_equal 'MiSeq Reagent Kit v3 (600-cycle) with a 20% PhiX (Illumina) spike-in',
                 assay.extended_metadata.get_attribute_value('Protocol')
    assert_equal 'CCTACGGGNGGCWGCAG', assay.extended_metadata.get_attribute_value('Forward Primer')
    assert_equal 'Illumina MiSeq', assay.extended_metadata.get_attribute_value('Instrument Model')
    assert_equal 'PCR', assay.extended_metadata.get_attribute_value('Library Selection')
    assert_equal 'METAGENOMIC', assay.extended_metadata.get_attribute_value('Library Source')
    assert_equal 'AMPLICON', assay.extended_metadata.get_attribute_value('Library Strategy')

    study.assays.each do |assay|
      assert assay.valid?, "invalid assay - #{assay.errors.full_messages}"
    end
    assert study.valid?, "invalid study - #{study.errors.full_messages}"
    assert investigation.valid?, "invalid investigation - #{investigation.errors.full_messages}"

    assert_difference('ExtendedMetadata.count', 10) do
      User.with_current_user(contributor.user) do
        study.save!
      end
    end

    sample = study.observation_units.first.samples.first
    refute_nil sample.sample_type
    assert_equal sample_type, sample.sample_type
    assert_equal 'sample DRS176892', sample.title
    assert_equal 'Sample obtained from Single age 30 collected on 2017-09-13 from the human gut',
                 sample.get_attribute_value('Description')
    assert_equal 'Homo sapiens', sample.get_attribute_value('Host')
    assert_equal 'HIV-1 positive', sample.get_attribute_value('Host disease stat')
    assert_equal 'Single', sample.get_attribute_value('Marital status')
    assert_equal 'Trader', sample.get_attribute_value('Occupation')
    assert_equal 'human gut metagenome', sample.get_attribute_value('Scientific name')
    assert_equal '408170', sample.get_attribute_value('Organism')
  end

  test 'ignore disabled EMT' do
    contributor = FactoryBot.create(:person)
    FactoryBot.create(:experimental_assay_class)
    FactoryBot.create(:fairdatastation_test_case_sample_type, policy: Policy.public_policy)
    FactoryBot.create(:fairdata_test_case_study_extended_metadata, enabled: false)
    project = contributor.projects.first
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    investigation = nil
    assert_difference('Study.count', 2) do
      assert_no_difference('ExtendedMetadata.count') do
        User.with_current_user(contributor.user) do
          investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, [project], Policy.default)
          investigation.save!
        end
      end
    end
    investigation.reload
    assert_equal [nil, nil], investigation.studies.collect(&:extended_metadata)
  end

  test 'observation_unit and assay datasets created in construct_isa' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first

    contributor = FactoryBot.create(:person)
    project = contributor.projects.first
    FactoryBot.create(:experimental_assay_class)
    FactoryBot.create(:fairdatastation_test_case_sample_type)

    investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, [project], Policy.default)
    assert_equal 2, investigation.studies.last.observation_units.to_a.count
    observation_unit = investigation.studies.last.observation_units.first
    assert_equal 1, observation_unit.observation_unit_assets.find_all { |oua|
                      oua.asset_type == 'DataFile'
                    }.collect(&:asset).count

    df = observation_unit.observation_unit_assets.find_all { |oua| oua.asset_type == 'DataFile' }.first.asset
    assert_equal 'Dataset: test-file-1.csv', df.title
    assert_equal 'file', df.description
    assert_equal 'application/octet-stream', df.content_blob.content_type
    assert df.content_blob.external_link?
    assert df.content_blob.is_webpage?
    assert df.content_blob.show_as_external_link?

    assay = investigation.studies.last.assays.last
    assert_equal 'Assay - seek-test-assay-6', assay.title
    assert_equal 1, assay.assay_assets.find_all { |oua| oua.asset_type == 'DataFile' }.collect(&:asset).count
    df = assay.assay_assets.find_all { |oua| oua.asset_type == 'DataFile' }.first.asset
    assert_equal 'Dataset: test-file-3.csv', df.title
    assert_equal 'file', df.description
    assert_equal 'application/octet-stream', df.content_blob.content_type
    assert df.content_blob.external_link?
    assert df.content_blob.is_webpage?
    assert df.content_blob.show_as_external_link?

    assert_difference('DataFile.count', 5) do
      assert_difference('ObservationUnitAsset.count', 3) do
        disable_authorization_checks do
          investigation.save!
        end
      end
    end

    # check dataset linked to multiple cases
    df = DataFile.where(external_identifier: 'test-file-1.csv').first
    assert_equal %w[seek-test-obs-unit-1 seek-test-obs-unit-2],
                 df.observation_units.collect(&:external_identifier).sort
    assert_equal ['seek-test-assay-1'], df.assays.collect(&:external_identifier).sort
    df = DataFile.where(external_identifier: 'test-file-3.csv').first
    assert_empty df.observation_units
    assert_equal %w[seek-test-assay-3 seek-test-assay-6], df.assays.collect(&:external_identifier).sort
  end

  test 'populate obsv unit extended metadata' do
    ext_metadata_type = FactoryBot.create(:fairdata_test_case_obsv_unit_extended_metadata)
    FactoryBot.create(:fairdatastation_test_case_sample_type)
    FactoryBot.create(:experimental_assay_class)

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    contributor = FactoryBot.create(:person)
    project = contributor.projects.first

    investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, [project], Policy.default)
    assert_nil investigation.extended_metadata

    assert_difference('ExtendedMetadata.count', 3) do
      User.with_current_user(contributor.user) do
        investigation.save!
      end
    end

    assert_equal 2, investigation.studies.count
    study = investigation.studies.first
    assert_equal 1, study.observation_units.count
    obvs_unit = study.observation_units.first
    refute_nil obvs_unit.extended_metadata
    assert_equal ext_metadata_type, obvs_unit.extended_metadata.extended_metadata_type

    assert_equal '1234g', obvs_unit.extended_metadata.get_attribute_value('Birth weight')
    assert_equal 'male', obvs_unit.extended_metadata.get_attribute_value('Gender')
    assert_equal '2020-01-10', obvs_unit.extended_metadata.get_attribute_value('Date of birth')
  end

  test 'no sample type during construct isa raises exception' do
    FactoryBot.create(:fairdata_test_case_obsv_unit_extended_metadata)
    disable_authorization_checks{ SampleType.destroy_all }
    FactoryBot.create(:experimental_assay_class)

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    contributor = FactoryBot.create(:person)
    project = contributor.projects.first

    assert_raises(Seek::FairDataStation::MissingSampleTypeException) do
      Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, [project], Policy.default)
    end

  end

  test 'update isa' do
    investigation = setup_test_case_investigation
    policy = investigation.policy
    projects = investigation.projects
    contributor = investigation.contributor

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-modified-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first

    # on save check, 0 investigation created, 1 study created, 1 obs unit, 1 sample, 1 assay, 3 data file, 3 extended metadata

    assert_no_difference('Investigation.count') do
      assert_difference('Study.count', 1) do
        assert_difference('ObservationUnit.count', 1) do
          assert_difference('Sample.count', 1) do
            assert_difference('Assay.count', 1) do
              assert_difference('DataFile.count', 3) do
                assert_difference('ObservationUnitAsset.count', 1) do
                  assert_difference('AssayAsset.count', 2) do # 1 for new df, the other is for the sample
                    assert_difference('ExtendedMetadata.count', 3) do
                      assert_difference('ActivityLog.count', 18) do
                        assert_difference("ActivityLog.where(action:'create').count", 7) do
                          # FIXME: ideally should be zero, but 1 is being created by a save when observation_unit pass to the study.observation_units association
                          assert_difference('DataFile.count', 1) do
                            investigation = Seek::FairDataStation::Writer.new.update_isa(investigation, inv, contributor,
                                                                                         projects, policy)
                          end
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
      end
    end

    ActivityLog.last(18).each do |log|
      assert_includes %w[create update], log.action
      assert_equal contributor, log.culprit
      assert_equal 'fair data station import', log.data
    end

    investigation.reload
    assert_equal 2, investigation.activity_logs.count
    assert_equal 'update', investigation.activity_logs.last.action

    # check:
    #   investigation title has been modified
    assert_equal 'An Investigation for a SEEK test case - changed', investigation.title

    # check:
    #   seek-test-study-1 experimental site name changed
    #   seek-test-study-2 description modified
    #   seek-test-study-3 created as a new study
    assert_equal 3, investigation.studies.count
    study = investigation.studies.where(external_identifier: 'seek-test-study-1').first
    assert_equal 'manchester test site - changed', study.extended_metadata.get_attribute_value('Experimental site name')
    assert_equal 2, study.activity_logs.count
    assert_equal 'update', study.activity_logs.last.action

    study = investigation.studies.where(external_identifier: 'seek-test-study-2').first
    assert_equal 'testing testing testing testing testing testing testing testing testing testing study 2 - changed',
                 study.description
    assert_equal 2, study.activity_logs.count
    assert_equal 'update', study.activity_logs.last.action

    study = investigation.studies.where(external_identifier: 'seek-test-study-3').first
    assert_equal 'test study 3', study.title
    assert_equal 'birmingham-test-site', study.extended_metadata.get_attribute_value('Experimental site name')
    assert_equal 1, study.activity_logs.count
    assert_equal 'create', study.activity_logs.last.action

    # check:
    #   seek-test-obs-unit-1 host sex modified
    #   seek-test-obs-unit-1 now linked to test-file-6.csv, and no longer linked to test-file-1.csv
    #   seek-test-obs-unit-3 name changed
    #   seek-test-obs-unit-4 created, linked to seek-test-study-3, along with new test-file-7.csv
    assert_equal 1, study.observation_units.count
    obs_unit = ObservationUnit.where(external_identifier: 'seek-test-obs-unit-1').first
    assert_equal 'female', obs_unit.extended_metadata.get_attribute_value('Gender')
    assert_equal ['test-file-6.csv'], obs_unit.data_files.collect(&:external_identifier)
    assert_equal 2, obs_unit.activity_logs.count
    assert_equal 'update', obs_unit.activity_logs.last.action

    # check no new activity logs, as unchanged
    obs_unit = ObservationUnit.where(external_identifier: 'seek-test-obs-unit-2').first
    assert_equal 1, obs_unit.activity_logs.count
    assert_equal 'create', obs_unit.activity_logs.last.action

    obs_unit = ObservationUnit.where(external_identifier: 'seek-test-obs-unit-3').first
    assert_equal 'test obs unit 3 - changed', obs_unit.title
    assert_equal 2, obs_unit.activity_logs.count
    assert_equal 'update', obs_unit.activity_logs.last.action

    obs_unit = ObservationUnit.where(external_identifier: 'seek-test-obs-unit-4').first
    assert_equal 'testing testing testing testing testing testing testing testing testing testing obs unit 4',
                 obs_unit.description
    assert_equal '1005g', obs_unit.extended_metadata.get_attribute_value('Birth weight')
    assert_equal 'seek-test-study-3', obs_unit.study.external_identifier
    assert_equal ['test-file-7.csv'], obs_unit.data_files.collect(&:external_identifier)
    assert_equal 1, obs_unit.activity_logs.count
    assert_equal 'create', obs_unit.activity_logs.last.action

    # check:
    #   seek-test-sample-1 name changed
    #   seek-test-sample-2 biosafety changed
    #   seek-test-sample-3 ncbi changed
    #   seek-test-sample-5 description changed
    #   seek-test-sample-6 created, linked to seek-test-obs-unit-4
    sample = Sample.where(external_identifier: 'seek-test-sample-1').first
    assert_equal 'test seek sample 1 - changed', sample.title
    sample = Sample.where(external_identifier: 'seek-test-sample-2').first
    assert_equal '2', sample.get_attribute_value('Bio safety level')
    assert_equal '2024-08-20', sample.get_attribute_value('Collection date')
    sample = Sample.where(external_identifier: 'seek-test-sample-3').first
    assert_equal '123460', sample.get_attribute_value('Organism ncbi id')
    sample = Sample.where(external_identifier: 'seek-test-sample-5').first
    assert_equal 'testing testing testing testing testing testing testing testing testing testing sample 5 - changed',
                 sample.get_attribute_value('Description')
    sample = Sample.where(external_identifier: 'seek-test-sample-6').first
    assert_equal 'seek-test-obs-unit-4', sample.observation_unit.external_identifier
    assert_equal 'goat', sample.get_attribute_value('Scientific name')
    assert_equal 'test seek sample 6', sample.title

    # check for no new activity logs
    sample = Sample.where(external_identifier: 'seek-test-sample-4').first
    assert_equal 1, sample.activity_logs.count
    assert_equal 'create', sample.activity_logs.last.action

    # check:
    #   seek-test-assay-1 description changed
    #   seek-test-assay-1 now linked to test-file-6.csv
    #   seek-test-assay-6 facility changed
    #   seek-test-assay-7 created, along with new test-file-8.csv data file
    assay = Assay.where(external_identifier: 'seek-test-assay-1').first
    assert_equal 'testing testing testing testing testing testing testing testing testing testing assay 1 - changed',
                 assay.description
    assert_equal ['test-file-6.csv'], assay.data_files.collect(&:external_identifier)
    assert_equal ['seek-test-sample-1'], assay.samples.collect(&:external_identifier)
    assay = Assay.where(external_identifier: 'seek-test-assay-6').first
    assert_equal 'test facility - changed', assay.extended_metadata.get_attribute_value('Facility')
    assert_equal ['seek-test-sample-5'], assay.samples.collect(&:external_identifier)
    assay = Assay.where(external_identifier: 'seek-test-assay-7').first
    assert_equal 'testing testing testing testing testing testing testing testing testing testing assay 7',
                 assay.description
    assert_equal 'new test facility', assay.extended_metadata.get_attribute_value('Facility')
    assert_equal 1, assay.samples.count
    assert_equal 'seek-test-sample-6', assay.samples.first.external_identifier
    assert_equal ['test-file-8.csv'], assay.data_files.collect(&:external_identifier)
  end

  test 'update isa with things moving' do
    investigation = setup_test_case_investigation
    policy = investigation.policy
    projects = investigation.projects
    contributor = investigation.contributor

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-moves-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first

    assert_no_difference('Investigation.count') do
      assert_no_difference('Study.count') do
        assert_no_difference('ObservationUnit.count') do
          assert_no_difference('Sample.count') do
            assert_no_difference('Assay.count') do
              assert_no_difference('DataFile.count') do
                assert_no_difference('ObservationUnitAsset.count') do
                  assert_no_difference('AssayAsset.count') do
                    assert_no_difference('ExtendedMetadata.count') do
                      assert_no_difference('ActivityLog.count') do
                        investigation = Seek::FairDataStation::Writer.new.update_isa(investigation, inv, contributor,
                                                                                     projects, policy)
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
    end

    investigation.reload

    # check
    #   seek-test-obs-unit-3 has moved to seek-test-study-1
    #   seek-test-sample-3 has moved to seek-test-obs-unit-1
    #   seek-test-sample-5 has moved to seek-test-obs-unit-2
    #   seek-test-assay-4 has moved to seek-test-sample-3 and therefore also seek-test-study-1
    #   seek-test-assay-6 has moved to seek-test-sample-4 and therefore also seek-test-study-1
    #   in each case also check their children are as expected, including items that haven't moved
    obs_unit = ObservationUnit.where(external_identifier: 'seek-test-obs-unit-3').first
    assert_equal 'seek-test-study-1', obs_unit.study.external_identifier
    assert_equal ['seek-test-sample-4'], obs_unit.samples.collect(&:external_identifier)

    study = Study.where(external_identifier: 'seek-test-study-1').first
    assert_equal %w[seek-test-obs-unit-1 seek-test-obs-unit-3],
                 study.observation_units.collect(&:external_identifier).sort
    study = Study.where(external_identifier: 'seek-test-study-2').first
    assert_equal ['seek-test-obs-unit-2'], study.observation_units.collect(&:external_identifier).sort

    sample = Sample.where(external_identifier: 'seek-test-sample-3').first
    assert_equal 'seek-test-obs-unit-1', sample.observation_unit.external_identifier
    assert_equal %w[seek-test-assay-3 seek-test-assay-4], sample.assays.collect(&:external_identifier).sort
    sample = Sample.where(external_identifier: 'seek-test-sample-5').first
    assert_equal 'seek-test-obs-unit-2', sample.observation_unit.external_identifier
    assert_equal ['seek-test-assay-5'], sample.assays.collect(&:external_identifier)
    sample = Sample.where(external_identifier: 'seek-test-sample-4').first
    assert_equal 'seek-test-obs-unit-3', sample.observation_unit.external_identifier
    assert_equal ['seek-test-assay-6'], sample.assays.collect(&:external_identifier)

    assay = Assay.where(external_identifier: 'seek-test-assay-4').first
    assert_equal 1, assay.samples.count
    assert_equal 'seek-test-sample-3', assay.samples.first.external_identifier
    assert_equal 'seek-test-study-1', assay.study.external_identifier

    assay = Assay.where(external_identifier: 'seek-test-assay-6').first
    assert_equal 1, assay.samples.count
    assert_equal 'seek-test-sample-4', assay.samples.first.external_identifier
    assert_equal 'seek-test-study-1', assay.study.external_identifier
  end

  test 'update_isa id mis match' do
    investigation = setup_test_case_investigation
    policy = investigation.policy
    projects = investigation.projects
    contributor = investigation.contributor

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/demo.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first

    refute_equal investigation.external_identifier, inv.external_id

    assert_raises(Seek::FairDataStation::ExternalIdMismatchException) do
      investigation = Seek::FairDataStation::Writer.new.update_isa(investigation, inv, contributor,
                                                                   projects, policy)
    end
  end

  test 'construct with nested extended metadata' do
    FactoryBot.create(:fairdata_test_case_investigation_extended_metadata)
    study_emt = FactoryBot.create(:fairdata_test_case_nested_study_extended_metadata)
    obs_unit_emt = FactoryBot.create(:fairdata_test_case_nested_obsv_unit_extended_metadata)
    FactoryBot.create(:fairdata_test_case_assay_extended_metadata)
    FactoryBot.create(:fairdatastation_test_case_sample_type)
    FactoryBot.create(:experimental_assay_class)
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    contributor = FactoryBot.create(:person)

    investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, contributor.projects,
                                                                    Policy.default)
    assert investigation.valid?

    assert_difference('ExtendedMetadata.count', 12) do
      User.with_current_user(contributor.user) do
        investigation.save!
      end
    end

    assert_equal 2, investigation.studies.count
    study = investigation.studies.first
    assert_equal study_emt, study.extended_metadata.extended_metadata_type
    assert_equal 'test study 1', study.title

    expected = HashWithIndifferentAccess.new({
                                               'Experimental site name': 'manchester test site',
                                               'study date details': {
                                                 'End date of Study': '2024-08-08',
                                                 'Start date of Study': '2024-08-01'
                                               }
                                             })

    assert_equal expected, study.extended_metadata.data

    study = investigation.studies.last
    assert_equal study_emt, study.extended_metadata.extended_metadata_type
    assert_equal 'test study 2', study.title

    expected = HashWithIndifferentAccess.new({
                                               'Experimental site name': 'manchester test site',
                                               'study date details': {
                                                 'End date of Study': '2024-08-18',
                                                 'Start date of Study': '2024-08-10'
                                               }
                                             })

    assert_equal expected, study.extended_metadata.data

    assert_equal 2, study.observation_units.count
    obs_unit = study.observation_units.first
    assert_equal obs_unit_emt, obs_unit.extended_metadata.extended_metadata_type
    assert_equal 'test obs unit 2', obs_unit.title

    expected = HashWithIndifferentAccess.new({
                                               'Gender': 'female',
                                               'obs_unit_birth_details': {
                                                 'Birth weight': '1235g',
                                                 'Date of birth': '2020-01-11'
                                               }
                                             })
    assert_equal expected, obs_unit.extended_metadata.data
  end

  test 'construct with deep nested extended metadata' do
    FactoryBot.create(:fairdata_test_case_investigation_extended_metadata)
    study_emt = FactoryBot.create(:fairdata_test_case_deep_nested_study_extended_metadata)
    FactoryBot.create(:fairdata_test_case_obsv_unit_extended_metadata)
    FactoryBot.create(:fairdata_test_case_assay_extended_metadata)
    FactoryBot.create(:fairdatastation_test_case_sample_type)
    FactoryBot.create(:experimental_assay_class)
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    contributor = FactoryBot.create(:person)

    investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, contributor.projects,
                                                                    Policy.default)
    assert investigation.valid?

    assert_difference('ExtendedMetadata.count', 12) do
      User.with_current_user(contributor.user) do
        investigation.save!
      end
    end

    assert_equal 2, investigation.studies.count
    study = investigation.studies.first
    assert_equal study_emt, study.extended_metadata.extended_metadata_type
    assert_equal 'test study 1', study.title

    expected = HashWithIndifferentAccess.new({
                                               'Experimental site name': 'manchester test site',
                                               'child': {
                                                 'End date of Study': '2024-08-08',
                                                 'grandchild': {
                                                   'Start date of Study': '2024-08-01'
                                                 }
                                               }
                                             })

    assert_equal expected, study.extended_metadata.data
  end

  test 'add EMT during update if previously nil' do
    FactoryBot.create(:fairdatastation_test_case_sample_type)
    FactoryBot.create(:experimental_assay_class)
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    contributor = FactoryBot.create(:person)
    projects = contributor.projects
    policy = Policy.default

    investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, projects, policy)
    assert investigation.valid?
    User.with_current_user(contributor.user) do
      investigation.save!
    end
    investigation.reload
    assert_nil investigation.extended_metadata

    inv_emt = FactoryBot.create(:fairdata_test_case_investigation_extended_metadata)
    study_emt = FactoryBot.create(:fairdata_test_case_study_extended_metadata)
    obs_unit_emt = FactoryBot.create(:fairdata_test_case_obsv_unit_extended_metadata)
    assay_emt = FactoryBot.create(:fairdata_test_case_assay_extended_metadata)

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-modified-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first

    assert_no_difference('Investigation.count') do
      assert_difference('Study.count', 1) do
        assert_difference('ObservationUnit.count', 1) do
          assert_difference('Sample.count', 1) do
            assert_difference('Assay.count', 1) do
              assert_difference('DataFile.count', 3) do
                assert_difference('ObservationUnitAsset.count', 1) do
                  assert_difference('AssayAsset.count', 2) do
                    # 1 for new df, the other is for the sample
                    assert_difference('ExtendedMetadata.count', 15) do
                      User.with_current_user(contributor.user) do
                        investigation = Seek::FairDataStation::Writer.new.update_isa(investigation, inv, contributor,
                                                                                     projects, policy)
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
    end

    investigation.reload
    study = investigation.studies.first
    obs_unit = study.observation_units.first
    assay = obs_unit.samples.first.assays.first

    assert_equal inv_emt, investigation.extended_metadata.extended_metadata_type
    assert_equal study_emt, study.extended_metadata.extended_metadata_type
    assert_equal obs_unit_emt, obs_unit.extended_metadata.extended_metadata_type
    assert_equal assay_emt, assay.extended_metadata.extended_metadata_type

    expected = HashWithIndifferentAccess.new({
                                               'Experimental site name': 'manchester test site - changed',
                                               'End date of Study': '2024-08-08',
                                               'Start date of Study': '2024-08-01'

                                             })

    assert_equal expected, study.extended_metadata.data

  end

  test 'EMT replaced during update if better match found' do
    FactoryBot.create(:fairdatastation_test_case_sample_type)
    study_emt_partial = FactoryBot.create(:fairdata_test_case_partial_study_extended_metadata)
    FactoryBot.create(:experimental_assay_class)
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    contributor = FactoryBot.create(:person)
    projects = contributor.projects
    policy = Policy.default

    investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, projects, policy)
    assert investigation.valid?
    User.with_current_user(contributor.user) do
      assert_difference('ExtendedMetadata.count', 2) do
        investigation.save!
      end
    end
    investigation.reload
    assert_equal study_emt_partial, investigation.studies.first.extended_metadata.extended_metadata_type
    expected = HashWithIndifferentAccess.new({
                                               'Experimental site name': 'manchester test site'
                                             })

    assert_equal expected, investigation.studies.first.extended_metadata.data

    study_emt = FactoryBot.create(:fairdata_test_case_study_extended_metadata)
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-modified-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first

    User.with_current_user(contributor.user) do
      assert_difference('ExtendedMetadata.count', 1) do # 1 new study, other 2 had EMT replaced and old version removed
        investigation = Seek::FairDataStation::Writer.new.update_isa(investigation, inv, contributor,
                                                                     projects, policy)
        investigation.save!
      end
    end

    investigation.reload
    assert_equal study_emt, investigation.studies.first.extended_metadata.extended_metadata_type
    expected = HashWithIndifferentAccess.new({
                                               'Experimental site name': 'manchester test site - changed',
                                               'End date of Study': '2024-08-08',
                                               'Start date of Study': '2024-08-01'

                                             })

    assert_equal expected, investigation.studies.first.extended_metadata.data
  end

  test 'update isa with nested metadata' do
    FactoryBot.create(:fairdata_test_case_investigation_extended_metadata)
    FactoryBot.create(:fairdata_test_case_nested_study_extended_metadata)
    FactoryBot.create(:fairdata_test_case_nested_obsv_unit_extended_metadata)
    FactoryBot.create(:fairdata_test_case_assay_extended_metadata)
    FactoryBot.create(:fairdatastation_test_case_sample_type)
    FactoryBot.create(:experimental_assay_class)
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    contributor = FactoryBot.create(:person)
    projects = contributor.projects
    policy = Policy.default

    investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, projects, policy)
    assert investigation.valid?

    # setup
    assert_difference('ExtendedMetadata.count', 12) do
      User.with_current_user(contributor.user) do
        investigation.save!
      end
    end

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-modified-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first

    # on save check, 0 investigation created, 1 study created, 1 obs unit, 1 sample, 1 assay, 3 data file, 3 extended metadata

    assert_no_difference('Investigation.count') do
      assert_difference('Study.count', 1) do
        assert_difference('ObservationUnit.count', 1) do
          assert_difference('Sample.count', 1) do
            assert_difference('Assay.count', 1) do
              assert_difference('DataFile.count', 3) do
                assert_difference('ObservationUnitAsset.count', 1) do
                  assert_difference('AssayAsset.count', 2) do
                    # 1 for new df, the other is for the sample
                    assert_difference('ExtendedMetadata.count', 3) do
                      User.with_current_user(contributor.user) do
                        investigation = Seek::FairDataStation::Writer.new.update_isa(investigation, inv, contributor,
                                                                                     projects, policy)
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
    end

    investigation.reload

    assert_equal 3, investigation.studies.count
    study = investigation.studies.where(external_identifier: 'seek-test-study-1').first
    expected = HashWithIndifferentAccess.new({
                                               'Experimental site name': 'manchester test site - changed',
                                               'study date details': {
                                                 'End date of Study': '2024-08-08',
                                                 'Start date of Study': '2024-08-01'
                                               }
                                             })
    assert_equal expected, study.extended_metadata.data

    study = investigation.studies.where(external_identifier: 'seek-test-study-3').first
    expected = HashWithIndifferentAccess.new({
                                               'Experimental site name': 'birmingham-test-site',
                                               'study date details': {
                                                 'End date of Study': '2024-09-13',
                                                 'Start date of Study': '2024-09-12'
                                               }
                                             })
    assert_equal expected, study.extended_metadata.data

    obs_unit = ObservationUnit.where(external_identifier: 'seek-test-obs-unit-1').first
    expected = HashWithIndifferentAccess.new({
                                               'Gender': 'female',
                                               'obs_unit_birth_details': {
                                                 'Birth weight': '1234g',
                                                 'Date of birth': '2020-01-10'
                                               }
                                             })
    assert_equal expected, obs_unit.extended_metadata.data
    obs_unit = ObservationUnit.where(external_identifier: 'seek-test-obs-unit-4').first
    expected = HashWithIndifferentAccess.new({
                                               'Gender': 'female',
                                               'obs_unit_birth_details': {
                                                 'Birth weight': '1005g',
                                                 'Date of birth': '2020-02-12'
                                               }
                                             })
    assert_equal expected, obs_unit.extended_metadata.data
  end

  private

  def setup_test_case_investigation
    FactoryBot.create(:fairdata_test_case_investigation_extended_metadata)
    FactoryBot.create(:fairdata_test_case_study_extended_metadata)
    FactoryBot.create(:fairdata_test_case_obsv_unit_extended_metadata)
    FactoryBot.create(:fairdata_test_case_assay_extended_metadata)
    FactoryBot.create(:fairdatastation_test_case_sample_type)
    FactoryBot.create(:experimental_assay_class)

    contributor = FactoryBot.create(:person)
    project = contributor.projects.first
    policy = FactoryBot.create(:public_policy)
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, [project], policy)
    assert_difference('Investigation.count', 1) do
      investigation.save!
    end
    assert_equal 'seek-test-investigation', investigation.external_identifier
    investigation
  end
end
